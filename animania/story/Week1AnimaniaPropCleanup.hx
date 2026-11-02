package animania.story;

class Week1AnimaniaPropCleanup extends Module
{
  static final TARGET_LEVEL:String = 'week1Animania';
  static final WEEK5LEVEL:String = 'week5Animania';

  var lastLevelId:String = null;

  public function new()
  {
    super('week1AnimaniaPropCleanup', 1000);
  }

  public override function onUpdate(event:UpdateScriptEvent):Void
  {
    super.onUpdate(event);

    var state = FlxG.state;
    if (state == null || !Std.isOfType(state, StoryMenuState))
    {
      lastLevelId = null;
      return;
    }

    var levelId:String = Reflect.getProperty(state, 'currentLevelId');
    if (levelId == lastLevelId) return;
    lastLevelId = levelId;

    if (levelId == TARGET_LEVEL) return;
	if (levelId == WEEK5LEVEL) return;

    var levelProps = Reflect.getProperty(state, 'levelProps');
    if (levelProps == null) return;

    for (prop in levelProps.members)
    {
      if (prop == null || prop.shader == null) continue;

      var src:String = prop.shader.glFragmentSource;
      if (src != null && src.indexOf('bg_col') != -1) prop.shader = null;
    }
  }
}
