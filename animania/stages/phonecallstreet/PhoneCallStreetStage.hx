package animania.stages.phonecallstreet;

class PhoneCallStreetStage extends ScriptedStage
{
	function new()
	{
		super('phoneCallStreet');
	}

	function lowQualityMode():Bool
	{
		return Save.instance.modOptions["lowQuality"] == true;
	}

	function shadersEnabled():Bool
	{
		return Save.instance.modOptions["shaders"] == true;
	}

	var bloomShader:BloomShader = null;
	var bloomFilter:ShaderFilter = null;
	var filterCam = null;

	var bgSky:FlxBackdrop = null;

	var leafs = [];
	var leafBaseScale = [];
	var leafZoomFactor = [];
	var leafsBounds = [-1500, 1500, -150, 50];

	var ps = null;

	var seenCountdown:Bool = false;
	var basesStored:Bool = false;
	var standActive:Bool = false;
	var origBfId:String = null;
	var origDadId:String = null;

	var blackScreenSpr = null;
	var barTop = null;
	var barBottom = null;
	var introText = null;

	var timers = [];

	var baseOppX:Float = 0;
	var baseOppY:Float = 0;
	var basePlrX:Float = 0;
	var basePlrY:Float = 0;
	var baseBarY:Float = 0;
	var baseBarBgY:Float = 0;
	var baseIcon1Y:Float = 0;
	var baseIcon2Y:Float = 0;

	// Posiciones originales de la barra curva (bg / rojo / verde). La animacion de muerte de Tadano las sube 250px;
	// sin restaurarlas, al volver del gameover la barra y los iconos (que se anclan a la barra) quedan fuera de pantalla.
	var curvedBases = [];

	var PLAYER_STRUM_SCALE:Float = 1.05;
	var OPPONENT_STRUM_SCALE:Float = 0.95;

	var mcTan = [0.0, 0.0];
	var mcShake = [0.0, 0.0];
	var mcScale = [1.0, 1.0];
	var mcScaleApplied = [1.0, 1.0];
	var mcTweens = new StringMap();
	var mcTime:Float = 0;
	var mcPostFn = null;
	var mcWasActive = [false, false];
	var mcAlphaIsOne = [false, false];
	var mcTanAmp:Float = 45.0;
	var mcShx = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
	var mcShy = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
	var mcRecX = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
	var mcRecY = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

	override function buildStage():Void
	{
		leafs = [];
		leafBaseScale = [];
		leafZoomFactor = [];

		super.buildStage();

		if (Save.instance.modOptions['lowQuality'])
		{
			removeLowQualityProps();
		}

		if (shadersEnabled())
		{
			bloomShader = new BloomShader();
			bloomFilter = new ShaderFilter(bloomShader);
			filterCam = FlxG.camera;
			filterCam.filters = [bloomFilter];
		}

		bgSky = new FlxBackdrop(Paths.image('stages/phoneCallStreet/sky'), 0x01, -1885.85, -831.5);
		bgSky.scrollFactor.set(0.1, 0.1);
		bgSky.velocity.x = 20;
		bgSky.scale.set(1.2, 1.2);
		bgSky.zIndex = -13;
		add(bgSky);

		var lightShade = getNamedProp("lightShade");
		if (lightShade != null)
		{
			var width = 1882.6 * 3;
			lightShade.scrollFactor.set(0., 1.);
			lightShade.blend = BlendMode.ADD;
			lightShade.alpha = 0.1;
			lightShade.scale.x = width;
			lightShade.scale.y *= 2;
			lightShade.updateHitbox();
		}

		for (prop in namedProps)
			if (prop.name.indexOf("stand-") != -1)
				prop.visible = false;

		if (!lowQualityMode())
		{
			for (i in 0...3)
				spawnLeaf();
		}

		refresh();
	}

	override function addCharacter(character, charType):Void
	{
		super.addCharacter(character, charType);

		if (charType == CharacterType.DAD && character != null)
			character.scrollFactor.set(0.9, 0.95);
	}

	var _lowQualityProps = ['far city', 'bg trees', 'stand-housesFAR'];

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

