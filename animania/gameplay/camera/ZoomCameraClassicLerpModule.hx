package animania.gameplay.camera;

class ZoomCameraClassicLerpModule extends Module
{
  static final DEFAULT_ZOOM:Float = 1.0;
  static final DEFAULT_WIDESCREEN_SCALE:Float = 0.0;
  static final DEFAULT_DURATION:Float = 4.0;
  static final DEFAULT_MODE:String = 'direct';

  static final SNAP_THRESHOLD:Float = 0.0015;

  var lerping:Bool = false;
  var lerpTargetZoom:Float = FlxCamera.defaultZoom;
  var lerpDuration:Float = 0.5;

  public function new()
  {
    super('ZoomCameraClassicLerpModule', 200);
  }

  override public function onSongEvent(event:SongEventScriptEvent):Void
  {
    super.onSongEvent(event);

    if (event.eventData == null || event.eventData.eventKind != 'ZoomCamera') return;

    var ease:String = event.eventData.getString('ease');
    if (ease != 'classicLerp')
    {
      lerping = false;
      return;
    }

    if (PlayState.instance == null || PlayState.instance.currentStage == null) return;
    if (PlayState.instance.isMinimalMode) return;

    var zoom:Float = event.eventData.getFloat('zoom');
    if (zoom == null) zoom = DEFAULT_ZOOM;

    var widescreenScaleX:Float = event.eventData.getFloat('widescreenScaleX');
    if (widescreenScaleX == null) widescreenScaleX = DEFAULT_WIDESCREEN_SCALE;
    var widescreenScaleY:Float = event.eventData.getFloat('widescreenScaleY');
    if (widescreenScaleY == null) widescreenScaleY = DEFAULT_WIDESCREEN_SCALE;

    var scaledZoom:Float = zoom + (zoom * calculateScale(FullScreenScaleMode.wideScale, FlxPoint.get(widescreenScaleX, widescreenScaleY)));

    var duration:Float = event.eventData.getFloat('duration');
    if (duration == null) duration = DEFAULT_DURATION;

    var mode:String = event.eventData.getString('mode');
    if (mode == null) mode = DEFAULT_MODE;
    var isDirectMode:Bool = mode == 'direct';

    event.cancelEvent();

    PlayState.instance.cancelCameraZoomTween();

    lerpTargetZoom = scaledZoom * (isDirectMode ? FlxCamera.defaultZoom : PlayState.instance.stageZoom);

    var durSeconds:Float = Conductor.instance.stepLengthMs * duration / Constants.MS_PER_SEC;
    lerpDuration = durSeconds > 0 ? durSeconds : 0.5;

    if (durSeconds <= 0)
    {
      PlayState.instance.currentCameraZoom = lerpTargetZoom;
      lerping = false;
    }
    else
    {
      lerping = true;
    }
  }

  override public function onUpdate(event:UpdateScriptEvent):Void
  {
    super.onUpdate(event);

    if (!lerping) return;
    if (PlayState.instance == null || PlayState.instance.shouldSubstatePause) return;

    var current:Float = PlayState.instance.currentCameraZoom;
    var next:Float = MathUtil.smoothLerpPrecision(current, lerpTargetZoom, FlxG.elapsed, lerpDuration, 0.01);
    next = MathUtil.snap(next, lerpTargetZoom, SNAP_THRESHOLD);

    PlayState.instance.currentCameraZoom = next;

    if (next == lerpTargetZoom) lerping = false;
  }

  override public function onSongRetry(event:SongRetryEvent):Void
  {
    super.onSongRetry(event);
    lerping = false;
  }

  override public function onStateChangeBegin(event:StateChangeScriptEvent):Void
  {
    super.onStateChangeBegin(event);
    lerping = false;
  }

  function calculateScale(wideScale:FlxPoint, scale:FlxPoint):Float
  {
    return (wideScale.x - 1) * scale.x + (wideScale.y - 1) * scale.y;
  }
}
