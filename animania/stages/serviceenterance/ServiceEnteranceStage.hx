package animania.stages.serviceenterance;

class ServiceEnteranceStage extends Stage
{
	var useShaders = true;
	var lowQuality = false;

	var rainShader = null;
	var rainShaderFilter = null;
	var rainShaderStartIntensity = 0.1;
	var rainShaderEndIntensity = 0.3;
	var rainSpeedMult = 1.0;

	var bfRim = null;
	var dadRim = null;
	var bfBaseColor = 0xFFFFF56D;
	var dadBaseColor = 0xFFFFFFFF;
	var bfRimAmt = 0.0;
	var dadRimAmt = 0.0;
	var bfRimTween = null;
	var dadRimTween = null;

	var carInterruptable = true;
	var car2Interruptable = true;

	var lastChange = 0;
	var changeInterval = 8;

	var mist0 = null;
	var mist1 = null;
	var mist2 = null;
	var mist3 = null;
	var mist4 = null;
	var mist5 = null;

	var rainSndAmbience = null;
	var carSndAmbience = null;
	var carRide1 = null;
	var carRide2 = null;
	var _sounds = [];

	var _ready = false;
	var _timer = 0.0;
	var _flickerTime = 0.0;
	var _alphaTarget = 1.0;

	function new()
	{
		super('serviceEnterance');
	}

	override function onCreate(event)
	{
		super.onCreate(event);

		getNamedProp('holygrad').cameras = [PlayState.instance.camHUD];
		getNamedProp('fgRedOverlay').cameras = [PlayState.instance.camHUD];

		PauseSubState.musicSuffix = '-amtake1';

		_ready = false;
		_timer = 0.0;
		_flickerTime = 0.0;
		_alphaTarget = 1.0;
		lastChange = 0;
		rainSpeedMult = 1.0;

		resetCar(true, true);
	}

	function makeMist(asset, x, y, scroll, z, alpha, velX, scale)
	{
		var mist = new FlxBackdrop(Paths.image('stages/serviceEnterance/' + asset), 0x01);
		mist.setPosition(x, y);
		mist.scrollFactor.set(scroll, scroll);
		mist.zIndex = z;
		mist.blend = BlendMode.ADD;
		mist.color = 0xFF5c5c5c;
		mist.alpha = alpha;
		mist.velocity.x = velX;
		mist.scale.set(scale, scale);
		add(mist);
		return mist;
	}

	var _lowQualityProps = ['bulbb', 'vendingLight', 'fgBoxes', 'rain', 'fgMist', 'phillyCars', 'phillyCars2'];

	function removeLowQualityProps()
	{
		var names = _lowQualityProps;
		var boppers = Reflect.field(this, 'boppers');
		var named = Reflect.field(this, 'namedProps');

		var i = 0;
		while (i < names.length)
		{
			var prop = getNamedProp(names[i]);
			if (prop != null)
			{
				FlxTween.cancelTweensOf(prop);
				if (boppers != null) boppers.remove(prop);
				if (named != null) named.remove(names[i]);
				remove(prop);
				prop.kill();
				prop.destroy();
			}
			i = i + 1;
		}
	}

	override function buildStage()
	{
		super.buildStage();

		if (Save.instance.modOptions["lowQuality"])
		{
			removeLowQualityProps();
			return;
		}

		mist0 = makeMist('mistMid', -650, 340, 1.2, 1000, 0.6, 172, 1);
		mist1 = makeMist('mistMid', -650, 305, 1.1, 1000, 0.6, 150, 1);
		mist2 = makeMist('mistBack', -650, 315, 1.2, 1001, 0.8, -80, 1);
		mist3 = makeMist('mistMid', -650, 320, 0.95, 30, 0.5, -50, 0.8);
		mist4 = makeMist('mistBack', -650, -250, 0.8, 5, 1, 40, 0.7);
		mist5 = makeMist('mistMid', -650, -400, 0.5, 7, 1, 20, 1.1);

		refresh();
	}

	override function onCountdownStart(event)
	{
		super.onCountdownStart(event);

		setupRuntime();
		resetCar(true, true);
	}

	function scaleColor(base, amt)
	{
		var k = Math.max(0, Math.min(1, amt));
		var r = Std.int(((base >> 16) & 0xFF) * k);
		var g = Std.int(((base >> 8) & 0xFF) * k);
		var b = Std.int((base & 0xFF) * k);
		return 0xFF000000 | (r << 16) | (g << 8) | b;
	}

	function createRim(char)
	{
		var rim = new DropShadowShader();
		rim.setAdjustColor(-5, -26, 0, -16);
		rim.angle = 115;
		rim.distance = 20;
		rim.strength = 1;
		rim.threshold = 0.1;
		rim.color = 0xFF000000;

		char.shader = rim;
		rim.attachedSprite = char;

		if (!char.isAnimate)
		{
			char.animation.onFrameChange.add(function(name, frameNum, frameIndex)
			{
				if (char.frame != null) rim.updateFrameInfo(char.frame);
			});
		}

		return rim;
	}

