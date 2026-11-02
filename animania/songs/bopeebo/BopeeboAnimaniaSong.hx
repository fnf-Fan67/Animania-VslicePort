package animania.songs.bopeebo;

class BopeeboAnimaniaSong extends Song
{
	function new()
	{
		super('bopeebo-animania');
	}

	var bounceMinAmp = 2.0;
	var bounceMaxAmp = 25.0;
	var bounceRampBeats = 32.0;
	var bounceFadeSec = 0.6;
	var bounceOpponent = false;

	var bounceOn = false;
	var bounceStartBeat = 96;

	var hudZoomBackup = 1.0;
	var scrollTween = null;

	var bounceBaseY = [[0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0]];
	var bouncePlaced = false;
	var bounceGain = 0.0;
	var bounceLastOff = 0.0;
	var bouncePostFn = null;

	function bouncePlace(game)
	{
		if (game == null || bouncePlaced) return;

		var l = 0;
		while (l < 2)
		{
			var s = (l == 0) ? game.opponentStrumline : game.playerStrumline;
			if (s != null)
			{
				var c = 0;
				while (c < 4)
				{
					bounceBaseY[l][c] = s.getByIndex(c).y - s.y;
					c += 1;
				}
			}
			l += 1;
		}

		bouncePlaced = true;
	}

	function bounceOffset()
	{
		var beatT = Conductor.instance.currentBeatTime;
		var p = beatT - Math.floor(beatT);

		var k = (beatT - bounceStartBeat) / bounceRampBeats;
		if (k < 0.0) k = 0.0;
		if (k > 1.0) k = 1.0;
		var amp = (bounceMinAmp + (bounceMaxAmp - bounceMinAmp) * k) * bounceGain;

		var w = 0.0;
		if (p < 0.5) w = 1.0 - FlxEase.sineInOut(p * 2.0);
		else w = FlxEase.sineInOut((p - 0.5) * 2.0);

		return -amp * w;
	}

	function bouncePost()
	{
		var game = PlayState.instance;
		if (game == null || !bouncePlaced) return;

		var step = FlxG.elapsed / bounceFadeSec;
		if (bounceOn)
		{
			bounceGain += step;
			if (bounceGain > 1.0) bounceGain = 1.0;
		}
		else
		{
			bounceGain -= step;
			if (bounceGain < 0.0) bounceGain = 0.0;
		}

		var off = bounceOffset();
		if (off == 0 && bounceLastOff == 0) return;
		bounceLastOff = off;

		var l = bounceOpponent ? 0 : 1;
		while (l < 2)
		{
			var s = (l == 0) ? game.opponentStrumline : game.playerStrumline;
			if (s != null)
			{
				var c = 0;
				while (c < 4)
				{
					s.getByIndex(c).y = s.y + bounceBaseY[l][c] + off;
					c += 1;
				}
			}
			l += 1;
		}
	}

	function resetState()
	{
		hudZoomBackup = 1.0;
		scrollTween = null;
		bounceOn = false;
		bounceGain = 0.0;
	}

	function onCreate(event)
	{
		resetState();

		FunkinMemory.cacheTexture(Paths.image('stages/mainStageAmTake/gf_event', 'shared'));
		FunkinMemory.cacheTexture(Paths.image('stages/mainStageAmTake/solotime_cardboard', 'shared'));

		bouncePostFn = function() {
			bouncePost();
		};
		FlxG.signals.postUpdate.add(bouncePostFn);
	}

	function onCountdownStart(event)
	{
		bouncePlace(PlayState.instance);
	}

	function onSongRetry(event)
	{
		resetState();
	}

