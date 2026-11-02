package animania.notes.styles;

class AmTakeBase extends NoteStyle implements IScriptedClass
{
  var HOLD_COVER_ZINDEX:Int = 5;

  public function new()
  {
    super('amtake-base');
  }

  override function buildHoldCoverSprite(target:NoteHoldCover):Void
  {
    super.buildHoldCoverSprite(target);

    sendHoldCoversBelowStrum();
  }

  function sendHoldCoversBelowStrum()
  {
    var ps = PlayState.instance;
    if (ps == null || ps.playerStrumline == null || ps.opponentStrumline == null) return;

    var covers = ps.playerStrumline.noteHoldCovers;
    if (covers == null || covers.zIndex == HOLD_COVER_ZINDEX) return;
    var coversOpp = ps.opponentStrumline.noteHoldCovers;
    if (coversOpp == null || coversOpp.zIndex == HOLD_COVER_ZINDEX) return;

	covers.zIndex = HOLD_COVER_ZINDEX;
    coversOpp.zIndex = HOLD_COVER_ZINDEX;
    ps.playerStrumline.refresh();
    ps.opponentStrumline.refresh();
  }
}