	function fadeBfRim(to, time, opts)
	{
		if (bfRimTween != null) bfRimTween.cancel();
		bfRimTween = FlxTween.num(bfRimAmt, to, time, opts, function(v)
		{
			bfRimAmt = v;
			if (bfRim != null) bfRim.color = scaleColor(bfBaseColor, v);
		});
	}

	function fadeDadRim(to, time, opts)
	{
		if (dadRimTween != null) dadRimTween.cancel();
		dadRimTween = FlxTween.num(dadRimAmt, to, time, opts, function(v)
		{
			dadRimAmt = v;
			if (dadRim != null) dadRim.color = scaleColor(dadBaseColor, v);
		});
	}

	function randomizeStartFrames(layer)
	{
		if (layer == null) return;

		var elements = layer.frames[0].elements;
		var i = 0;
		while (i < elements.length)
		{
			elements[i].toSymbolInstance().firstFrame = FlxG.random.int(0, 9);
			i = i + 1;
		}
	}

	function setupRuntime()
	{
		if (_ready) return;
		_ready = true;

		var cam = PlayState.instance.camGame;
		var bf = getBoyfriend();
		var dad = getDad();
		var gf = getGirlfriend();

		if (Save.instance.modOptions["shaders"])
		{
			if (bf != null) bfRim = createRim(bf);
			if (dad != null) dadRim = createRim(dad);
			bfRimAmt = 0.0;
			dadRimAmt = 0.0;

			rainSpeedMult = 1.0;
			rainShader = new RuntimeRainShader();
			rainShader.intensity = rainShaderStartIntensity;
			rainShader.scale = FlxG.height / 300;
			rainShader.rainColor = 0xFF5DD19B;
			rainShader.updateViewInfo(FlxG.width, FlxG.height, cam);

			rainShaderFilter = new ShaderFilter(rainShader);
			var filters = cam.filters;
			if (filters == null) filters = [];
			filters[filters.length] = rainShaderFilter;
			cam.filters = filters;
		}

		rainSndAmbience = FunkinSound.load(Paths.sound('gameplay/stages/serviceEnterance/rainAmbience'), 1, true, false, false);
		if (rainSndAmbience != null)
		{
			rainSndAmbience.volume = 0;
			rainSndAmbience.play(false, FlxG.random.float(0, rainSndAmbience.length));
		}

		carSndAmbience = FunkinSound.load(Paths.sound('gameplay/stages/serviceEnterance/carAmbience'), 1, true, false, false);
		if (carSndAmbience != null)
		{
			carSndAmbience.volume = 0.1;
			carSndAmbience.play(false, FlxG.random.float(0, carSndAmbience.length));
		}

		var redOverlay = getNamedProp('fgRedOverlay');
		if (redOverlay != null)
		{
			FlxTween.tween(redOverlay, {alpha: 0.5}, 2, {ease: FlxEase.sineInOut, type: 4});
		}

		if (!Save.instance.modOptions["lowQuality"])
		{
			var listener = gf;
			if (listener == null) listener = bf;

			carRide1 = FunkinSound.load(Paths.sound('gameplay/stages/serviceEnterance/car'), 1, true, false, false);
			if (carRide1 != null)
			{
				carRide1.volume = 0;
				carRide1.proximity(0, 0, listener, 1000, true);
			}

			carRide2 = FunkinSound.load(Paths.sound('gameplay/stages/serviceEnterance/car'), 1, true, false, false);
			if (carRide2 != null)
			{
				carRide2.volume = 0;
				carRide2.proximity(0, 0, listener, 1000, true);
			}

			var rain = getNamedProp('rain');
			if (rain != null && rain.timeline != null) randomizeStartFrames(rain.timeline.layers[0]);

			var boxes = getNamedProp('fgBoxes');
			if (boxes != null && boxes.timeline != null) randomizeStartFrames(boxes.timeline.getLayer('Слой_2'));

			var vending = getNamedProp('vendingLight');
			if (vending != null) vending.useColorTransform = true;
		}

		_sounds = [rainSndAmbience, carSndAmbience, carRide1, carRide2];
	}

