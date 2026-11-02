package animania.stages.mainstage;

class SpotlightAccesories extends FunkinSprite
{
	public var targetSpotlight:FunkinSprite = null;

	public var light:FunkinSprite;

	var angleTween:FlxTween = null;

	public function new(ass, prop)
	{
		super(prop.x, prop.y);
		scrollFactor.set(prop.scrollFactor.x, prop.scrollFactor.y);
		targetSpotlight = prop;
		this.zIndex = prop.zIndex + 1;

		frames = Paths.getSparrowAtlas("stages/mainStageAmTake/spotlight", "shared");
		animation.addByPrefix("y", "spotlight ring", 1, true);
		animation.play("y", true);
		blend = BlendMode.MULTIPLY;
		updateHitbox();

		origin.set(80 / 2, -158 / 2);

		light = new FunkinSprite(prop.x, prop.y);
		light.frames = Paths.getSparrowAtlas("stages/mainStageAmTake/spotlight", "shared");
		light.animation.addByPrefix("y", "spotlight ray", 1, true);
		light.blend = BlendMode.ADD;
		light.animation.play("y", true);
		light.scrollFactor.set(prop.scrollFactor.x, prop.scrollFactor.y);
		alpha = light.alpha = 0;
		light.updateHitbox();
		light.origin.set(290, 80);
	}

	/** Anima el angulo del spotlight (cancela el tween anterior de este mismo spotlight). */
	public function tweenAngle(to:Float, time:Float, ease):Void
	{
		if (angleTween != null)
			angleTween.cancel();

		angleTween = FlxTween.num(targetSpotlight.angle, to, time, {ease: ease}, v -> targetSpotlight.angle = v);
	}

	override function update(elapsed)
	{
		super.update(elapsed);
		light.update(elapsed);

		angle = targetSpotlight.angle;
		light.angle = angle;
		light.color = color;
		light.alpha = .9 * alpha;
	}

	override function draw()
	{
		super.draw();
		light.draw();
	}

	override function destroy()
	{
		if (angleTween != null)
			angleTween.cancel();

		if (light != null)
		{
			light.destroy();
			light = null;
		}

		super.destroy();
	}
}
