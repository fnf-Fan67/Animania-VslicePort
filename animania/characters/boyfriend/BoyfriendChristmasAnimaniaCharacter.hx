package animania.characters.boyfriend;

class BoyfriendChristmasAnimaniaCharacter extends MultiAnimateAtlasCharacter
{
	function new()
	{
		super('bf-christmas-animania');
	}

	override function onCreate(event:ScriptEvent):Void
	{
		super.onCreate(event);

		GameOverSubState.musicSuffix = '-xmas';
		GameOverSubState.blueBallSuffix = '-xmas';
	}

	var lastHoldFinish:Null<Float> = null;

	function onNoteHit(event:HitNoteScriptEvent)
	{

		if (event.note.noteData.getMustHitNote() && characterType == CharacterType.BF && !event.eventCanceled)
		{
			if (event.note.holdNoteSprite != null)
				lastHoldFinish = event.note.strumTime + event.note.noteData.length;
			switch (event.note.kind)
			{
				case "mom":
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'alt');
					return;

				case "cheer":
					holdTimer = 0;
					playAnimation("hey", true, false);
					return;

				default:
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, "");
					return;
			}
		}
	}

	function onNoteMiss(event)
	{

		if (event.note.noteData.getMustHitNote() && characterType == CharacterType.BF && !event.eventCanceled)
		{
			switch (event.note.kind)
			{
				case "mom":
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), true, 'alt');
					return;

				case "fresh":
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), true, 'both');
					return;

				default:
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), true, "");
					return;
			}
		}

		super.onNoteMiss(event);
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

	override function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reverse:Bool = false):Void
	{
		if (!debug)
		{
			if (name == "firstDeath")
			{
				shader = null;
			}
			else if (name == "deathLoop")
			{
				Conductor.instance.forceBPM(100);
			}
			else if (name == "deathConfirm")
			{
				GameOverSubState.instance.targetCameraZoom *= 1.15;
				FlxTween.tween(FlxG.camera, {zoom: GameOverSubState.instance.targetCameraZoom}, 2, {ease: FlxEase.backOut});
				GameOverSubState.instance.cameraFollowPoint.x += 225;
				GameOverSubState.instance.cameraFollowPoint.y -= 75;
			}
		}
		super.playAnimation(name, restart, ignoreOther, reverse);
	}
}