	override function onUpdate(event)
	{
		super.onUpdate(event);

		if (!_ready || PlayState.instance == null) return;

		var elapsed = event.elapsed;
		_timer = _timer + elapsed;

		var cam = PlayState.instance.camGame;
		cam.targetOffset.x = Math.sin(_timer * 0.15) * 25;
		cam.targetOffset.y = Math.sin(_timer * 0.05) * 10;

		if (Save.instance.modOptions["shaders"] && rainShader != null)
		{
			var songLength = 0.0;
			if (FlxG.sound.music != null) songLength = FlxG.sound.music.length;

			var intensity = rainShaderStartIntensity;
			if (Conductor.instance.songPosition > 0 && songLength > 0)
			{
				intensity = FlxMath.remapToRange(Conductor.instance.songPosition, 0, songLength, rainShaderStartIntensity, rainShaderEndIntensity);
			}

			rainShader.intensity = intensity;
			rainShader.updateViewInfo(FlxG.width, FlxG.height, FlxG.camera);
			rainShader.update(elapsed * rainSpeedMult);

			if (rainSndAmbience != null) rainSndAmbience.volume = Math.min(0.1, rainShader.intensity);
		}

		if (!Save.instance.modOptions["lowQuality"])
		{
			if (mist0 != null) mist0.y = 480 + (Math.sin(_timer * 0.35) * 70);
			if (mist1 != null) mist1.y = 460 + (Math.sin(_timer * 0.3) * 80);
			if (mist2 != null) mist2.y = 476 + (Math.sin(_timer * 0.4) * 60);
			if (mist3 != null) mist3.y = 470 + (Math.sin(_timer * 0.3) * 70);
			if (mist4 != null) mist4.y = -120 + (Math.sin(_timer * 0.35) * 50);
			if (mist5 != null) mist5.y = -280 + (Math.sin(_timer * 0.08) * 100);

			var fgMist = getNamedProp('fgMist');
			if (fgMist != null) fgMist.x = -1650 + (Math.sin(_timer * 0.85) * 15);

			_flickerTime = _flickerTime + Math.min(Math.max(elapsed, 0), 0.1);
			if (_flickerTime > 0.05)
			{
				_alphaTarget = FlxG.random.float(0.75, 1.2);
				_flickerTime = _flickerTime - 0.05;
			}

			var vending = getNamedProp('vendingLight');
			if (vending != null && (Std.int(_timer * 1000) % 100) > 50)
			{
				var current = vending.colorTransform.alphaMultiplier;
				vending.colorTransform.alphaMultiplier = current + (_alphaTarget - current) * Math.min(1, elapsed * 60 * 0.9);
			}
		}
	}

	override function onBeatHit(event)
	{
		super.onBeatHit(event);

		if (!_ready) return;

		if (FlxG.random.bool(15) && event.beat != (lastChange + changeInterval) && carInterruptable)
			driveCar(getNamedProp('phillyCars'), carRide1, false);

		if (FlxG.random.bool(15) && event.beat != (lastChange + changeInterval) && car2Interruptable)
			driveCar(getNamedProp('phillyCars2'), carRide2, true);

		if (event.beat == (lastChange + changeInterval))
			lastChange = event.beat;

		if (Save.instance.modOptions["shaders"] && bfRim != null && dadRim != null && PlayState.instance.currentSong.id.toLowerCase() == 'dadbattle-animania')
		{
			if (event.beat == 284)
			{
				rainSpeedMult = 0.4;
				fadeBfRim(0.33, 3, {startDelay: 2, ease: FlxEase.sineInOut});
				fadeDadRim(0.33, 3, {startDelay: 2, ease: FlxEase.sineInOut});
			}
			else if (event.beat == 348)
			{
				fadeBfRim(0, 4, {ease: FlxEase.sineInOut});
				fadeDadRim(0, 4, {ease: FlxEase.sineInOut});
			}
		}
	}

	function pauseCars()
	{
		var cars = getNamedProp('phillyCars');
		if (cars != null) FlxTweenUtil.pauseTweensOf(cars);

		var cars2 = getNamedProp('phillyCars2');
		if (cars2 != null) FlxTweenUtil.pauseTweensOf(cars2);
	}

	function resumeCars()
	{
		var cars = getNamedProp('phillyCars');
		if (cars != null) FlxTweenUtil.resumeTweensOf(cars);

		var cars2 = getNamedProp('phillyCars2');
		if (cars2 != null) FlxTweenUtil.resumeTweensOf(cars2);
	}

	function resetCar(left, right)
	{
		if (Save.instance.modOptions["lowQuality"]) return;

		if (left)
		{
			carInterruptable = true;
			var cars = getNamedProp('phillyCars');
			if (cars != null)
			{
				FlxTween.cancelTweensOf(cars);
				cars.x = -1750;
				cars.y = 450;
				cars.angle = -20;
			}
		}

		if (right)
		{
			car2Interruptable = true;
			var cars2 = getNamedProp('phillyCars2');
			if (cars2 != null)
			{
				FlxTween.cancelTweensOf(cars2);
				cars2.x = -1750;
				cars2.y = 450;
				cars2.angle = -20;
			}
		}
	}

