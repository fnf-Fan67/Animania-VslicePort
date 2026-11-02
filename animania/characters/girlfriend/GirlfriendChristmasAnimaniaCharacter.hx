package animania.characters.girlfriend;

class GirlfriendChristmasAnimaniaCharacter extends AnimateAtlasCharacter
{
	function new()
	{
		super('gf-christmas-animania');
	}

	var fgSnow;

	override function onCreate(event:ScriptEvent):Void
	{
		super.onCreate(event);
		if (PlayState.instance.currentStage != null)
		{
			fgSnow = FunkinSprite.create(this.x + 285, this.y + 600, "characters/amtake/gf/gf-snow");
			PlayState.instance.currentStage.add(fgSnow);
			fgSnow.zIndex = zIndex + 1;
			fgSnow.shader = this.shader;
			PlayState.instance.currentStage.refresh();
		}
	}

	function onCountdownStep(e)
	{
		super.onCountdownStep(e);
		switch (e.step)
		{
			case CountdownStep.THREE:
				playAnimation("count3", true, false, false);
			case CountdownStep.TWO:
				playAnimation("count2", true, false, false);
			case CountdownStep.ONE:
				playAnimation("count1", true, false, false);
			case CountdownStep.GO:
				playAnimation("cheer", true, false, false);
		}
	}

	override function onAnimationFinished(prefix:String):Void
	{
		switch (prefix)
		{
			case "combo251":
				hasDanced = false;
				super.onAnimationFinished(prefix);

			default:
				super.onAnimationFinished(prefix);
		}
	}

	override function onUpdate(e)
	{
		super.onUpdate(e);

		/*if (parentStage != null && fgSnow != null)
		{
			if (fgSnow.shader != this.shader)
				fgSnow.shader = this.shader;
		}*/
	}
}
