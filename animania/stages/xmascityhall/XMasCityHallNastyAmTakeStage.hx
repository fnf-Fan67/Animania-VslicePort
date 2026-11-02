package animania.stages.xmascityhall;

class XMasCityHallNastyAmTakeStage extends ScriptedStage
{
	var leftTV;
	var rightTV;
	var colorShader:AdjustColorShader;
	var railBoppers = [];
	var hangers = [];
	var fuckingCoolAndAwesomeSkull;
	var bgCreeps;
	var songPos = 0;

	function new()
	{
		super('xMasCityMallNastyAmTake');
	}

	function onCreate(e)
	{
		super.onCreate(e);
		PauseSubState.musicSuffix = '-amtake5';
	}

	function buildStage()
	{
		super.buildStage();

		if (!Save.instance.modOptions["lowQuality"])
		{
			removeLowQualityProps();
		}

		colorShader = new AdjustColorShader();
		colorShader.hue = -10;
		colorShader.saturation = -20;
		colorShader.contrast = 0;
		colorShader.brightness = 0;

		if (!Save.instance.modOptions["lowQuality"])
		{
		leftTV = new FunkinSprite(-2000, -915, Paths.animateAtlas('stages/xMassCityMallNasty/TV', 'shared'));
		leftTV.anim.play();
		leftTV.zIndex = 75;
		leftTV.flipX = true;
		leftTV.applyStageMatrix = true;
		leftTV.scrollFactor.set(0.8, 0.8);
		leftTV.anim.addByFrameLabel("off", "off", 24);
		leftTV.anim.addByFrameLabel("noise", "noise", 24);
		leftTV.anim.play("off", true);
		add(leftTV);

		rightTV = new FunkinSprite(625, -915, Paths.animateAtlas('stages/xMassCityMallNasty/TV', 'shared'));
		rightTV.anim.play();
		rightTV.zIndex = 76;
		rightTV.applyStageMatrix = true;
		rightTV.scrollFactor.set(0.8, 0.8);
		rightTV.anim.addByFrameLabel("off", "off", 24);
		rightTV.anim.addByFrameLabel("noise", "noise", 24);
		rightTV.anim.play("off", true);
		add(rightTV);
		}

		hangers = [];

		for (prop in namedProps)
			if (prop.name.indexOf("hang") != -1)
			{
				hangers.push([prop, FlxG.random.float(.25, 1.5)]);
				prop.y -= 750;
			}

		fuckingCoolAndAwesomeSkull = new FunkinSprite(-200, -300);
		fuckingCoolAndAwesomeSkull.zIndex = 116;
		fuckingCoolAndAwesomeSkull.frames = Paths.getSparrowAtlas('stages/xMassCityMallNasty/skull', 'shared');
		fuckingCoolAndAwesomeSkull.animation.addByPrefix("y", "skull-troll_gif", 24, false);
		fuckingCoolAndAwesomeSkull.scrollFactor.set(.9, .9);
		fuckingCoolAndAwesomeSkull.setGraphicSize(750, 700);
		fuckingCoolAndAwesomeSkull.flipX = true;
		fuckingCoolAndAwesomeSkull.alpha = 0;
		fuckingCoolAndAwesomeSkull.blend = BlendMode.ADD;
		fuckingCoolAndAwesomeSkull.animation.onFinish.add((name:String) -> FlxTween.tween(fuckingCoolAndAwesomeSkull, {alpha: 0.0}, .35,
			{onComplete: _ -> fuckingCoolAndAwesomeSkull.kill(), ease: FlxEase.smootherStepInOut}));
		add(fuckingCoolAndAwesomeSkull);

		if (!Save.instance.modOptions["lowQuality"])
		{
		bgCreeps = new FunkinSprite(-1000, -325, Paths.animateAtlas('stages/xMassCityMallNasty/bg creeps', 'shared'));
		bgCreeps.zIndex = 114;
		bgCreeps.animation.addBySymbol("snow", bgCreeps.getDefaultSymbol(), 24, true);
		bgCreeps.animation.play("snow", true);
		bgCreeps.scrollFactor.set(.95, .95);
		bgCreeps.applyStageMatrix = true;
		add(bgCreeps);
		bgCreeps.y += 500;
		}


		var tentacleLeft = getNamedProp("tentacleLeft");
		var tentacleRight = getNamedProp("tentacleRight");
		tentacleLeft.animation.onFinish.add((animName:String) -> tentacleLeft.alpha = 0);

		tentacleRight.animation.onFrameChange.add((animName:String, frameNumber:Int, frameIndex:Int) -> {
			tentacleRight.offset.x = (animName == "tick" ? 0 : 775);
		});

		tentacleRight.animation.onFinish.add((animName:String) -> tentacleRight.alpha = 0);

		refresh();
	}

	override function addCharacter(character:BaseCharacter, charType:CharacterType):Void
	{
		super.addCharacter(character, charType);

		switch (charType)
		{
			case CharacterType.BF:
				character.shader = colorShader;
				songPos = 0;
		}
	}

	function onBeatHit(event)
	{
		super.onBeatHit(event);

		switch (event.beat)
		{
			case 8:
				if (!Save.instance.modOptions["lowQuality"])
				{
					leftTV.anim.play("noise", true);
					rightTV.anim.play("noise", true);
				}

			case 88:
				if (!Save.instance.modOptions["lowQuality"])
				{
					FlxTween.tween(bgCreeps, {y: -325}, 1.95, {ease: FlxEase.sineOut});
					for (hanger in hangers)
						FlxTween.tween(hanger[0], {y: hanger[0].y + 700}, .85, {ease: FlxEase.cubeInOut, startDelay: FlxG.random.float(0, .75)});
				}

			case 148:
				FlxTween.tween(fuckingCoolAndAwesomeSkull, {alpha: 0.15}, .15, {ease: FlxEase.backOut});
				fuckingCoolAndAwesomeSkull.animation.play("y", true);
		}
	}

	function onUpdate(event)
	{
		super.onUpdate(event);

		if (PlayState.instance.isPlayerDying)
			return;

		if (!Save.instance.modOptions["lowQuality"])
			return;

		if (Conductor.instance.currentBeat > 92)
		{
			songPos += event.elapsed;

			for (i in 0...hangers.length)
				hangers[i][0].offset.y = FlxMath.fastSin(songPos / 1.5 * hangers[i][1]) * 40;
		}
	}

	var _lowQualityProps = ['ceiling', 'hangRUNMO', 'hangCRUSHERS', 'hangZONA', 'hangMUFFIN', 'hangDUDE', 'candy', 'gust'];

	function removeLowQualityProps()
	{
		var i = 0;
		while (i < _lowQualityProps.length)
		{
			var name = _lowQualityProps[i];
			var prop = getNamedProp(name);
			if (prop != null)
			{
				FlxTween.cancelTweensOf(prop);
				boppers.remove(prop);
				namedProps.remove(name);
				remove(prop);
				prop.kill();
				prop.destroy();
			}
			i = i + 1;
		}
	}
}
