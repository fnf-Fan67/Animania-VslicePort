package animania.characters.dad;

class DadBeastCharacter extends AnimateAtlasCharacter
{
	function new()
	{
		super('dad-beast');
	}

	override function onCreate(event:ScriptEvent):Void
	{
		super.onCreate(event);
	}

	override function onNoteHit(event:HitNoteScriptEvent):Void
	{
		if (!event.note.noteData.getMustHitNote() && characterType == CharacterType.DAD && !event.eventCanceled)
		{
			holdTimer = 0;
			switch (event.note.kind)
			{
				case "mom":
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'alt');

				default:
					this.playSingAnimation(event.note.noteData.getDirection(), false, "");
			}
			return;
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

		icon.loadTextureAtlas("icons/beast-dearest", null, icon.getDefaultAtlasSettings());
		icon.antialiasing = true;

		animania.scriptCall("makeAmTakeAnimatedIcon", [icon, !isOpponent]);

		icon.snapToTargetSize();
	}
}