	function spawnLeaf():Void
	{
		var leaf = new FunkinSprite();
		leaf.loadSparrow("stages/phoneCallStreet/leafs");
		if (leaf.frames == null)
		{
			leaf.destroy();
			return;
		}

		leaf.animation.addByPrefix("y", "leaf", 24, true);
		leaf.zIndex = 900;

		leafs.push(leaf);
		leafBaseScale.push(1.0);
		leafZoomFactor.push(1.0);

		resetLeaf(leafs.length - 1);
		add(leaf);
	}

	function resetLeaf(i:Int):Void
	{
		var leaf = leafs[i];

		leaf.angularVelocity = FlxG.random.float(-25, 65);
		leaf.velocity.x = FlxG.random.float(-225, 275);
		leaf.velocity.y = FlxG.random.float(225, 450);

		leaf.animation.play("y", true);
		if (leaf.animation.curAnim != null)
		{
			leaf.animation.curAnim.curFrame = FlxG.random.int(0, leaf.animation.curAnim.numFrames - 1);
			leaf.animation.curAnim.frameRate = FlxG.random.int(4, 24);
		}

		leaf.x = FlxG.random.float(leafsBounds[0], leafsBounds[1]);
		leaf.y = FlxG.random.float(leafsBounds[2], leafsBounds[3]);

		leafZoomFactor[i] = FlxG.random.float(.7, .9);
		leafBaseScale[i] = FlxG.random.float(1.1, 1.35);
		leaf.scale.set(leafBaseScale[i], leafBaseScale[i]);
		leaf.scrollFactor.x = FlxG.random.float(.9, 1.1);
	}

	function updateLeafs():Void
	{
		if (lowQualityMode())
			return;

		var zoom = FlxG.camera.zoom;

		for (i in 0...leafs.length)
		{
			var leaf = leafs[i];

			if (leaf.y > 1550)
				resetLeaf(i);

			if (zoom != 0)
			{
				var zf = leafZoomFactor[i];
				var r = ((1.0 - zf) + zf * zoom) / zoom;
				leaf.scale.set(leafBaseScale[i] * r, leafBaseScale[i] * r);
			}
		}
	}

	override function onUpdate(event)
	{
		super.onUpdate(event);

		updateLeafs();
	}

	override function onBeatHit(event)
	{
		super.onBeatHit(event);

		if (PlayState.instance.isPlayerDying)
			return;

		phoneBeat(event.beat);

		if (lowQualityMode())
			return;

		if (FlxG.random.bool(10) && leafs.length <= 9)
			spawnLeaf();
	}

	override function onCountdownStart(event)
	{
		super.onCountdownStart(event);

		ps = PlayState.instance;
		if (ps == null)
			return;

		resetPhoneState();

		FlxTimer.wait(0, () -> Countdown.skipCountdown());
	}

	function setComboPopUpsVisible(how:Bool)
	{
		var popUps = ModuleHandler.getModule('RatingComboModule').ratingPopUps;
		if (popUps != null)
			popUps.visible = how;
	}

	override function onSongRetry(event)
	{
		super.onSongRetry(event);

		ps = PlayState.instance;
		if (ps == null)
			return;

		if (standActive)
			swapBack();

		resetPhoneState();
	}

	override function onSongStart(event)
	{
		super.onSongStart(event);
		setComboPopUpsVisible(false);
		if (ps != null && ps.iconP1 != null && !ps.isMinimalMode)
		{
			ps.iconP1.bopEvery = 16;
			ps.iconP2.bopEvery = 16;
		}
	}

	override function onGameOver(e)
	{
		super.onGameOver(e);
		clearFilters();
	}

	override function onDestroy(e)
	{
		clearFilters();
		cancelTimers();

		if (mcPostFn != null)
		{
			FlxG.signals.postUpdate.remove(mcPostFn);
			mcPostFn = null;
		}

		if (ps != null && introText != null)
			ps.remove(introText, true);

		leafs = [];
		leafBaseScale = [];
		leafZoomFactor = [];
		blackScreenSpr = null;
		barTop = null;
		barBottom = null;
		introText = null;
		ps = null;

		super.onDestroy(e);
	}

	function clearFilters():Void
	{
		if (filterCam != null)
			filterCam.filters = null;
	}

