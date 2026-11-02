package animania.hud.timebar;

class TimeBarModule extends Module
{

  var BAR_HEIGHT:Float = 9;

  var BAR_HEIGHT_SCREEN_STRENGTH:Float = 1;
  var BAR_HEIGHT_MIN_SCALE:Float = 0.6;
  var BAR_HEIGHT_MAX_SCALE:Float = 1;

  var BAR_ALPHA:Float = 0.8;

  var BAR_COLOR = 0xFFFFFFFF;

  var BAR_ZINDEX:Int = 900;

  var BAR_OVERSCAN:Float = 2;

  var bar = null;
  var drawHook = null;

  static var MEGA_ALLOWED_STAGES:Array<String> = [
    "mainStageAmTake",
    "serviceEnterance",
    "xMasCityMallAmTake",
    "xMasCityMallAmTakeDark",
    "xMasCityMallNastyAmTake",
	"phoneCallStreet"
  ];

  function isAllowedStage():Bool
  {
    var play = PlayState.instance;
    if (play == null || play.currentStage == null) return false;
    return MEGA_ALLOWED_STAGES.indexOf(play.currentStage.id) != -1;
  }

  public function new()
  {
    super('TimeBarModule', 1000, {state: PlayState});
  }

  override function onStateChangeEnd(event:StateChangeScriptEvent):Void
  {
    super.onStateChangeEnd(event);

    removeDrawHook();
    bar = null;

    if (!Std.isOfType(event.targetState, PlayState)) return;

    var ps = PlayState.instance;
    if (ps == null) return;
    if (!isAllowedStage()) return;

    createBar(ps);
  }

  override function onStateChangeBegin(event:StateChangeScriptEvent):Void
  {
    super.onStateChangeBegin(event);

    removeDrawHook();
    bar = null;
  }

  override function onDestroy(event:ScriptEvent):Void
  {
    super.onDestroy(event);

    removeDrawHook();
    bar = null;
  }

  function createBar(ps)
  {
    bar = new FunkinSprite();
    bar.makeSolidColor(2, 2, BAR_COLOR);
    bar.scrollFactor.set(0, 0);
    bar.cameras = [ps.camHUD];
    bar.alpha = BAR_ALPHA;
    bar.zIndex = BAR_ZINDEX;
    bar.visible = false;

    ps.add(bar);
    ps.refresh();

    drawHook = function()
    {
      onPreDraw();
    };
    FlxG.signals.preDraw.add(drawHook);
  }

  function removeDrawHook()
  {
    if (drawHook == null) return;

    FlxG.signals.preDraw.remove(drawHook);
    drawHook = null;
  }

  function onPreDraw()
  {
    if (bar == null) return;

    var ps = PlayState.instance;

    if (ps == null || FlxG.state != ps || !bar.exists)
    {
      removeDrawHook();
      bar = null;
      return;
    }

    layoutBar(ps.camHUD, getProgress());
  }

  function getProgress()
  {
    var music = FlxG.sound.music;
    if (music == null || music.length <= 0) return 0;

    var pos = Conductor.instance.songPosition - Conductor.instance.combinedOffset;
    var p = pos / music.length;

    if (p < 0) p = 0;
    if (p > 1) p = 1;
    return p;
  }

  // Pantalla más grande -> factor > 1 (barra más alta); pantalla más chica -> factor < 1 (barra más baja).
  function getHeightScale()
  {
    var size = FullScreenScaleMode.logicalSize;
    var baseH:Float = FlxG.initialHeight;
    if (size == null || size.y <= 0 || baseH <= 0) return 1;

    var k:Float = 1 + (size.y / baseH - 1) * BAR_HEIGHT_SCREEN_STRENGTH;
    if (k < BAR_HEIGHT_MIN_SCALE) k = BAR_HEIGHT_MIN_SCALE;
    if (k > BAR_HEIGHT_MAX_SCALE) k = BAR_HEIGHT_MAX_SCALE;
    return k;
  }

  function layoutBar(cam, progress)
  {
    if (progress <= 0)
    {
      bar.visible = false;
      return;
    }
    bar.visible = true;

    var z = cam.zoom;
    if (z < 0.05) z = 0.05;

    var cx = cam.width / 2;
    var cy = cam.height / 2;

    var screenLeft = -BAR_OVERSCAN;
    var screenTop = Preferences.downscroll ? -BAR_OVERSCAN : BAR_OVERSCAN;
    var screenW = cam.width * progress + BAR_OVERSCAN;
    var screenH = BAR_HEIGHT * getHeightScale() + BAR_OVERSCAN;

    bar.scale.set(screenW / z / bar.frameWidth, screenH / z / bar.frameHeight);
    bar.updateHitbox();
    bar.x = cx + (screenLeft - cx) / z;
    bar.y = cy + (screenTop - cy) / z;
  }
}
