package animania.characters.parents;

class ParentsChristmasAnimaniaCharacter extends AnimateAtlasCharacter
{
	function new()
	{
		super('parents-christmas-animania');
	}

	override function onCreate(event:ScriptEvent):Void
	{
		super.onCreate(event);
	}

	var lastHoldFinish:Null<Float> = null;

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
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'alt' + idleSuffix);
					return;

				case "both":
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'both' + idleSuffix);
					return;

				case "parents-miss":
					event.cancel();
					idleSuffix = "-angry";
					shouldAlternate = false;
					return;
				default:
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, idleSuffix.indexOf("angry") != -1 ? "angry" : "");
					return;
			}
		}
	}

	function onNoteMiss(e)
	{
		if (!e.note.noteData.getMustHitNote() && characterType == CharacterType.DAD)
			return;

		super.onNoteMiss(e);
	}

	public override function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reversed:Bool = false):Void
	{
		var doBasic:Bool = false;
		switch (name)
		{
			case "skibidi":
				idleSuffix = "";
				shouldAlternate = true;
				danceEvery = 1;
			case "cocoaSoloLookLeft":
				canPlayOtherAnims = true;
				doBasic = true;
			case "cocoaSoloLookRight":
				doBasic = true;
				canPlayOtherAnims = true;
			default:
				super.playAnimation(name, restart, ignoreOther, reversed);
		}

		if (doBasic)
			super.playAnimation(name, restart, ignoreOther, reversed);
	}

	override function onAnimationFinished(prefix:String):Void
	{
		trace(prefix);
		switch (prefix)
		{
			case "cocoaSolo" | "cocoaSoloLeft":
				trace("я сосу большие яйца <3");

			case "cocoaSoloLookLeft":
				trace("я сосу большие яйца <3 2");
				canPlayOtherAnims = true;
				playAnimation("cocoaSoloLeft", true, true);

			case "cocoaSoloLookRight":
				canPlayOtherAnims = true;
				playAnimation("cocoaSolo", true, true);
				/*new FlxTimer().start(4, () ->
				{
					canPlayOtherAnims = true;
				});*/

			case "singRIGHTmiss":
				super.onAnimationFinished(prefix);

			default:
				super.onAnimationFinished(prefix);
		}
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