	function resetPhoneState():Void
	{
		cancelTimers();

		styleSubtitles();

		if (ps.isMinimalMode)
			return;

		if (!seenCountdown)
		{
			seenCountdown = true;
			FunkinMemory.cacheTexture(Paths.image("characters/phonecall/tadano-stand", "shared"));
			FunkinMemory.cacheTexture(Paths.image("characters/phonecall/komi-stand", "shared"));
		}

		if (!basesStored)
		{
			basesStored = true;
			baseOppX = ps.opponentStrumline.x;
			baseOppY = ps.opponentStrumline.y;
			basePlrX = ps.playerStrumline.x;
			basePlrY = ps.playerStrumline.y;
			baseBarY = ps.healthBar.y;
			baseBarBgY = ps.healthBarBG.y;
			baseIcon1Y = ps.iconP1.y;
			baseIcon2Y = ps.iconP2.y;
		}

		FlxTween.cancelTweensOf(ps.camHUD);
		ps.camHUD.alpha = 0;
		ps.camHUD.zoom = 1;
		ps.disableKeys = true;

		for (obj in [ps.healthBar, ps.healthBarBG, ps.iconP1, ps.iconP2])
		{
			if (obj != null)
			{
				FlxTween.cancelTweensOf(obj);
				obj.alpha = 1;
			}
		}
		ps.healthBar.y = baseBarY;
		ps.healthBarBG.y = baseBarBgY;
		ps.iconP1.y = baseIcon1Y;
		ps.iconP2.y = baseIcon2Y;
		restoreCurvedBarPositions();
		setCurvedBarAlpha(1);

		removeSprite(blackScreenSpr);
		blackScreenSpr = new FunkinSprite();
		blackScreenSpr.makeSolidColor(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.BLACK);
		blackScreenSpr.scrollFactor.set();
		blackScreenSpr.x = -FlxG.width;
		blackScreenSpr.y = -FlxG.height;
		blackScreenSpr.zIndex = 5999;
		blackScreenSpr.cameras = [ps.camCutscene];
		ps.add(blackScreenSpr);

		var barHeight = 100;

		removeSprite(barTop);
		barTop = new FunkinSprite();
		barTop.makeSolidColor(Std.int(FlxG.width * 1.5), barHeight + 20, 0xFF000000);
		barTop.zIndex = 499;
		barTop.scrollFactor.set();
		barTop.y = -20;
		barTop.screenCenter(0x01);
		barTop.cameras = [ps.camCutscene];
		ps.add(barTop);

		removeSprite(barBottom);
		barBottom = new FunkinSprite();
		barBottom.makeSolidColor(Std.int(FlxG.width * 1.5), barHeight + 20, 0xFF000000);
		barBottom.zIndex = 199;
		barBottom.scrollFactor.set();
		barBottom.y = FlxG.height - barBottom.height + 20;
		barBottom.screenCenter(0x01);
		barBottom.cameras = [ps.camCutscene];
		ps.add(barBottom);

		ps.refresh();

		for (s in [ps.opponentStrumline, ps.playerStrumline])
			FlxTween.cancelTweensOf(s);

		ps.playerStrumline.strumlineScale.set(PLAYER_STRUM_SCALE, PLAYER_STRUM_SCALE);
		ps.opponentStrumline.strumlineScale.set(OPPONENT_STRUM_SCALE, OPPONENT_STRUM_SCALE);

		ps.opponentStrumline.alpha = 0;
		ps.opponentStrumline.angle = 360;
		ps.opponentStrumline.x = baseOppX + FlxG.width;
		ps.opponentStrumline.y = baseOppY;

		ps.playerStrumline.alpha = 0;
		if (AmMlpc.playerStrum())
		{
		ps.playerStrumline.x = basePlrX - FlxG.width / 2;
		}
		ps.playerStrumline.y = basePlrY;

		mcReset();

		if (mcPostFn == null)
		{
			mcPostFn = function()
			{
				mcPost();
			};
			FlxG.signals.postUpdate.add(mcPostFn);
		}

		var gf = currentStageGf();
		if (gf != null)
			gf.visible = false;

		var bf = getBoyfriend();
		if (bf != null)
			bf.idleSuffix = "";

		if (camGameFadeDirty)
		{
			camGameFadeDirty = false;
			ps.camGame.stopFX();
			ps.camGame.color = FlxColor.WHITE;
		}

		setupIntroText();
	}

