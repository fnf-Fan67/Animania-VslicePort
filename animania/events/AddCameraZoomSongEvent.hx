package animania.events;

class AddCameraZoomSongEvent extends SongEvent
{
  static final DECAY_RATE:Float = 0.95;
  static final EPSILON:Float = 0.0005;

  var active:Bool = false;
  var savedCameraZoomRate:Float = 0;

  public function new()
  {
    super('AddCameraZoom');
  }

  public override function onCountdownStart(event:ScriptEvent):Void
  {
    active = false;
  }

  public override function onDestroy(event:ScriptEvent):Void
  {
    restoreBopIfNeeded();
  }

  public override function onSongEnd(event:ScriptEvent):Void
  {
    restoreBopIfNeeded();
  }

  public override function onGameOver(event:ScriptEvent):Void
  {
    restoreBopIfNeeded();
  }

  public override function handleEvent(data:SongEventData):Void
  {
    var ps:PlayState = PlayState.instance;
    if (ps == null) return;

    var gameZoom:Float = data.getFloat('gameZoom') ?? 0;
    var hudZoom:Float = data.getFloat('hudZoom') ?? 0;

    if (!active)
    {
      savedCameraZoomRate = ps.cameraZoomRate;
      ps.cameraZoomRate = 0;
      active = true;
    }

    ps.cameraBopMultiplier += gameZoom;
    ps.camHUD.zoom += hudZoom;
  }

  public override function onUpdate(event:UpdateScriptEvent):Void
  {
    if (!active) return;

    var ps:PlayState = PlayState.instance;
    if (ps == null)
    {
      active = false;
      return;
    }

    var dt:Float = event.elapsed * 60;
    var decay:Float = Math.pow(DECAY_RATE, dt);

    ps.cameraBopMultiplier = FlxMath.lerp(1.0, ps.cameraBopMultiplier, decay);
    ps.camHUD.zoom = FlxMath.lerp(ps.defaultHUDCameraZoom, ps.camHUD.zoom, decay);

    if (ps.subState == null && !ps.debugUnbindCameraZoom)
    {
      FlxG.camera.zoom = ps.currentCameraZoom * ps.cameraBopMultiplier;
    }

    if (Math.abs(ps.cameraBopMultiplier - 1.0) < EPSILON && Math.abs(ps.camHUD.zoom - ps.defaultHUDCameraZoom) < EPSILON)
    {
      ps.cameraBopMultiplier = 1.0;
      ps.camHUD.zoom = ps.defaultHUDCameraZoom;
      ps.cameraZoomRate = savedCameraZoomRate;
      active = false;
    }
  }

  function restoreBopIfNeeded():Void
  {
    if (!active) return;

    var ps:PlayState = PlayState.instance;
    if (ps != null) ps.cameraZoomRate = savedCameraZoomRate;

    active = false;
  }

  public override function getTitle():String
  {
    return 'Add Camera Zoom';
  }

  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'gameZoom',
        title: 'Game Zoom',
        defaultValue: 0.0,
        step: 0.005,
        type: 'float',
        units: 'x'
      },
      {
        name: 'hudZoom',
        title: 'HUD Zoom',
        defaultValue: 0.0,
        step: 0.005,
        type: 'float',
        units: 'x'
      }
    ]);
  }
}
