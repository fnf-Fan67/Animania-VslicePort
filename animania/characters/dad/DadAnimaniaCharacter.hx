package animania.characters.dad;

class DadAnimaniaCharacter extends AnimateAtlasCharacter
{
	function new()
	{
		super('dad-animania');
	}

	override function onCreate(event:ScriptEvent):Void
	{
		super.onCreate(event);
	}

	var lastHoldFinish:Null<Float> = null;

	public override function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reversed:Bool = false):Void
	{
		switch (name)
		{
			case "angy":
				idleSuffix = "-angry";

			case "imok":
				idleSuffix = "";

			default:
				super.playAnimation(name, restart, ignoreOther, reversed);
		}
	}

	function onNoteHit(event:HitNoteScriptEvent)
	{

		if (!event.note.noteData.getMustHitNote() && characterType == CharacterType.DAD && !event.eventCanceled)
		{
			if (event.note.holdNoteSprite != null)
				lastHoldFinish = event.note.strumTime + event.note.noteData.length;
			switch (event.note.kind)
			{
				case "mom":
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'alt');
					return;

				case "beatbox":
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'beatbox');
					return;

				default:
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, idleSuffix.indexOf("angry") != -1 ? "angry" : "");
					return;
			}
		}
		super.onNoteHit(event);
	}

	override function initHealthIcon(isOpponent:Bool):Void
	{
		super.initHealthIcon(isOpponent);

		if (PlayState.instance == null)
			return;

		var icon = isOpponent ? PlayState.instance.iconP2 : PlayState.instance.iconP1;
		if (icon == null)
			return;

		var animania = ModuleHandler.getModule("AnimaniaStuff");
		if (animania == null)
			return;

		animania.scriptCall("makeAmTakeAnimatedIcon", [icon, !isOpponent]);
	}
}
