package animania.events;

/**
 * Evento AngleCamera: inclina (rota) el contenido de camGame con scrollAngle.
 * El HUD no se toca.
 *
 * Formato en el chart:
 * {
 *   'e': 'AngleCamera',
 *   'v': {
 *     'angle': FLOAT,    // angulo destino en grados
 *     'delay': FLOAT,    // espera antes de empezar, en steps
 *     'duration': FLOAT, // duracion en steps
 *     'ease': ENUM,      // funcion de easing ('INSTANT' ignora duration)
 *     'easeDir': ENUM    // In / Out / InOut
 *   }
 * }
 *
 * Un AngleCamera nuevo cancela el tween anterior y arranca desde el angulo
 * actual, asi que "angle: 0 + INSTANT" corta una inclinacion larga en seco
 * (como hace dadbattle en 32000ms).
 */
class AngleCameraSongEvent extends SongEvent
{
  static final DEFAULT_ANGLE:Float = 0.0;
  static final DEFAULT_DELAY:Float = 0.0;
  static final DEFAULT_DURATION:Float = 4.0;

  var angleTween:Null<FlxTween> = null;

  public function new()
  {
    super('AngleCamera');
  }

  public override function handleEvent(data:SongEventData):Void
  {
    var pf = PlayState.instance;
    if (pf == null || pf.camGame == null) return;

    var angle:Float = data.getFloat('angle') ?? DEFAULT_ANGLE;
    var delay:Float = data.getFloat('delay') ?? DEFAULT_DELAY;
    var duration:Float = data.getFloat('duration') ?? DEFAULT_DURATION;
    var ease:String = data.getString('ease') ?? SongEvent.DEFAULT_EASE;
    var easeDir:String = data.getString('easeDir') ?? SongEvent.DEFAULT_EASE_DIR;

    if (SongEvent.EASE_TYPE_DIR_REGEX.match(ease) || ease == 'linear') easeDir = '';

    var easeFn:Null<Float->Float> = null;
    if (ease != 'INSTANT')
    {
      var fnName:String = '$ease$easeDir';
      easeFn = Reflect.field(FlxEase, fnName);
      if (easeFn == null)
      {
        trace('[AngleCamera] Funcion de ease invalida: $fnName, se usa linear.');
        easeFn = FlxEase.linear;
      }
    }

    var stepMs:Float = Conductor.instance.stepLengthMs;
    var durSeconds:Float = Math.max(stepMs * duration / Constants.MS_PER_SEC, 0);
    var delaySeconds:Float = Math.max(stepMs * delay / Constants.MS_PER_SEC, 0);

    if (angleTween != null) angleTween.cancel();
    angleTween = null;

    var cam:FlxCamera = pf.camGame;

    // INSTANT, o duracion y delay en cero: se aplica directo.
    if (easeFn == null || (durSeconds <= 0 && delaySeconds <= 0))
    {
      cam.scrollAngle = angle;
      return;
    }

    angleTween = FlxTween.num(cam.scrollAngle, angle, durSeconds, {ease: easeFn, startDelay: delaySeconds}, function(v:Float) {
      cam.scrollAngle = v;
    });
  }

  function stopTween():Void
  {
    if (angleTween != null) angleTween.cancel();
    angleTween = null;
  }

  function resetAngle():Void
  {
    var pf = PlayState.instance;
    if (pf != null && pf.camGame != null) pf.camGame.scrollAngle = 0;
  }

  public override function onSongRetry(event:SongRetryEvent):Void
  {
    stopTween();
    resetAngle();
  }

  public override function onGameOver(event:ScriptEvent):Void
  {
    stopTween();
    resetAngle();
  }

  public override function onDestroy(event:ScriptEvent):Void
  {
    // La camara se destruye con el PlayState: solo soltamos el tween.
    stopTween();
  }

  public override function getTitle():String
  {
    return 'Angle Camera';
  }

  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'angle',
        title: 'Angle',
        defaultValue: DEFAULT_ANGLE,
        step: 0.5,
        type: 'float',
        units: 'deg'
      },
      {
        name: 'delay',
        title: 'Delay',
        defaultValue: DEFAULT_DELAY,
        min: 0,
        step: 0.5,
        type: 'float',
        units: 'steps'
      },
      {
        name: 'duration',
        title: 'Duration',
        defaultValue: DEFAULT_DURATION,
        min: 0,
        step: 0.5,
        type: 'float',
        units: 'steps'
      },
      {
        name: 'ease',
        title: 'Easing Type',
        defaultValue: SongEvent.DEFAULT_EASE,
        type: 'enum',
        keys: [
          'Linear' => 'linear',
          'Instant (Ignores duration)' => 'INSTANT',
          'Sine' => 'sine',
          'Quad' => 'quad',
          'Cube' => 'cube',
          'Quart' => 'quart',
          'Quint' => 'quint',
          'Expo' => 'expo',
          'Smooth Step' => 'smoothStep',
          'Smoother Step' => 'smootherStep',
          'Elastic' => 'elastic',
          'Back' => 'back',
          'Bounce' => 'bounce',
          'Circ' => 'circ'
        ]
      },
      {
        name: 'easeDir',
        title: 'Easing Direction',
        defaultValue: SongEvent.DEFAULT_EASE_DIR,
        type: 'enum',
        keys: ['In' => 'In', 'Out' => 'Out', 'In/Out' => 'InOut']
      }
    ]);
  }
}
