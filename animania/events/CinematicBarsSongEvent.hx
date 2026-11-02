package animania.events;

class CinematicBarsSongEvent extends SongEvent
{
  static final BAR_HEIGHT:Float = 350;
  static final BAR_WIDTH:Float = 15000;
  static final BAR_COLOR:Int = 0xFF000000;

  var upperBar:Null<FlxSprite> = null;
  var lowerBar:Null<FlxSprite> = null;

  var baseUpperY:Float = 0;
  var baseLowerY:Float = 0;

  public function new()
  {
    super('CinematicBars');
  }

  public override function onCountdownStart(event:ScriptEvent):Void
  {
    destroyBars();

    upperBar = new FlxSprite(-((BAR_WIDTH - FlxG.width) / 2), -BAR_HEIGHT);
    upperBar.makeGraphic(Std.int(BAR_WIDTH), Std.int(BAR_HEIGHT), BAR_COLOR);
    upperBar.cameras = [PlayState.instance.camHUD];
    upperBar.zIndex = PlayState.instance.healthBar.zIndex - 8;
    PlayState.instance.add(upperBar);

    lowerBar = new FlxSprite(-((BAR_WIDTH - FlxG.width) / 2), FlxG.height);
    lowerBar.makeGraphic(Std.int(BAR_WIDTH), Std.int(BAR_HEIGHT), BAR_COLOR);
    lowerBar.cameras = [PlayState.instance.camHUD];
    lowerBar.zIndex = PlayState.instance.healthBar.zIndex - 8;
    PlayState.instance.add(lowerBar);

    PlayState.instance.refresh();

    baseUpperY = upperBar.y;
    baseLowerY = lowerBar.y;
  }

  public override function onDestroy(event:ScriptEvent):Void
  {
    destroyBars();
  }

  public override function onSongEnd(event:ScriptEvent):Void
  {
    destroyBars();
  }

  public override function onGameOver(event:ScriptEvent):Void
  {
    destroyBars();
  }

  function destroyBars():Void
  {
    if (upperBar != null)
    {
      FlxTween.cancelTweensOf(upperBar);
      if (PlayState.instance != null) PlayState.instance.remove(upperBar, true);
      upperBar.destroy();
      upperBar = null;
    }

    if (lowerBar != null)
    {
      FlxTween.cancelTweensOf(lowerBar);
      if (PlayState.instance != null) PlayState.instance.remove(lowerBar, true);
      lowerBar.destroy();
      lowerBar = null;
    }
  }

  public override function handleEvent(data:SongEventData):Void
  {
    if (upperBar == null || lowerBar == null) return;

    var upY:Float = data.getFloat('upY') ?? 0;
    var upTime:Float = data.getFloat('upTime') ?? 0;
    var upEase:String = data.getString('upEase') ?? SongEvent.DEFAULT_EASE;
    var upEaseDir:String = data.getString('easeDirup') ?? SongEvent.DEFAULT_EASE_DIR;

    var downY:Float = data.getFloat('downY') ?? 0;
    var downTime:Float = data.getFloat('downTime') ?? 0;
    var downEase:String = data.getString('downEase') ?? SongEvent.DEFAULT_EASE;
    var downEaseDir:String = data.getString('easeDirdown') ?? SongEvent.DEFAULT_EASE_DIR;

    FlxTween.cancelTweensOf(upperBar);
    FlxTween.cancelTweensOf(lowerBar);

    var upEaseFn:Float->Float = resolveEase(upEase, upEaseDir);
    var downEaseFn:Float->Float = resolveEase(downEase, downEaseDir);

    FlxTween.tween(upperBar, {y: baseUpperY + upY}, Math.max(upTime, 0), {ease: upEaseFn});

    FlxTween.tween(lowerBar, {y: baseLowerY - downY}, Math.max(downTime, 0), {ease: downEaseFn});
  }

  /**
   * Resuelve el string de ease/easeDir del chart (mismo formato que ZoomCamera)
   * a la funcion real de FlxEase, sin explotar si el nombre no existe: si el
   * combo es invalido cae a linear en vez de tirar error en el tween.
   */
  function resolveEase(ease:String, easeDir:String):Float->Float
  {
    if (ease == null || ease == '') ease = SongEvent.DEFAULT_EASE;
    if (easeDir == null) easeDir = '';

    if (SongEvent.EASE_TYPE_DIR_REGEX.match(ease) || ease == 'linear') easeDir = '';

    var fnName:String = '$ease$easeDir';
    var fn:Null<Float->Float> = Reflect.field(FlxEase, fnName);

    if (fn == null)
    {
      trace('[CinematicBars] Funcion de ease invalida: $fnName, se usa linear.');
      return FlxEase.linear;
    }

    return fn;
  }

  public override function getTitle():String
  {
    return 'Cinematic Bars';
  }

  public override function getEventSchema():SongEventSchema
  {
    var easeKeys = [
      'Linear' => 'linear',
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
      'Circ' => 'circ',
    ];

    var dirKeys = ['In' => 'In', 'Out' => 'Out', 'In/Out' => 'InOut'];

    return new SongEventSchema([
      {
        name: 'upper',
        title: 'Barra superior',
        type: 'frame',
        children: [
          {
            name: 'upY',
            title: 'Distancia (px)',
            defaultValue: 0.0,
            step: 5.0,
            type: 'float'
          },
          {
            name: 'upTime',
            title: 'Duracion (segundos)',
            defaultValue: 1.0,
            min: 0,
            step: 0.05,
            type: 'float'
          },
          {
            name: 'upEase',
            title: 'Easing',
            defaultValue: SongEvent.DEFAULT_EASE,
            type: 'enum',
            keys: easeKeys
          },
          {
            name: 'easeDirup',
            title: 'Direccion',
            defaultValue: SongEvent.DEFAULT_EASE_DIR,
            type: 'enum',
            keys: dirKeys
          }
        ]
      },
      {
        name: 'lower',
        title: 'Barra inferior',
        type: 'frame',
        children: [
          {
            name: 'downY',
            title: 'Distancia (px)',
            defaultValue: 0.0,
            step: 5.0,
            type: 'float'
          },
          {
            name: 'downTime',
            title: 'Duracion (segundos)',
            defaultValue: 1.0,
            min: 0,
            step: 0.05,
            type: 'float'
          },
          {
            name: 'downEase',
            title: 'Easing',
            defaultValue: SongEvent.DEFAULT_EASE,
            type: 'enum',
            keys: easeKeys
          },
          {
            name: 'easeDirdown',
            title: 'Direccion',
            defaultValue: SongEvent.DEFAULT_EASE_DIR,
            type: 'enum',
            keys: dirKeys
          }
        ]
      }
    ]);
  }
}
