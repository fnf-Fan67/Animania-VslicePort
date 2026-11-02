package animania.stages.mainstage;

class MainStageAmTake extends ScriptedStage
{
	function new()
	{
		super('mainStageAmTake');
	}

	override function onCreate(e)
	{
		super.onCreate(e);
		PauseSubState.musicSuffix = '-amtake1';
		cameraDance = false;
	}

	var spotlighShits = [];

	var crowd1:FunkinSprite;
	var crowd2:FunkinSprite;
	var crowd3:FunkinSprite;
	var crowd1Tween:FlxTween = null;

	var smokes = [];

	var floorLights:FunkinSprite;
	var floorLightsBlendy:FunkinSprite;
	var floorLightBged:FunkinSprite;

	var highShader:HighShader;
	var trippyShader:TrippyShader;

	var highFilter:ShaderFilter;
	var trippyFilter:ShaderFilter;

	var filterCam = null;

	var bfRim:RimLight;
	var dadRim:RimLight;

	override function buildStage()
	{
		spotlighShits = [];
		super.buildStage();

		if (Save.instance.modOptions["lowQuality"])
			removeLowQualityProps();

		floorLights = getNamedProp("floorLights");
		floorLightsBlendy = getNamedProp("floorLightsBlendy");
		floorLightBged = getNamedProp("floorLightBged");

		if (Save.instance.modOptions["shaders"])
		{
			bfRim = new RimLight();
			dadRim = new RimLight();
		}

		createAllSpotlights();
		setLight(true);
		setSmokeVisible(false);
		smokes = [];
		for (prop in namedProps)
			if (prop.name.indexOf("smoke-") != -1)
				smokes.push(prop);

		getNamedProp("vin1").alpha = 1;
		getNamedProp("vin2").alpha = 0;

		if (!Save.instance.modOptions["lowQuality"])
		{
			crowd1 = new FunkinSprite(-1050, 770, Paths.animateAtlas("stages/mainStageAmTake/crowd", "shared"));
			crowd1.anim.addByFrameLabel("y", "crowd1", 1, false);
			crowd1.anim.play("y", true);
			crowd1.scrollFactor.set(1.1, 1.1);
			crowd1.zIndex = 80;
			crowd1.useRenderTexture = true;
			crowd1.applyStageMatrix = true;
			add(crowd1);

			crowd2 = new FunkinSprite(-1100, 750, Paths.animateAtlas("stages/mainStageAmTake/crowd", "shared"));
			crowd2.anim.addByFrameLabel("y", "croud2 bop", 24, false);
			crowd2.anim.addByFrameLabelIndices("dL", "croud2 dance", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], 24, false);
			crowd2.anim.addByFrameLabelIndices("dR", "croud2 dance", [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], 24, false);
			crowd2.anim.play("y", true);
			crowd2.scrollFactor.set(1.2, 1.2);
			crowd2.zIndex = 200;
			crowd2.color = 0xFFAAA9B2;
			namedProps.set("crowdA", crowd2);
			crowd2.useRenderTexture = true;
			crowd2.applyStageMatrix = true;
			add(crowd2);

			crowd3 = new FunkinSprite(-1050, 600, Paths.animateAtlas("stages/mainStageAmTake/crowd", "shared"));
			crowd3.anim.addByFrameLabel("y", "croud3", 24, false);
			crowd3.anim.play("y", true);
			crowd3.scrollFactor.set(1.3, 1.3);
			crowd3.zIndex = 205;
			crowd3.color = 0xFFA29EAF;
			crowd3.useRenderTexture = true;
			crowd3.applyStageMatrix = true;
			add(crowd3);
		}

		refresh();

		if (Save.instance.modOptions["shaders"])
		{
			highShader = new HighShader();
			highShader.effectiveness = 0;
			highFilter = new ShaderFilter(highShader);

			trippyShader = new TrippyShader();
			trippyShader.darkness = 0;
			trippyShader.intensity = 0;
			trippyFilter = new ShaderFilter(trippyShader);

			filterCam = FlxG.camera;
			filterCam.filters = [highFilter, trippyFilter];
		}

