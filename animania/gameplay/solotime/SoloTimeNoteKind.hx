package animania.gameplay.solotime;

class SoloTimeNoteKind extends NoteKind
{
	function new()
	{
		super("solotime", "SoloTime Note", "solotime", []);
	}

	var soloType = NoteStyleRegistry.instance.fetchEntry("solotime");

	override function onNoteHit(event:HitNoteScriptEvent)
	{
		if (PlayState.instance != null)
			PlayState.instance.songScore += 800;
		if (event.doesNotesplash)
			createCustomSplash(event.note);
		event.doesNotesplash = false;

    event.stopPropagation();

		super.onNoteHit(event);
	}

	override function onNoteMiss(event)
	{
		event.cancel();
		return;
	}

	function createCustomSplash(note)
	{
		var splash = constructNoteSplash(note);
		if (splash != null)
		{
			var strumline = PlayState.instance.playerStrumline;
			var receptor = strumline.strumlineNotes.members[note.noteData.getDirection()];

			splash.scale.set(strumline.strumlineScale.x, strumline.strumlineScale.y);
			splash.updateHitbox();

			splash.x = (receptor.x + receptor.width / 2) - splash.width / 2 - soloType.getSplashOffsets()[0] * strumline.strumlineScale.x;
			splash.y = (receptor.y + receptor.height / 2) - splash.height / 2 - soloType.getSplashOffsets()[1] * strumline.strumlineScale.y;
		}
	}

	function constructNoteSplash(note):NoteSplash
	{
		var result = new NoteSplash(soloType);
		result.zIndex = 355;
		result.play(note.noteData.getDirection());
		PlayState.instance.playerStrumline.add(result);
		return result;
	}

	var timeLeft:Float = 0;
	var appearTime:Float = 500;

	override function onUpdate(event:UpdateScriptEvent)
	{
		for (note in getNotes())
		{
			note.alpha = (Math.min(Math.max(1 - ((note.strumTime - Conductor.instance.songPosition) / appearTime), 0), 1) * 3) - .25;

			if (note.hasBeenHit || note.hasMissed) continue;
    }

		super.onUpdate(event);
	}

	override function onNoteIncoming(event:NoteScriptEvent)
	{
		event.note.alpha *= .75;
		super.onNoteIncoming(event);
	}
}