	function setupIntroText():Void
	{
		introText = getNamedProp("introText");
		if (introText == null)
		{
			trace("[phoneCallStreet] No existe el prop 'introText' (revisa el log: 'Could not build texture for prop').");
			return;
		}

		FlxTween.cancelTweensOf(introText);

		if (ps.members.indexOf(introText) == -1)
		{
			remove(introText);
			ps.add(introText);
		}

		introText.camera = ps.camCutscene;
		introText.scrollFactor.set(0, 0);
		introText.zIndex = 6000;
		introText.alpha = 0;
		ps.refresh();
	}

	var camGameFadeDirty:Bool = false;

	function currentStageGf()
	{
		return getGirlfriend();
	}

	function removeSprite(spr):Void
	{
		if (spr == null || ps == null)
			return;
		FlxTween.cancelTweensOf(spr);
		ps.remove(spr, true);
		spr.kill();
		spr.destroy();
	}

	function styleSubtitles():Void
	{
		if (ps.subtitles == null)
			return;

		var members = ps.subtitles.members;
		var i = 0;
		while (i < members.length)
		{
			var m = members[i];
			i = i + 1;
			if (m != null && Std.isOfType(m, FlxText))
			{
				m.font = Paths.font("MP Manga.ttf");
				m.size = 26;
			}
		}
	}

	function phoneBeat(beat:Int):Void
	{
		if (ps == null || ps.isMinimalMode)
			return;

		switch (beat)
		{
			case 0:
				ps.camHUD.alpha = 0;

			case 1:
				if (introText != null)
				{
					introText.visible = true;
					introText.scale.set(.8, .8);
					introText.updateHitbox();
					introText.screenCenter();
					introText.animation.play("loop", true);
					introText.alpha = 0;
					FlxTween.tween(introText, {alpha: 1}, 2.5, {ease: FlxEase.backOut});
				}

			case 11:
				if (introText != null)
					FlxTween.tween(introText, {alpha: 0}, 2.5, {ease: FlxEase.backOut});

			case 13:
				if (blackScreenSpr != null)
					FlxTween.tween(blackScreenSpr, {alpha: 0}, 2.5, {ease: FlxEase.backOut});

				var tad = getBoyfriend();
				if (tad != null)
				{
					var tadX0 = tad.x;
					tad.x += 380;
					FlxTween.tween(tad, {x: tadX0 + 30}, 1.45, {onComplete: function(_)
					{
						FlxTween.tween(tad, {x: tadX0}, .5, {ease: FlxEase.cubeOut});
					}});
					tad.playAnimation("intro", true, true);
				}

			case 16:
				ps.camGame.shake(.0005, .8);
				ps.camHUD.shake(.001, .8);

			case 19:
				ps.camGame.shake(.0005, .8);
				ps.camHUD.shake(.001, .8);

			case 23:
				ps.camGame.shake(.0005, .8);
				ps.camHUD.shake(.001, .8);

			case 31:
				ps.camHUD.zoom = 1.1;
				FlxTween.tween(ps.camHUD, {alpha: 1, zoom: 1}, .35);
				FlxTween.tween(ps.playerStrumline, {alpha: 1}, .35);

			case 33:
				removeSprite(barTop);
				removeSprite(barBottom);
				barTop = null;
				barBottom = null;
				ps.disableKeys = false;

			case 166:
				FlxTween.tween(ps.opponentStrumline, {angle: 0, alpha: 0.5, x: FlxG.width / 2 + Constants.STRUMLINE_X_OFFSET}, 1.35, {
					startDelay: 2,
					ease: FlxEase.cubeOut,
					onComplete: function(_)
					{
						mcEase("shake", 0, 0.05, Conductor.instance.beatLengthMs * 4 / 1000, FlxEase.sineOut);
					}
				});

			case 168:
				var tad2 = getBoyfriend();
				if (tad2 != null)
				{
					FlxTween.tween(tad2, {x: tad2.x + 800}, 1.35, {ease: FlxEase.cubeOut});
					tad2.idleSuffix = "-alt";
				}

			case 232:
				FlxTween.tween(ps.opponentStrumline, {alpha: 1}, 1.35, {ease: FlxEase.cubeOut});
				standUP();
				mcSet("shake", 0, 0);

			case 332:
				ps.disableKeys = true;
				var dir = AmScroll.isDown() ? 1 : -1;

				for (obj in [ps.healthBar, ps.healthBarBG, ps.iconP1, ps.iconP2])
					if (obj != null)
						FlxTween.tween(obj, {y: obj.y - 250 * dir, alpha: 0}, 1.75, {ease: FlxEase.smootherStepIn, startDelay: .25});

				fadeCurvedBar(1.75, .25);

				for (obj in [ps.playerStrumline, ps.opponentStrumline])
					FlxTween.tween(obj, {y: obj.y + 250 * dir, alpha: 0}, 1.75, {ease: FlxEase.smootherStepIn, startDelay: .5});

			case 348:
				camGameFadeDirty = true;
				ps.camGame.fade(FlxColor.BLACK, 3, false, function()
				{
					ps.camGame.color = FlxColor.BLACK;
				}, true);
		}

		if (beat > 232 && beat % 2 == 0)
		{
			var beatSec = Conductor.instance.beatLengthMs / 1000;

			mcSet("scale", 1.05, 0);
			mcEase("scale", 0, 1, beatSec, FlxEase.sineOut);

			mcSet("scale", 1.05, 1);
			mcEase("scale", 1, 0.95, beatSec, FlxEase.sineOut);
		}
	}

