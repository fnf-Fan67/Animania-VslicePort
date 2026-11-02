package animania.characters.girlfriend;

class GirlfriendChristmasAnimaniaCharacter extends AnimateAtlasCharacter
{
	function new()
	{
		super('gf-christmas-animania');
	}

	// FIX: ahora es public para que los stages puedan hacer gf.fgSnow sin error
	// (en las clases de HScript las vars sin "public" son privadas)
	public var fgSnow;

	override function onCreate(event:ScriptEvent):Void
	{
		super.onCreate(event);

		var stage = PlayState.instance.currentStage;
		if (stage != null)
		{
			// por si el personaje se vuelve a crear, no duplicar la nieve
			removeFgSnow();

			fgSnow = FunkinSprite.create(this.x + 285, this.y + 600, "characters/amtake/gf/gf-snow");
			stage.add(fgSnow);
			fgSnow.zIndex = zIndex + 1;
			fgSnow.shader = this.shader;
			stage.refresh();
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

		// FIX: desbloqueado. Antes usaba "parentStage", que no existe en BaseCharacter
		// (por eso daba error); se usa PlayState.instance.currentStage igual que en onCreate.
		if (fgSnow != null && PlayState.instance != null && PlayState.instance.currentStage != null)
		{
			if (fgSnow.shader != this.shader)
				fgSnow.shader = this.shader;
		}
	}

	// RESET: quitar la nieve del stage cuando se destruye el personaje
	override function onDestroy(event:ScriptEvent):Void
	{
		removeFgSnow();
		super.onDestroy(event);
	}

	function removeFgSnow():Void
	{
		if (fgSnow == null)
			return;

		var stage = PlayState.instance != null ? PlayState.instance.currentStage : null;
		if (stage != null)
			stage.remove(fgSnow);

		fgSnow.kill();
		fgSnow.destroy();
		fgSnow = null;
	}
}
