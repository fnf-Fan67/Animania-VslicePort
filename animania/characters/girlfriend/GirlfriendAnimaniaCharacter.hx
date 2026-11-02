package animania.characters.girlfriend;

class GirlfriendAnimaniaCharacter extends AnimateAtlasCharacter
{
	function new()
	{
		super('gf-animania');
	}

	public var altDanceAnim:Bool = FlxG.random.bool(10);

	var awesomeAnims = ["fresh solo"];

	public override function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reversed:Bool = false):Void
	{
		switch (name)
		{
			case "pre-dance":

			case "end-dance":

			case "stop drop dance":
				if (altDanceAnim)
				{
					idleSuffix = "-philly";
					return;
				}
				else
				{
					idleSuffix = "";
					return;
				}
		}

    if (!animationOffsets.exists(name)) setAnimationOffsets(name, 0, 0);
		super.playAnimation(name, restart, ignoreOther, reversed);
	}

	override function onAnimationFinished(prefix:String):Void
	{
		switch (prefix)
		{
			case "pre-dance":
				hasDanced = false;
				canPlayOtherAnims = true;
				idleSuffix = "-dance";

			case "end-dance":
				hasDanced = false;
				canPlayOtherAnims = true;
				if (altDanceAnim)
				{
					idleSuffix = "-philly";
					dance(true);
					return;
				}
				else
				{
					idleSuffix = "";
					dance(true);
					return;
				}

			case "fresh solo":
				hasDanced = false;
				idleSuffix = "-drop";
			default:
		}
		super.onAnimationFinished(prefix);
	}

	var lastHoldFinish:Null<Float> = null;

	function onNoteHit(event:HitNoteScriptEvent)
	{

		if ((!event.note.noteData.getMustHitNote() && characterType == CharacterType.DAD)
			|| (event.note.noteData.getMustHitNote() && characterType == CharacterType.BF)
			|| (event.note.kind != null && event.note.kind.indexOf('gf') != -1 && characterType == CharacterType.GF))
		{
			if (event.note.holdNoteSprite != null)
				lastHoldFinish = event.note.strumTime + event.note.noteData.length;
			holdTimer = 0;
			this.playSingAnimation(event.note.noteData.getDirection(), false, "");
		}
		else if (characterType == CharacterType.GF && event.note.noteData.getMustHitNote())
		{
			switch (event.judgement)
			{
				case 'sick':
					playComboAnimation(event.comboCount);
				case 'good':
					playComboAnimation(event.comboCount);
				default:
					playComboDropAnimation(event.comboCount);
			}
		}
	}

	function playComboAnimation(comboCount:Int):Void
	{
		if (awesomeAnims.contains(getCurrentAnimation()))
			return;

		super.playComboAnimation(comboCount);
	}

	function playComboDropAnimation(comboCount:Int):Void
	{
		if (awesomeAnims.contains(getCurrentAnimation()))
			return;

		super.playComboDropAnimation(comboCount);
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

  function onCountdownStart(e)
  {
    super.onCountdownStart(e);
    if (altDanceAnim)
    {
      idleSuffix = '-philly';
    }
  }

	function onCountdownStep(e)
	{
		super.onCountdownStep(e);
		switch (e.step)
		{
			case CountdownStep.THREE:
				playAnimation("count three", true, false, false);
			case CountdownStep.TWO:
				playAnimation("count two", true, false, false);
			case CountdownStep.ONE:
				playAnimation("count one", true, false, false);
			case CountdownStep.GO:
				playAnimation("cheer", true, false, false);
		}
	}
}