	function standUP():Void
	{
		if (ps == null || ps.isMinimalMode)
			return;

		var oldBf = getBoyfriend();
		var oldDad = getDad();
		origBfId = oldBf != null ? oldBf.characterId : "tadano-phone";
		origDadId = oldDad != null ? oldDad.characterId : "komi-phone";

		swapCharacter(CharacterType.BF, "tadano-stand", 500);
		swapCharacter(CharacterType.DAD, "komi-stand", 500);
		standActive = true;

		for (prop in namedProps)
			prop.visible = prop.name.indexOf("stand-") != -1;

		refresh();

		placeCharacter(getBoyfriend(), -175, 325, _data.characters.bf);
		placeCharacter(getDad(), 300, 325, _data.characters.dad);

		ps.camGame.flash(FlxColor.WHITE, 1.5);

		ps.tweenCameraZoom(0.8, 0, false);
	}

	function swapBack():Void
	{
		standActive = false;

		if (origBfId != null)
			swapCharacter(CharacterType.BF, origBfId, 0);
		if (origDadId != null)
			swapCharacter(CharacterType.DAD, origDadId, 0);

		for (prop in namedProps)
			prop.visible = prop.name.indexOf("stand-") == -1;

		refresh();
	}

	function swapCharacter(charType, id:String, zExtra:Int):Void
	{
		var old = (charType == CharacterType.BF) ? getBoyfriend(true) : getDad(true);
		var oldZ = 999;
		if (old != null)
		{
			oldZ = old.zIndex;
			old.visible = false;
			old.destroy();
		}

		var c = CharacterDataParser.fetchCharacter(id);
		if (c == null)
			return;

		addCharacter(c, charType);
		if (zExtra != 0)
			c.zIndex = oldZ + zExtra;
	}

	function placeCharacter(c, px:Float, py:Float, stageCharData):Void
	{
		if (c == null)
			return;

		c.setPosition(px, py);
		c.originalPosition.set(c.x, c.y);
		c.resetCameraFocusPoint();

		if (stageCharData != null)
		{
			c.cameraFocusPoint.x += stageCharData.cameraOffsets[0];
			c.cameraFocusPoint.y += stageCharData.cameraOffsets[1];
		}
	}

	function getCurvedBarSprites()
	{
		var list = [];
		try
		{
			var m = ModuleHandler.getModule("CurvedHealthBarModule");
			if (m != null)
			{
				for (spr in [m.bg, m.redBar, m.greenBar])
					if (spr != null)
						list.push(spr);
			}
		}
		catch (err:Dynamic) {}
		return list;
	}

	// Guarda (primera vez) / restaura la posicion de los sprites de la barra curva. Ver curvedBases.
	function restoreCurvedBarPositions():Void
	{
		for (spr in getCurvedBarSprites())
		{
			FlxTween.cancelTweensOf(spr);

			var found = null;
			for (b in curvedBases)
				if (b.spr == spr)
					found = b;

			if (found == null)
				curvedBases.push({spr: spr, x: spr.x, y: spr.y});
			else
			{
				spr.x = found.x;
				spr.y = found.y;
			}
		}
	}

	function setCurvedBarAlpha(a:Float):Void
	{
		for (spr in getCurvedBarSprites())
		{
			FlxTween.cancelTweensOf(spr);
			spr.alpha = a;
		}
	}

