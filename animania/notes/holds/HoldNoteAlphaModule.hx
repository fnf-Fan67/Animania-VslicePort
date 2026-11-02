package animania.notes.holds;

class HoldNoteAlphaModule extends Module
{
  var HOLD_ALPHA:Float = 0.7;

  function new()
  {
    super('HoldNoteAlphaModule', 1000);
  }

  function isTargetStyle():Bool
  {
    var play:PlayState = PlayState.instance;
    if (play == null) return false;
    if (play.currentChart == null) return false;

    var id:String = play.currentChart.noteStyle;
    return id == 'amtake-base' || id == 'amtake-xmas';
  }

  function applyAlpha(strumline:Dynamic):Void
  {
    if (strumline == null) return;

    applyToGroup(strumline.holdNotes);

    applyToGroup(Reflect.field(strumline, 'holdNotesVwoosh'));
  }

  function applyToGroup(group:Dynamic):Void
  {
    if (group == null || group.members == null) return;

    for (hold in group.members)
    {
      if (hold == null || !hold.alive) continue;

      if (hold.alpha <= 0) continue;

      if (hold.alpha != HOLD_ALPHA) hold.alpha = HOLD_ALPHA;
    }
  }

  override function onUpdate(event:UpdateScriptEvent):Void
  {
    super.onUpdate(event);

    if (!isTargetStyle()) return;

    var play:PlayState = PlayState.instance;
    applyAlpha(play.playerStrumline);
    applyAlpha(play.opponentStrumline);
  }
}
