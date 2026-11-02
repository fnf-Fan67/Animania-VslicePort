package animania.notes.kinds;

class NoAnimationNoteKind extends NoteKind
{
  function new()
  {
    super("noanimation", "no animation note", null, []);
  }

  override function onNoteHit(event:HitNoteScriptEvent)
  {
    event.stopPropagation();

    super.onNoteHit(event);
  }
}
