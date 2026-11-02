package animania.stages.xmascityhall;

class XMasCityHallNastyAmTakeStage extends ScriptedStage
{
	var leftTV;
	var rightTV;
	var colorShader:AdjustColorShader;
	var railBoppers = [];
	var hangers = []; // cada entrada: [prop, velocidadSway, yBase, offsetYBase]
	var fuckingCoolAndAwesomeSkull;
	var bgCreeps;
	var tentacleLeft;
	var tentacleRight;
	var songPos = 0;

	// valores iniciales (los usa resetEffects para dejar todo como al construir el stage)
	var HANGER_Y_OFFSET = 750;
	var BG_CREEPS_START_Y = 175; // -325 + 500

	function new()
	{
		super('xMasCityMallNastyAmTake');
	}

	function lowQualityMode():Bool
	{
		return Save.instance.modOptions["lowQuality"] == true;
	}

	function onCreate(e)
	{
		super.onCreate(e);
		PauseSubState.musicSuffix = '-amtake5';
	}

	function buildStage()
	{
		super.buildStage();

		// FIX: antes estaba invertido (!lowQuality), por eso borraba los hangers con lowQuality DESACTIVADO
		if (lowQualityMode())
		{
			removeLowQualityProps();
		}

		colorShader = new AdjustColorShader();
		colorShader.hue = -10;
		colorShader.saturation = -20;
		colorShader.contrast = 0;
		colorShader.brightness = 0;

		if (!lowQualityMode())
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
				hangers.push([prop, FlxG.random.float(.25, 1.5), prop.y, prop.offset.y]);
				prop.y -= HANGER_Y_OFFSET;
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

		if (!lowQualityMode())
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

		tentacleLeft = getNamedProp("tentacleLeft");
		tentacleRight = getNamedProp("tentacleRight");

		if (tentacleLeft != null)
			tentacleLeft.animation.onFinish.add((animName:String) -> tentacleLeft.alpha = 0);

		if (tentacleRight != null)
		{
			tentacleRight.animation.onFrameChange.add((animName:String, frameNumber:Int, frameIndex:Int) -> {
				tentacleRight.offset.x = (animName == "tick" ? 0 : 775);
			});

			tentacleRight.animation.onFinish.add((animName:String) -> tentacleRight.alpha = 0);
		}

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
				if (!lowQualityMode())
				{
					leftTV.anim.play("noise", true);
					rightTV.anim.play("noise", true);
				}

			case 88:
				if (!lowQualityMode())
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

		// FIX: antes estaba invertido (!lowQuality), el sway solo corría en lowQuality (donde no hay hangers)
		if (lowQualityMode())
			return;

		if (Conductor.instance.currentBeat > 92)
		{
			songPos += event.elapsed;

			for (i in 0...hangers.length)
				hangers[i][0].offset.y = FlxMath.fastSin(songPos / 1.5 * hangers[i][1]) * 40;
		}
	}

	// ---------------------------------------------------------------
	// RESETS
	// ---------------------------------------------------------------

	// Devuelve todos los efectos del stage a su estado inicial.
	// Se llama al reintentar/morir (resetStage ya reposiciona los props del JSON,
	// pero no sabe nada de lo que hace este script).
	function resetEffects()
	{
		songPos = 0;

		// TVs: volver a "off" (en el beat 8 pasan a "noise")
		if (leftTV != null)
			leftTV.anim.play("off", true);
		if (rightTV != null)
			rightTV.anim.play("off", true);

		// Hangers: cancelar tweens, quitar el sway y volver a subirlos fuera de pantalla
		for (hanger in hangers)
		{
			var prop = hanger[0];
			if (prop == null)
				continue;
			FlxTween.cancelTweensOf(prop);
			prop.y = hanger[2] - HANGER_Y_OFFSET;
			prop.offset.y = hanger[3];
		}

		// bgCreeps: cancelar el tween del beat 88 y volver a la posición inicial
		if (bgCreeps != null)
		{
			FlxTween.cancelTweensOf(bgCreeps);
			bgCreeps.y = BG_CREEPS_START_Y;
			bgCreeps.animation.play("snow", true);
		}

		// Skull: el onFinish lo hace kill(), hay que revivirlo para que vuelva a salir en el beat 148
		if (fuckingCoolAndAwesomeSkull != null)
		{
			FlxTween.cancelTweensOf(fuckingCoolAndAwesomeSkull);
			fuckingCoolAndAwesomeSkull.animation.stop();
			fuckingCoolAndAwesomeSkull.revive();
			fuckingCoolAndAwesomeSkull.alpha = 0;
		}

		// Tentáculos (la canción también los apaga, esto cubre el stage solo)
		resetTentacle(tentacleLeft);
		resetTentacle(tentacleRight);
	}

	function resetTentacle(tentacle)
	{
		if (tentacle == null)
			return;
		FlxTween.cancelTweensOf(tentacle);
		tentacle.alpha = 0;
	}

	override function onSongRetry(event)
	{
		super.onSongRetry(event);
		resetEffects();
	}

	override function onDestroy(event)
	{
		// cancelar todo lo que pueda quedar vivo antes de soltar las referencias
		for (hanger in hangers)
			if (hanger[0] != null)
				FlxTween.cancelTweensOf(hanger[0]);

		if (bgCreeps != null)
			FlxTween.cancelTweensOf(bgCreeps);
		if (fuckingCoolAndAwesomeSkull != null)
			FlxTween.cancelTweensOf(fuckingCoolAndAwesomeSkull);
		if (tentacleLeft != null)
			FlxTween.cancelTweensOf(tentacleLeft);
		if (tentacleRight != null)
			FlxTween.cancelTweensOf(tentacleRight);

		hangers = [];
		railBoppers = [];
		leftTV = null;
		rightTV = null;
		bgCreeps = null;
		fuckingCoolAndAwesomeSkull = null;
		tentacleLeft = null;
		tentacleRight = null;
		colorShader = null;
		songPos = 0;

		// que el pause de este stage no se quede en otras canciones
		PauseSubState.musicSuffix = '';

		super.onDestroy(event);
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