	function finishCar(back)
	{
		if (back) car2Interruptable = true;
		else carInterruptable = true;
	}

	function driveCar(sprite, ride, back)
	{
		if (Save.instance.modOptions["lowQuality"] || sprite == null) return;

		if (back) car2Interruptable = false;
		else carInterruptable = false;

		FlxTween.cancelTweensOf(sprite);

		var variant = FlxG.random.int(1, 4);
		sprite.animation.play('car' + Std.string(variant));

		var offsetX = 0;
		var offsetY = 0;
		var duration = 2.0;

		if (variant == 1)
		{
			offsetX = 0;
			offsetY = 120;
			duration = FlxG.random.float(1, 1.7);
		}
		else if (variant == 2)
		{
			offsetX = 30;
			offsetY = 65;
			duration = FlxG.random.float(1.6, 2.4);
		}
		else if (variant == 3)
		{
			offsetX = 30;
			offsetY = 60;
			duration = FlxG.random.float(1.8, 2.5);
		}
		else if (variant == 4)
		{
			offsetX = 10;
			offsetY = 120;
			duration = FlxG.random.float(0.6, 1.9);
		}

		duration = duration * 1.5;
		sprite.offset.set(offsetX, offsetY);

		var path = [];
		if (back)
		{
			path[0] = FlxPoint.get(950, 360);
			path[1] = FlxPoint.get(-1550, 350);
			path[2] = FlxPoint.get(-1750, 550);
			FlxTween.angle(sprite, -1, -20, duration * 0.75, {startDelay: duration * 0.25});
		}
		else
		{
			path[0] = FlxPoint.get(-1750, 550);
			path[1] = FlxPoint.get(-1550, 330);
			path[2] = FlxPoint.get(950, 360);
			FlxTween.angle(sprite, -20, -1, duration * 0.7);
		}

		FlxTween.quadPath(sprite, path, duration, true, {
			onStart: function(t)
			{
				if (ride != null)
				{
					ride.fadeIn(duration * 0.5, 0, 0.9);
					ride.play();
				}
			},
			onUpdate: function(t)
			{
				if (ride != null) ride.setPosition(sprite.x, sprite.y);
			},
			onComplete: function(t)
			{
				if (ride != null)
				{
					ride.fadeOut(duration * 0.5, 0, function(t2)
					{
						ride.stop();
						finishCar(back);
					});
				}
				else
				{
					finishCar(back);
				}
			}
		});
	}

	override function onPause(event)
	{
		super.onPause(event);

		pauseCars();

		var i = 0;
		while (i < _sounds.length)
		{
			if (_sounds[i] != null) _sounds[i].pause();
			i = i + 1;
		}
	}

	override function onResume(event)
	{
		super.onResume(event);

		resumeCars();

		var i = 0;
		while (i < _sounds.length)
		{
			if (_sounds[i] != null) _sounds[i].resume();
			i = i + 1;
		}
	}

	override function onGameOver(event)
	{
		super.onGameOver(event);

		FlxG.camera.filters = [];
		if (getBoyfriend() != null) getBoyfriend().shader = null;
	}

	function removeRainFilter()
	{
		if (rainShaderFilter == null || PlayState.instance == null) return;

		var cam = PlayState.instance.camGame;
		if (cam == null || cam.filters == null) return;

		var kept = [];
		var i = 0;
		while (i < cam.filters.length)
		{
			if (cam.filters[i] != rainShaderFilter) kept[kept.length] = cam.filters[i];
			i = i + 1;
		}
		cam.filters = kept;
	}

	function cleanupRuntime()
	{
		var cars = getNamedProp('phillyCars');
		if (cars != null) FlxTween.cancelTweensOf(cars);

		var cars2 = getNamedProp('phillyCars2');
		if (cars2 != null) FlxTween.cancelTweensOf(cars2);

		var redOverlay = getNamedProp('fgRedOverlay');
		if (redOverlay != null) FlxTween.cancelTweensOf(redOverlay);

		if (bfRimTween != null)
		{
			bfRimTween.cancel();
			bfRimTween = null;
		}
		if (dadRimTween != null)
		{
			dadRimTween.cancel();
			dadRimTween = null;
		}

		var i = 0;
		while (i < _sounds.length)
		{
			if (_sounds[i] != null) _sounds[i].stop();
			i = i + 1;
		}
		_sounds = [];

		removeRainFilter();

		rainShader = null;
		rainShaderFilter = null;
		bfRim = null;
		dadRim = null;
		rainSndAmbience = null;
		carSndAmbience = null;
		carRide1 = null;
		carRide2 = null;
		_ready = false;
	}

	override function onDestroy(event)
	{
		cleanupRuntime();
		super.onDestroy(event);
	}
}