	function onBeatHit(event)
	{
		var pls = PlayState.instance;
		if (pls == null || pls.currentStage == null) return;

		var beat = event.beat;
		var now = Conductor.instance.songPosition;
		var beatMs = Conductor.instance.beatLengthMs;

		if (beat == 96)
		{
			bounceOn = true;
			bounceStartBeat = beat;
		}
		if (beat == 128) bounceOn = false;

		if (beat == 96)
		{
			moveIn();

			var vin2 = pls.currentStage.getNamedProp('vin2');
			if (vin2 != null)
			{
				FlxTween.tween(vin2, {alpha: 0.6}, 0.25, {
					ease: FlxEase.cubeIn,
					onComplete: function(_)
					{
						FlxTween.tween(vin2, {alpha: 0}, 9, {ease: FlxEase.sineInOut});
					}
				});
			}

			var cam = pls.camHUD;
			var aa = AmScroll.isDown() ? 1.0 : -1.0;
			hudZoomBackup = pls.defaultHUDCameraZoom;

			FlxTween.tween(cam, {angle: -2}, 17, {ease: FlxEase.sineInOut});
			scrollTween = FlxTween.num(cam.scroll.y, -15.0 * aa, 17, {ease: FlxEase.sineInOut}, function(v) {
				cam.scroll.y = v;
			});
			if (AmMlpc.pcHud())
			{
			FlxTween.tween(pls, {defaultHUDCameraZoom: 0.75}, 13, {startDelay: 5, ease: FlxEase.sineInOut});
			}
		}

		if (beat == 128)
		{
			var cam2 = pls.camHUD;
			if (scrollTween != null) scrollTween.cancel();
			FlxTween.tween(cam2, {angle: 0}, 0.6, {ease: FlxEase.cubeOut});
			scrollTween = FlxTween.num(cam2.scroll.y, 0.0, 0.6, {ease: FlxEase.cubeOut}, function(v) {
				cam2.scroll.y = v;
			});

			if (AmMlpc.pcHud())
			{
			FlxTween.cancelTweensOf(pls, ['defaultHUDCameraZoom']);
			pls.defaultHUDCameraZoom = hudZoomBackup;
			}

			moveOut();
		}

		if (beat == 131)
		{
			pls.disableKeys = true;
		}

		if (beat == 132)
		{
			var plyA = pls.playerStrumline;
			FlxTween.num(plyA.alpha, 0.1, 0.15, {ease: FlxEase.sineOut}, function(v) {
				plyA.alpha = v;
			});
		}

		if (beat == 135)
		{
			pls.disableKeys = false;
			pls.playerStrumline.strumlineNotes.members[2].playStatic();

			var plyB = pls.playerStrumline;
			FlxTween.num(plyB.alpha, 1.0, 0.5, {ease: FlxEase.sineInOut}, function(v) {
				plyB.alpha = v;
			});
		}
	}

	function onDestroy(event)
	{
		if (bouncePostFn != null)
		{
			FlxG.signals.postUpdate.remove(bouncePostFn);
			bouncePostFn = null;
		}
		bouncePlaced = false;
		bounceLastOff = 0.0;

		resetState();
	}

	function moveIn()
	{
		var pls = PlayState.instance;
		var opp = pls.opponentStrumline;
		var ply = pls.playerStrumline;
		var offset = AmScroll.isDown() ? -300.0 : 300.0;
		var offsetScore = AmScroll.isPref() ? -300.0 : 300.0;

		var scoreEls = scoreFcElements();
		var els = healthBarElements();
		var e = 0;
		while (e < els.length)
		{
			var el = els[e];
			e += 1;
			var elOff = (scoreEls.indexOf(el) != -1) ? offsetScore : offset;
			FlxTween.tween(el, {y: el.y + elOff, alpha: 0}, 6.26, {ease: FlxEase.sineInOut});
		}
		fadeIcons(pls, 0.0, 6.26, FlxEase.sineInOut);

		if (AmMlpc.playerStrum())
		{
		FlxTween.tween(ply, {x: ply.x - 150}, 16, {ease: FlxEase.sineInOut});
		}

		FlxTween.tween(opp, {y: opp.y + 25, alpha: 0.75}, 14, {ease: FlxEase.sineInOut});
		if (AmMlpc.oppScale())
		{
		FlxTween.num(opp.strumlineScale.x, 0.9, 14, {ease: FlxEase.sineInOut}, function(v) {
			opp.strumlineScale.set(v, v);
		});
		}
		if (AmMlpc.playerStrum())
		{
		FlxTween.num(ply.strumlineScale.x, 1.075, 16, {ease: FlxEase.sineInOut}, function(v) {
			ply.strumlineScale.set(v, v);
		});
		}
	}