	function fadeCurvedBar(time:Float, delay:Float):Void
	{
		for (spr in getCurvedBarSprites())
			FlxTween.tween(spr, {alpha: 0}, time, {ease: FlxEase.smootherStepIn, startDelay: delay});
	}

	function cancelTimers():Void
	{
		var i = 0;
		while (i < timers.length)
		{
			var t = timers[i];
			i = i + 1;
			if (t != null)
				t.cancel();
		}
		timers = [];
	}

	function mcReset():Void
	{
		mcTan = [0.0, 0.0];
		mcShake = [0.0, 0.0];
		mcScale = [1.0, 1.0];
		mcScaleApplied = [1.0, 1.0];
		mcWasActive = [false, false];
		mcAlphaIsOne = [false, false];

		for (k in mcTweens.keys())
		{
			var tw = mcTweens.get(k);
			if (tw != null)
				tw.cancel();
		}
		mcTweens = new StringMap();

		var i = 0;
		while (i < 8)
		{
			mcShx[i] = 0.0;
			mcShy[i] = 0.0;
			mcRecX[i] = 0.0;
			mcRecY[i] = 0.0;
			i += 1;
		}
	}

	function mcGetValue(name:String, lane:Int):Float
	{
		switch (name)
		{
			case "tanWave":
				return mcTan[lane];
			case "shake":
				return mcShake[lane];
			case "scale":
				return mcScale[lane];
		}
		return 0.0;
	}

	function mcSet(name:String, value:Float, lane:Int):Void
	{
		var key = name + lane;
		var tw = mcTweens.get(key);
		if (tw != null)
			tw.cancel();
		mcTweens.remove(key);

		switch (name)
		{
			case "tanWave":
				mcTan[lane] = value;
			case "shake":
				mcShake[lane] = value;
			case "scale":
				mcScale[lane] = value;
		}
	}

	function mcEase(name:String, lane:Int, target:Float, seconds:Float, ease):Void
	{
		var key = name + lane;
		var old = mcTweens.get(key);
		if (old != null)
			old.cancel();

		var from = mcGetValue(name, lane);
		var tw = FlxTween.num(from, target, seconds, {ease: ease}, function(v)
		{
			switch (name)
			{
				case "tanWave":
					mcTan[lane] = v;
				case "shake":
					mcShake[lane] = v;
				case "scale":
					mcScale[lane] = v;
			}
		});
		mcTweens.set(key, tw);
	}

	function mcTanOffset(lane:Int, col:Int, dist:Float):Float
	{
		if (mcTan[lane] == 0)
			return 0.0;

		var tv = Math.tan(mcTime * 1.5 + col * 0.25 + dist * 0.006);
		if (tv > 2)
			tv = 2;
		if (tv < -2)
			tv = -2;
		return mcTan[lane] * mcTanAmp * tv;
	}

	function mcDist(strumTime:Float, s):Float
	{
		var d = (strumTime - Conductor.instance.songPosition) * 0.45 * s.scrollSpeed;
		return (d < 0) ? 0.0 : d;
	}

	function syncStrumlineAlpha(s, lane):Void
	{
		var a = s.alpha;

		var c = 0;
		while (c < 4)
		{
			var r = s.getByIndex(c);
			if (r != null && r.alpha != a)
				r.alpha = a;
			c += 1;
		}

		if (a == 1.0)
		{
			if (mcAlphaIsOne[lane])
				return;
			mcAlphaIsOne[lane] = true;
		}
		else
		{
			mcAlphaIsOne[lane] = false;
		}

		var nm = s.notes.members;
		var nlen = nm.length;
		var i = 0;
		while (i < nlen)
		{
			var n = nm[i];
			i += 1;
			if (n == null || !n.alive)
				continue;

			var na = n.handledMiss ? a * 0.5 : a;
			if (n.alpha != na)
				n.alpha = na;
		}

		var hm = s.holdNotes.members;
		var hlen = hm.length;
		var j = 0;
		while (j < hlen)
		{
			var h = hm[j];
			j += 1;
			if (h == null || !h.alive || h.missedNote)
				continue;

			if (h.alpha != a)
				h.alpha = a;
		}
	}

	var mcColXs = [0.0, 0.0, 0.0, 0.0];