		setupZoomFactorProps();
	}

	var _lowQualityProps = ['boomBoxFramesLeft', 'boomBoxFramesRight'];

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

	var _zoomFactorNames = ['vin1', 'vin2'];
	var _zoomFactorValues = [0.65, 0.9];

	var _zfSprites = [];
	var _zfFactor = [];
	var _zfBaseScaleX = [];
	var _zfBaseScaleY = [];
	var _zfBaseCX = [];
	var _zfBaseCY = [];

	function setupZoomFactorProps()
	{
		_zfSprites = [];
		_zfFactor = [];
		_zfBaseScaleX = [];
		_zfBaseScaleY = [];
		_zfBaseCX = [];
		_zfBaseCY = [];

		var i = 0;
		while (i < _zoomFactorNames.length)
		{
			var spr = getNamedProp(_zoomFactorNames[i]);
			if (spr != null)
			{
				_zfSprites.push(spr);
				_zfFactor.push(_zoomFactorValues[i]);
				_zfBaseScaleX.push(spr.scale.x);
				_zfBaseScaleY.push(spr.scale.y);
				_zfBaseCX.push(spr.x + spr.width * 0.5);
				_zfBaseCY.push(spr.y + spr.height * 0.5);
			}
			i = i + 1;
		}
	}

	function updateZoomFactorProps()
	{
		var i = 0;
		while (i < _zfSprites.length)
		{
			var spr = _zfSprites[i];
			var cam = spr != null ? spr.camera : null;
			if (cam != null && cam.zoom != 0)
			{
				var zf = _zfFactor[i];
				var r = ((1.0 - zf) + zf * cam.zoom) / cam.zoom;

				var halfW = cam.width * 0.5;
				var halfH = cam.height * 0.5;
				var scrollX = cam.scroll.x * spr.scrollFactor.x;
				var scrollY = cam.scroll.y * spr.scrollFactor.y;

				var cx = halfW + ((_zfBaseCX[i] - scrollX) - halfW) * r + scrollX;
				var cy = halfH + ((_zfBaseCY[i] - scrollY) - halfH) * r + scrollY;

				spr.scale.set(_zfBaseScaleX[i] * r, _zfBaseScaleY[i] * r);
				spr.x = cx - spr.width * 0.5;
				spr.y = cy - spr.height * 0.5;
			}
			i = i + 1;
		}
	}

	/**
	 * PlayState agrega los personajes DESPUES de crear el stage, por eso el rim
	 * se engancha aqui y no en buildStage().
	 */
	override function addCharacter(character, charType)
	{
		super.addCharacter(character, charType);
		applyRim(character);
	}

	override function onCountdownStart(event)
	{
		super.onCountdownStart(event);
		applyRim(getBoyfriend());
		applyRim(getDad());
	}

	function applyRim(character)
	{
		if (character == null)
			return;

		if (Save.instance.modOptions["shaders"])
		{
			if (character == getBoyfriend() && bfRim != null)
				bfRim.attach(character);
			else if (character == getDad() && dadRim != null)
				dadRim.attach(character);
		}
	}

	function removeRim()
	{
		if (Save.instance.modOptions["shaders"])
		{
			if (bfRim != null)
				bfRim.detach();
			if (dadRim != null)
				dadRim.detach();
		}
	}

	function clearFilters()
	{
		if (filterCam != null)
			filterCam.filters = null;
	}

	override function onGameOver(e)
	{
		super.onGameOver(e);
		removeRim();
		clearFilters();
	}

	override function onDestroy(e)
	{
		removeRim();
		clearFilters();
		_zfSprites = [];
		super.onDestroy(e);
	}

	function createAllSpotlights()
	{
		for (prop in namedProps)
			if (prop.name.indexOf("stoplight") != -1)
			{
				var uhuh = new SpotlightAccesories("asss", prop);
				spotlighShits.push(uhuh);
				add(uhuh);
			}
	}

	override function onUpdate(event)
	{
		super.onUpdate(event);

		updateZoomFactorProps();

		if (Save.instance.modOptions["shaders"])
		{
			if (highShader != null)
				highShader.update(event.elapsed);

			if (trippyShader != null)
				trippyShader.update(event.elapsed * trippyMult);
		}

		var floorFade = (Conductor.instance.beatLengthMs / 1000) * FlxG.elapsed * 2.2;
		if (floorLightsBlendy != null && floorLightsBlendy.alpha > 0)
			floorLightsBlendy.alpha -= floorFade;
		if (floorLights != null && floorLights.alpha > 0)
			floorLights.alpha -= floorFade;

		if (spotlighShits.length > 0 && spotlighShits[0].alpha > 0 && !itsSoloTime)
		{
			var alph = spotlighShits[0].alpha;
			alph -= (Conductor.instance.beatLengthMs / 1000) * FlxG.elapsed * 3.3;
			for (s in spotlighShits)
				s.alpha = alph;
		}

		if (cameraDance || angleActive)
		{
			FlxG.camera.scrollAngle = FlxMath.lerp(neededAngle, FlxG.camera.scrollAngle, Math.exp(-FlxG.elapsed * 6.125));

			if (!cameraDance && Math.abs(FlxG.camera.scrollAngle) < 0.01)
			{
				FlxG.camera.scrollAngle = 0;
				angleActive = false;
			}
		}
	}

	var cameraDance:Bool = false;
	var neededAngle:Float = 0;
	var angleActive:Bool = false;

	var crowd2Bop:Bool = false;
	var crowd2Right:Bool = false;
	var trippyMult:Float = 1;

	function tweenTo(obj, field:String, to:Float, time:Float, ease)
	{
		var from:Float = Reflect.getProperty(obj, field);
		return FlxTween.num(from, to, time, {ease: ease}, v -> Reflect.setProperty(obj, field, v));
	}

	function setComboPopUpsVisible(how:Bool)
	{
		var popUps = ModuleHandler.getModule('RatingComboModule').ratingPopUps;
		if (popUps != null)
			popUps.visible = how;
	}

	override function onBeatHit(event)
	{
		super.onBeatHit(event);

		var songId = PlayState.instance.currentSong.id;

		crowd2Bop = (event.beat > 95 && event.beat < 129 && songId == "bopeebo-animania")
			|| (event.beat > 145 && event.beat < 175 && songId == "fresh-animania");

		if (allowedColorChange > 0 && event.beat % allowedColorChange == 0)
			setLight();

		neededAngle = (cameraDance) ? ((neededAngle > 0) ? -.5 : .5) : 0;
		if (cameraDance)
			angleActive = true;

		if (!Save.instance.modOptions["lowQuality"])
		{
			if (crowd1Tween != null)
				crowd1Tween.cancel();
			crowd1.y = 780;
			crowd1Tween = FlxTween.num(780, 770, .5, {ease: FlxEase.backOut}, v -> crowd1.y = v);

			if (crowd2Bop)
				crowd2.anim.play(crowd2Right ? "dL" : "dR", true);
			else
				crowd2.anim.play("y", true);

			crowd3.anim.play("y", true);

			crowd2Right = !crowd2Right;
		}

		if (songId == "fresh-animania")
		{
			if (event.beat == 48)
			{
				itsSoloTime = true;
				projectDad();
				if (Save.instance.modOptions["shaders"])
				{
					bfRim.stopFade();
					bfRim.threshold = 0;
				}
			}

			if (event.beat == 56)
			{
				itsSoloTime = true;
				setLight();
				if (Save.instance.modOptions["shaders"])
				{
					dadRim.stopFade();
					dadRim.threshold = 0;
				}
			}

			if (event.beat == 65)
			{
				itsSoloTime = true;
				projectGF();
			}

			if (event.beat == 72)
			{
				itsSoloTime = true;
				putProjectors(0xFF99FFFF, .45, .7);
				if (Save.instance.modOptions["shaders"])
				{
					dadRim.stopFade();
					dadRim.threshold = 0;
				}
			}

			if (event.beat >= 74 && event.beat <= 76)
			{
				itsSoloTime = false;
				putProjectors(0xFF99FFFF, 0.45, FlxG.random.float(.4, .8));
				if (Save.instance.modOptions["shaders"])
				{
					bfRim.threshold = 0.4;
					bfRim.fadeThreshold(0.0, 0.35, FlxEase.circOut);
				}
			}

			if (event.beat == 80)
			{
				itsSoloTime = false;
				cameraDance = false;
				for (p in spotlighShits)
					p.targetSpotlight.animation.play('off', true);
			}

			if (event.beat == 110)
				setComboPopUpsVisible(false);

			if (event.beat == 112)
			{
				itsSoloTime = true;
				setLight(false, FlxColor.WHITE);
				for (smoke in smokes)
					smoke.alpha = 1;

				if (Save.instance.modOptions["shaders"])
				{
					FlxTween.num(highShader.effectiveness, .2, 10, {ease: FlxEase.sineInOut}, i -> highShader.effectiveness = i);
					FlxTween.num(trippyShader.darkness, .5, 10, {ease: FlxEase.sineInOut}, i -> trippyShader.darkness = i);
					FlxTween.num(trippyShader.intensity, 2, 10, {ease: FlxEase.sineInOut}, i -> trippyShader.intensity = i);
				}
				trippyMult = 0.75;
			}

			if (event.beat == 144)
			{
				setComboPopUpsVisible(true);
				itsSoloTime = false;
				allowedColorChange = 1;
				cameraDance = true;
				setLight();
				for (smoke in smokes)
					tweenTo(smoke, 'alpha', 0, 6, FlxEase.smootherStepInOut);

				if (Save.instance.modOptions["shaders"])
				{
					FlxTween.num(highShader.effectiveness, 0, .25, {ease: FlxEase.cubeOut}, i -> highShader.effectiveness = i);
					FlxTween.num(trippyShader.darkness, .4, 2, {ease: FlxEase.sineInOut}, i -> trippyShader.darkness = i);
					FlxTween.num(trippyShader.intensity, .95, 2, {ease: FlxEase.sineInOut}, i -> trippyShader.intensity = i);
				}
				trippyMult = 2;
				FlxTween.num(trippyMult, 0.9, .75, {ease: FlxEase.sineInOut}, i -> trippyMult = i);
			}

			if (event.beat == 176)
			{
				itsSoloTime = false;
				allowedColorChange = 2;
				cameraDance = false;
				setLight();
			}

			if (event.beat == 206)
			{
				itsSoloTime = false;
				setLight(true);
			}

			if (event.beat == 208)
			{
				itsSoloTime = true;
				allowedColorChange = 0;
				cameraDance = false;
				setLight(false, FlxColor.WHITE);

				tweenTo(getNamedProp('vin2'), 'alpha', .5, 3, FlxEase.cubeOut);

				if (Save.instance.modOptions["shaders"])
				{
					FlxTween.num(trippyShader.darkness, 0, 1, {ease: FlxEase.sineInOut}, i -> trippyShader.darkness = i);
					FlxTween.num(trippyShader.intensity, 0, 1, {ease: FlxEase.sineInOut}, i -> trippyShader.intensity = i);
					FlxTween.num(trippyMult, 0, 1, {ease: FlxEase.sineInOut}, i -> trippyMult = i);
				}
			}
		}
	}

	var lightColors = [FlxColor.WHITE, 0xFF00F9FF, 0xFF2BFF00, 0xFFFF4F00, 0xFFCC00FF, 0xFFFF0064];
	var currentLightsColor = null;
	var allowedColorChange:Int = 0;

	public function setLight(?turnOff:Bool = false, ?forceColor:FlxColor)
	{
		if (turnOff)
		{
			allowedColorChange = 0;
			floorLightBged.animation.play("off", true);
			floorLights.alpha = 0.00001;
			floorLightsBlendy.alpha = 0.00001;

			for (p in spotlighShits)
				p.targetSpotlight.animation.play('off', true);

			if (Save.instance.modOptions["shaders"])
			{
				bfRim.stopFade();
				dadRim.stopFade();
				bfRim.threshold = 0;
				dadRim.threshold = 0;
			}

			return;
		}

		if (forceColor == null)
		{
			var oldColor = currentLightsColor;
			while (currentLightsColor == oldColor)
				currentLightsColor = lightColors[FlxG.random.int(1, lightColors.length - 1)];
		}
		else
			currentLightsColor = forceColor;

		putProjectors(currentLightsColor);

		if (itsSoloTime)
			return;

		for (p in spotlighShits)
			p.targetSpotlight.animation.play('on', true);

		floorLightBged.animation.play("on", true);
		floorLights.alpha = .9;
		floorLights.color = currentLightsColor;
		floorLightsBlendy.alpha = .9;
		floorLightsBlendy.color = currentLightsColor;

		if (Save.instance.modOptions["shaders"])
		{
			bfRim.color = currentLightsColor;
			dadRim.color = currentLightsColor;
			bfRim.strength = .6;
			dadRim.strength = .6;
			bfRim.threshold = 0.1;
			dadRim.threshold = 0.1;
		}
	}

	var itsSoloTime:Bool = false;

	function putProjectors(lightColor, ?coolAlpha:Float = .45, ?ass:Float = 1)
	{
		if (!itsSoloTime)
		{
			for (spot in spotlighShits)
			{
				spot.alpha = ass;
				spot.color = lightColor;
				spot.targetSpotlight.animation.play('on', true);
				spot.tweenAngle(FlxG.random.float(-18, 18), FlxG.random.float(0.5, 1.5) * 0.2, FlxEase.circOut);
			}

			if (Save.instance.modOptions["shaders"])
			{
				bfRim.color = lightColor;
				bfRim.strength = .8;
				bfRim.threshold = 0.1;
				dadRim.color = lightColor;
				dadRim.strength = .8;
				dadRim.threshold = 0.1;

				bfRim.fadeThreshold(0.0, 0.4, FlxEase.circOut);
				dadRim.fadeThreshold(0.0, 0.4, FlxEase.circOut);
			}
		}
		else
		{
			if (spotlighShits.length < 4)
				return;

			for (p in spotlighShits)
				p.targetSpotlight.animation.play('on', true);

			spotlighShits[1].alpha = 0;
			spotlighShits[1].targetSpotlight.angle = 0;

			spotlighShits[0].tweenAngle(-35, FlxG.random.float(0.25, .5), FlxEase.circOut);
			spotlighShits[0].alpha = coolAlpha;
			spotlighShits[0].color = 0xFF99FFFF;

			spotlighShits[2].tweenAngle(15, FlxG.random.float(0.25, .5), FlxEase.circOut);
			spotlighShits[2].alpha = coolAlpha;
			spotlighShits[2].color = 0xFF99FFFF;

			spotlighShits[3].tweenAngle(-20, FlxG.random.float(0.25, .5), FlxEase.circOut);
			spotlighShits[3].alpha = coolAlpha;
			spotlighShits[3].color = 0xFF99FFFF;

			if (Save.instance.modOptions["shaders"])
			{
				bfRim.stopFade();
				bfRim.color = 0xFF99FFFF;
				dadRim.color = 0xFF99FFFF;
				bfRim.strength = .6;
				bfRim.threshold = 0.1;
			}
		}
	}

	function projectDad()
	{
		if (spotlighShits.length < 4)
			return;

		for (p in spotlighShits)
			p.targetSpotlight.animation.play('on', true);

		spotlighShits[0].alpha = .45;
		spotlighShits[0].color = 0xFF99FFFF;
		spotlighShits[0].tweenAngle(15, FlxG.random.float(0.25, .5), FlxEase.circOut);

		spotlighShits[1].alpha = .45;
		spotlighShits[1].color = 0xFF99FFFF;
		spotlighShits[1].tweenAngle(-20, FlxG.random.float(0.25, .5), FlxEase.circOut);

		spotlighShits[3].alpha = .45;
		spotlighShits[3].color = 0xFF99FFFF;
		spotlighShits[3].tweenAngle(40, FlxG.random.float(0.25, .5), FlxEase.circOut);

		spotlighShits[2].targetSpotlight.animation.play('off', true);
		spotlighShits[2].alpha = 0;

		if (Save.instance.modOptions["shaders"])
		{
			bfRim.stopFade();
			dadRim.stopFade();
			dadRim.color = 0xFF99FFFF;
			bfRim.strength = 0;
			dadRim.strength = .6;
			dadRim.threshold = 0.1;
		}
	}

	function projectGF()
	{
		if (spotlighShits.length < 4)
			return;

		for (p in spotlighShits)
			p.targetSpotlight.animation.play('on', true);

		spotlighShits[0].alpha = .3;
		spotlighShits[0].color = 0xFF99FFFF;
		spotlighShits[0].tweenAngle(-25, FlxG.random.float(0.25, .5), FlxEase.circOut);

		spotlighShits[1].alpha = .3;
		spotlighShits[1].tweenAngle(-20, FlxG.random.float(0.25, .5), FlxEase.circOut);

		spotlighShits[3].alpha = .3;
		spotlighShits[3].color = 0xFF99FFFF;
		spotlighShits[3].tweenAngle(25, FlxG.random.float(0.25, .5), FlxEase.circOut);

		spotlighShits[2].alpha = .3;
		spotlighShits[2].tweenAngle(15, FlxG.random.float(0.25, .5), FlxEase.circOut);

		if (Save.instance.modOptions["shaders"])
		{
			bfRim.stopFade();
			dadRim.stopFade();
			bfRim.strength = .3;
			dadRim.strength = .3;
			bfRim.threshold = 0.1;
			dadRim.threshold = 0.1;
		}
	}

	function setSmokeVisible(how:Bool)
	{
		for (prop in namedProps)
			if (prop.name.indexOf("smoke-") != -1)
				prop.alpha = how ? 1 : 0.00001;
	}

	override function onSongEvent(event)
	{
		super.onSongEvent(event);

		var eventData = event.eventData;
		switch (eventData.eventKind)
		{
			case "Blank":
				var v = eventData.value;
				if (v != null)
				{
					trace(v.value1);
					trace(v.value2);
					trace(v.value3);
					trace(v.value4);
					trace(v.value5);
				}
		}
	}
}