	function moveOut()
	{
		var pls = PlayState.instance;
		var opp = pls.opponentStrumline;
		var ply = pls.playerStrumline;
		var offset = AmScroll.isDown() ? -300.0 : 300.0;
		var offsetScore = AmScroll.isPref() ? -300.0 : 300.0;

		var scoreEls = scoreFcElements();
		var els = healthBarElements();
		var e = 0;
		while (e < els.length)
		{
			var el = els[e];
			e += 1;
			var elOff = (scoreEls.indexOf(el) != -1) ? offsetScore : offset;
			FlxTween.tween(el, {y: el.y - elOff, alpha: 1}, 0.26, {ease: FlxEase.sineInOut});
		}
		fadeIcons(pls, 1.0, 0.26, FlxEase.sineInOut);

		if (AmMlpc.playerStrum())
		{
		FlxTween.tween(ply, {x: ply.x + 150}, 1, {ease: FlxEase.cubeOut});
		}

		FlxTween.tween(opp, {y: opp.y - 25, alpha: 1}, 1, {ease: FlxEase.backOut});
		if (AmMlpc.oppScale())
		{
		FlxTween.num(opp.strumlineScale.x, 1.0, 1, {ease: FlxEase.backOut}, function(v) {
			opp.strumlineScale.set(v, v);
		});
		}
		if (AmMlpc.playerStrum())
		{
		FlxTween.num(ply.strumlineScale.x, 1.0, 1, {ease: FlxEase.cubeOut}, function(v) {
			ply.strumlineScale.set(v, v);
		});
		}
	}

	function scoreFcElements()
	{
		var out = [];

		var score = ModuleHandler.getModule('AnimaniaScoreModule');
		if (score != null)
		{
			if (score.scoreLabel != null) out[out.length] = score.scoreLabel;

			var d = 0;
			while (d < score.scoreDigits.length)
			{
				var dig = score.scoreDigits[d];
				d += 1;
				if (dig != null) out[out.length] = dig;
			}
		}

		var fc = ModuleHandler.getModule('FullComboSpr');
		if (fc == null) fc = ModuleHandler.getModule('FullComboModule');
		if (fc != null && fc.fcSprite != null) out[out.length] = fc.fcSprite;

		return out;
	}

	function healthBarElements()
	{
		var out = [];

		var curved = ModuleHandler.getModule('CurvedHealthBarModule');
		if (curved != null)
		{
			if (curved.redBar != null) out[out.length] = curved.redBar;
			if (curved.greenBar != null) out[out.length] = curved.greenBar;
			if (curved.bg != null) out[out.length] = curved.bg;
		}

		var score = ModuleHandler.getModule('AnimaniaScoreModule');
		if (score != null)
		{
			if (score.scoreLabel != null) out[out.length] = score.scoreLabel;

			var d = 0;
			while (d < score.scoreDigits.length)
			{
				var dig = score.scoreDigits[d];
				d += 1;
				if (dig != null) out[out.length] = dig;
			}
		}

		var fc = ModuleHandler.getModule('FullComboSpr');
		if (fc == null) fc = ModuleHandler.getModule('FullComboModule');
		if (fc != null && fc.fcSprite != null) out[out.length] = fc.fcSprite;

		return out;
	}

	function fadeIcons(pls, target, time, easeFn)
	{
		if (pls.iconP1 != null) FlxTween.tween(pls.iconP1, {alpha: target}, time, {ease: easeFn});
		if (pls.iconP2 != null) FlxTween.tween(pls.iconP2, {alpha: target}, time, {ease: easeFn});
	}
}