	function mcFillColX(s)
	{
		var c = 0;
		while (c < 4)
		{
			var v = 0.0;
			var ok = false;
			try
			{
				v = s.getXPos(s.getByIndex(c).direction);
				ok = true;
			}
			catch (e:Dynamic)
			{
			}
			if (!ok) v = c * 112 * s.strumlineScale.x;
			mcColXs[c] = v;
			c += 1;
		}
	}

	function mcPost():Void
	{
		if (ps == null || ps.currentStage == null || ps.isMinimalMode)
			return;

		mcTime = Conductor.instance.songPosition / 1000;
		var songPos = Conductor.instance.songPosition;
		var t15 = mcTime * 1.5;

		var lane = 0;
		while (lane < 2)
		{
			var s = (lane == 0) ? ps.opponentStrumline : ps.playerStrumline;
			if (s == null)
			{
				lane += 1;
				continue;
			}

			syncStrumlineAlpha(s, lane);

			var active = (mcTan[lane] != 0 || mcShake[lane] != 0 || mcScale[lane] != 1.0 || mcScaleApplied[lane] != 1.0);
			if (!active && !mcWasActive[lane])
			{
				lane += 1;
				continue;
			}
			mcWasActive[lane] = active;

			var sx = s.strumlineScale.x;
			var ratio = mcScale[lane] / mcScaleApplied[lane];
			mcFillColX(s);

			var c = 0;
			while (c < 4)
			{
				var si = lane * 4 + c;
				if (mcShake[lane] != 0)
				{
					mcShx[si] = (Math.random() * 2 - 1) * mcShake[lane] * 16;
					mcShy[si] = (Math.random() * 2 - 1) * mcShake[lane] * 16;
				}
				else
				{
					mcShx[si] = 0.0;
					mcShy[si] = 0.0;
				}
				c += 1;
			}

			c = 0;
			while (c < 4)
			{
				var ri = lane * 4 + c;
				var r = s.getByIndex(c);
				var rox = mcTanOffset(lane, c, 0) + mcShx[ri];
				var roy = mcShy[ri];
				r.x += rox - mcRecX[ri];
				r.y += roy - mcRecY[ri];
				mcRecX[ri] = rox;
				mcRecY[ri] = roy;
				if (ratio != 1.0)
					r.scale.set(r.scale.x * ratio, r.scale.y * ratio);
				c += 1;
			}

			var tanK = mcTan[lane] * mcTanAmp;
			var kd = 0.45 * s.scrollSpeed;
			var sxPos = s.x;
			var base = lane * 4;

			var nm = s.notes.members;
			var nlen = nm.length;
			var i = 0;
			while (i < nlen)
			{
				var n = nm[i];
				i += 1;
				if (n == null || !n.alive || n.noteData == null)
					continue;

				var col = n.noteData.getDirection() % 4;
				if (ratio != 1.0)
					n.scale.set(n.scale.x * ratio, n.scale.y * ratio);

				var ox = mcShx[base + col];
				if (tanK != 0)
				{
					var d = (n.strumTime - songPos) * kd;
					if (d < 0) d = 0.0;
					var tv = Math.tan(t15 + col * 0.25 + d * 0.006);
					if (tv > 2) tv = 2;
					if (tv < -2) tv = -2;
					ox += tanK * tv;
				}
				n.yOffset = mcShy[base + col];

				n.x = sxPos + mcColXs[col] - (n.width - 104) / 2 - 2 + ox;
			}

			var hm = s.holdNotes.members;
			var hlen = hm.length;
			var j = 0;
			while (j < hlen)
			{
				var h = hm[j];
				j += 1;
				if (h == null || !h.alive)
					continue;

				var hcol = h.noteDirection % 4;
				var hox = mcShx[base + hcol];
				if (tanK != 0)
				{
					var hd = (h.strumTime - songPos) * kd;
					if (hd < 0) hd = 0.0;
					var htv = Math.tan(t15 + hcol * 0.25 + hd * 0.006);
					if (htv > 2) htv = 2;
					if (htv < -2) htv = -2;
					hox += tanK * htv;
				}
				h.yOffset = mcShy[base + hcol];
				h.x = sxPos + mcColXs[hcol] + 52 - h.width / 2 + hox;
			}

			mcScaleApplied[lane] = mcScale[lane];
			lane += 1;
		}
	}
}
