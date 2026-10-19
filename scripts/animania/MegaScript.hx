package animania;

class AmScroll
{
	public static function isDown():Bool
	{
		var ps = PlayState.instance;
		if (ps != null && ps.playerStrumline != null) return ps.playerStrumline.isDownscroll == true;
		return Preferences.downscroll;
	}

	public static function isPref():Bool
	{
		return Preferences.downscroll == true;
	}
}

class AmMlpc
{
	static var MOD_ID:String = 'MobileHitbox';

	public static function isLoaded():Bool
	{
		return ModuleHandler.getModule(MOD_ID) != null;
	}

	static function isArrowsLayout():Bool
	{
		var ps = PlayState.instance;
		if (ps == null || ps.playerStrumline == null) return true;
		if (Std.string(Preferences.controlsScheme) != 'Arrows') return false;
		var pb = ps.playerStrumline.background;
		var ob = (ps.opponentStrumline != null) ? ps.opponentStrumline.background : null;
		if (pb == null || ob == null) return ps.playerStrumline.isDownscroll == true;
		return pb.width > ob.width * 1.6;
	}

	static function middlescroll():String
	{
		var ms = Save.instance.modOptions['mobileMiddlescroll'];
		return (ms == null) ? 'Off' : Std.string(ms);
	}

	public static function pcHud():Bool
	{
		var ok = true;
		#if mobile
		ok = isLoaded() && !isArrowsLayout();
		#end
		return ok;
	}

	public static function playerStrum():Bool
	{
		var ok = true;
		#if mobile
		ok = pcHud() && middlescroll() != 'Widened';
		#end
		return ok;
	}

	public static function oppScale():Bool
	{
		var ok = true;
		#if mobile
		var ms = middlescroll();
		ok = pcHud() && (ms == 'Off' || ms == 'On');
		#end
		return ok;
	}
}

class AmTweenPause
{
	static var held:Array<Dynamic> = [];

	public static function pauseAll():Void
	{
		var list = held;
		FlxTween.globalManager.forEach(function(t)
		{
			if (t == null || !t.active || t.finished) return;
			FlxTweenUtil.pauseTween(t);
			list.push(t);
		});
	}

	public static function resumeAll():Void
	{
		var list = held;
		held = [];
		var i = 0;
		while (i < list.length)
		{
			FlxTweenUtil.resumeTween(list[i]);
			i += 1;
		}
	}
}

class AmTweenPauseModule extends Module
{
	function new()
	{
		super('AmTweenPauseModule', {state: PlayState});
	}

	override function onPause(event:PauseScriptEvent):Void
	{
		super.onPause(event);
		if (event.eventCanceled) return;
		AmTweenPause.pauseAll();
	}

	override function onResume(event:ScriptEvent):Void
	{
		super.onResume(event);
		if (event.eventCanceled) return;
		AmTweenPause.resumeAll();
	}
}

class VocalDifficultySuffixModule extends Module
{
	static var DIFFICULTIES:Array<String> = ['normal', 'easy'];

	var lastVocals:Dynamic = null;
	var anyFound:Bool = false;

	function new()
	{
		super('VocalDifficultySuffixModule', {state: PlayState});
	}

	override function onSongLoaded(event)
	{
		super.onSongLoaded(event);
		applyDifficultyVocals();
	}

	override function onDestroy(event)
	{
		lastVocals = null;
		super.onDestroy(event);
	}

	function applyDifficultyVocals():Void
	{
		var ps = PlayState.instance;
		if (ps == null || ps.vocals == null || ps.vocals == lastVocals) return;

		var old = ps.vocals;
		lastVocals = old;

		var chart = ps.currentChart;
		if (chart == null) return;

		var diff:String = (ps.currentDifficulty == null) ? '' : Std.string(ps.currentDifficulty).toLowerCase();
		if (DIFFICULTIES.indexOf(diff) == -1) return;

		anyFound = false;
		var playerPaths = withDifficulty(chart.buildPlayerVoiceList(), diff);
		var opponentPaths = chart.buildOpponentVoiceList();

		var legacyPath:String = null;
		if (playerPaths.length == 0 && opponentPaths.length == 0)
		{
			var variation = ps.currentVariation;
			var suffix:String = (variation != null && variation != '' && variation != 'default') ? '-' + variation : '';
			var candidate = insertDifficulty(Paths.voices(ps.currentSong.id, suffix), diff);
			if (Assets.exists(candidate))
			{
				legacyPath = candidate;
				anyFound = true;
			}
		}

		if (!anyFound) return;

		var group = new VoicesGroup();
		for (p in playerPaths)
			group.addPlayerVoice(FunkinSound.load(p, 1.0, false, false, false, false, null, null, true));
		for (p in opponentPaths)
			group.addOpponentVoice(FunkinSound.load(p, 1.0, false, false, false, false, null, null, true));
		if (legacyPath != null)
			group.addPlayerVoice(FunkinSound.load(legacyPath, 1.0, false, false, false, false, null, null, true));

		if (group.members.length == 1)
		{
			group.legacyVoiceSystem = true;
			group.legacyVoiceUsesPlayer = group.getPlayerVoice(0) != null;
		}

		group.forEach(function(snd) { snd.important = true; });

		group.playerVoicesOffset = old.playerVoicesOffset;
		group.opponentVoicesOffset = old.opponentVoicesOffset;
		group.playerVolume = old.playerVolume;
		group.opponentVolume = old.opponentVolume;

		old.stop();
		ps.vocals = group;
		lastVocals = group;
	}

	function withDifficulty(paths:Array<String>, diff:String):Array<String>
	{
		var result:Array<String> = [];
		for (p in paths)
		{
			var candidate = insertDifficulty(p, diff);
			if (candidate != p && Assets.exists(candidate))
			{
				result.push(candidate);
				anyFound = true;
			}
			else
			{
				result.push(p);
			}
		}
		return result;
	}

	function insertDifficulty(path:String, diff:String):String
	{
		var dot = path.lastIndexOf('.');
		if (dot < 0) return path;
		return path.substr(0, dot) + '-' + diff + path.substr(dot);
	}
}

#if FEATURE_DISCORD_RPC
class DiscordPresenceModule extends Module
{
	static var TITLE_TEXT:String = 'In The AmTake Title';
	static var MENU_TEXT:String = 'In The AmTake Menu';
	static var TITLE_IMAGE:String = 'https://raw.githubusercontent.com/fnf-Fan67/Animania-VslicePort/main/previewImages/discord/animania.png';
	static var SMALL_IMAGE:String = '';
	static var REFRESH_SECONDS:Float = 1.0;
	static var ENGINE_SETTLE_SECONDS:Float = 0.01;

	static var SONGS:Array<Dynamic> = [
		{id: 'cocoa-animania', name: 'Cocoa (AmTake)', image: 'https://raw.githubusercontent.com/fnf-Fan67/Animania-VslicePort/main/previewImages/discord/expansionMini.png'},
		{id: 'bopeebo-animania', name: 'Bopeebo (AmTake)', image: 'https://raw.githubusercontent.com/fnf-Fan67/Animania-VslicePort/main/previewImages/discord/expansionMini.png'},
		{id: 'fresh-animania', name: 'Fresh (AmTake)', image: 'https://raw.githubusercontent.com/fnf-Fan67/Animania-VslicePort/main/previewImages/discord/expansionMini.png'},
		{id: 'dadbattle-animania', name: 'DadBattle (AmTake)', image: 'https://raw.githubusercontent.com/fnf-Fan67/Animania-VslicePort/main/previewImages/discord/expansionMini.png'},
		{id: 'eggnog-animania', name: 'Eggnog (AmTake)', image: 'https://raw.githubusercontent.com/fnf-Fan67/Animania-VslicePort/main/previewImages/discord/animania05.png'},
		{id: 'winter-horrorland-animania', name: 'Winter Horrorland (AmTake)', image: 'https://raw.githubusercontent.com/fnf-Fan67/Animania-VslicePort/main/previewImages/discord/expansionMini.png'},
		{id: 'phone-call', name: 'PhoneCall', image: 'https://raw.githubusercontent.com/fnf-Fan67/Animania-VslicePort/main/previewImages/discord/animania05.png'}
	];

	var paused:Bool = false;
	var loopTimer:FlxTimer = null;

	function new()
	{
		super('DiscordPresenceModule');
	}

	override function onStateChangeEnd(event)
	{
		super.onStateChangeEnd(event);
		paused = false;
		restartLoop();
		applyLater();
	}

	override function onSongStart(event)
	{
		super.onSongStart(event);
		paused = false;
		applyLater();
	}

	override function onPause(event)
	{
		super.onPause(event);
		paused = true;
		applyLater();
	}

	override function onResume(event)
	{
		super.onResume(event);
		paused = false;
		applyLater();
	}

	override function onSongRetry(event)
	{
		super.onSongRetry(event);
		paused = false;
		applyLater();
	}

	override function onGameOver(event)
	{
		super.onGameOver(event);
		applyLater();
	}

	override function onFocusGained(event)
	{
		super.onFocusGained(event);
		applyLater();
	}

	override function onFocusLost(event)
	{
		super.onFocusLost(event);
		applyLater();
	}

	override function onDestroy(event)
	{
		stopLoop();
		paused = false;
		super.onDestroy(event);
	}

	function restartLoop():Void
	{
		stopLoop();
		loopTimer = new FlxTimer().start(REFRESH_SECONDS, function(_) apply(), 0);
	}

	function stopLoop():Void
	{
		if (loopTimer == null) return;
		loopTimer.cancel();
		loopTimer.destroy();
		loopTimer = null;
	}

	function applyLater():Void
	{
		new FlxTimer().start(ENGINE_SETTLE_SECONDS, function(_) apply());
	}

	function findSong(id:String):Dynamic
	{
		if (id == null) return null;
		var lower = id.toLowerCase();
		for (s in SONGS)
		{
			if (s.id == lower) return s;
		}
		return null;
	}

	function titleCase(text:String):String
	{
		var words = text.split('-').join(' ').split(' ');
		var result:Array<String> = [];
		for (w in words)
		{
			if (w == '') continue;
			result.push(w.charAt(0).toUpperCase() + w.substr(1));
		}
		return result.join(' ');
	}

	function setPresence(details:String, state:String, image:String):Void
	{
		DiscordClient.setPresence({
			details: details,
			state: state,
			largeImageKey: (image == null || image == '') ? TITLE_IMAGE : image,
			smallImageKey: SMALL_IMAGE
		});
	}

	function apply():Void
	{
		var current = FlxG.state;
		if (current == null || Std.isOfType(current, InitState)) return;

		if (Std.isOfType(current, PlayState))
		{
			applySong();
			return;
		}

		if (Std.isOfType(current, TitleState))
		{
			setPresence(TITLE_TEXT, '', TITLE_IMAGE);
			return;
		}

		setPresence(MENU_TEXT, '', TITLE_IMAGE);
	}

	function applySong():Void
	{
		var ps = PlayState.instance;
		if (ps == null || ps.currentSong == null) return;

		var entry = findSong(ps.currentSong.id);
		if (entry == null) return;
		if (ps.isChartingMode || ps.currentSong.isDiscordRPCAnonymous()) return;

		var difficulty:String = (ps.currentDifficulty == null) ? '???' : titleCase(Std.string(ps.currentDifficulty));

		var mode:String = 'Freeplay';
		if (PlayStatePlaylist.isStoryMode) mode = 'Story Mode';
		else if (ps.isPracticeMode) mode = 'Practice';
		else if (ps.isBotPlayMode) mode = 'Bot Play';

		var prefix:String = '';
		if (ps.isPlayerDying || ps.isGameOverState) prefix = 'Game Over - ';
		else if (paused) prefix = 'Paused - ';

		setPresence('Playing: ' + entry.name, prefix + mode + ' [' + difficulty + ']', entry.image);
	}
}
#end

class KeyboardModule extends Module
{
	function new()
	{
		super('KeyboardModule');
	}

	function events():Void
	{
		var key:FlxG = FlxG.keys.justPressed;

		if (key.TWO)
		{
			PlayState.instance.isBotPlayMode = !PlayState.instance.isBotPlayMode;
		}
	}

	override function onCountdownStart(event:CountdownScriptEvent):Void
	{
		super.onCountdownStart(event);

	}

	override function onUpdate(event:UpdateScriptEvent):Void
	{
		super.onUpdate(event);

		events();
	}
}

class QualityOptions extends Module
{
    var save:Save;
    var optionsState:OptionsState;
    var preferences:Dynamic;

    function new()
    {
        super('QualityOptions', {state: OptionsState});
    }

    override function onCreate():Void
    {
        super.onCreate();

        save = Save.instance;

        if (save.modOptions['shaders'] == null)
        {
            save.modOptions['shaders'] = true;
            save.flush();
        }

        if (save.modOptions['lowQuality'] == null)
        {
            save.modOptions['lowQuality'] = false;
            save.flush();
        }
    }

    function getShaders():Bool
    {
        if (save == null) save = Save.instance;
        var v = save.modOptions['shaders'];
        return (v == null) ? true : (v == true);
    }

    function getLowQuality():Bool
    {
        if (save == null) save = Save.instance;
        var v = save.modOptions['lowQuality'];
        return (v == null) ? false : (v == true);
    }

    function buildOptions():Void
    {
        optionsState = OptionsState.instance;
        save = Save.instance;
        preferences = optionsState.optionsCodex.pages.get('preferences');

        preferences.createPrefItemCheckbox(
            'animania shaders',
            'If on, custom shaders are used. Turn off to improve performance',
            function(value:Bool):Void
            {
                save.modOptions['shaders'] = value;
                save.flush();
            },
            getShaders()
        );

        preferences.createPrefItemCheckbox(
            'low quality animania',
            'If on, heavy effects are disabled to improve performance',
            function(value:Bool):Void
            {
                save.modOptions['lowQuality'] = value;
                save.flush();
            },
            getLowQuality()
        );
    }

    override function onStateChangeEnd(event:StateChangeScriptEvent):Void
    {
        var targetState = event.targetState;
        super.onStateChangeEnd(event);

        if (Std.isOfType(targetState, OptionsState))
        {
            buildOptions();
        }
    }
}

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

class FreshAnimania extends Song
{
	var blackAss:FunkinSprite = null;
	var ver:FunkinSprite = null;
	var solo_time_d:FunkinSprite = null;
	var hasPlayedCutscene:Bool = false;
    function new()
    {
        super('fresh-animania');

        hasPlayedCutscene = false;
    }

    function onCreate(event:ScriptEvent):Void
	{
        super.onCreate(event);

		hasPlayedCutscene = false;
        onLoadSong(PlayState.lastParams);
	}

    function onLoadSong(params)
    {
        if (params.targetSong.id != "fresh-animania")
            return;

        var currentStage:Dynamic = PlayState.instance.currentStage;

		blackAss = new FunkinSprite();
        blackAss.makeGraphic(1, 1, FlxColor.WHITE);
        blackAss.color = FlxColor.BLACK;
        blackAss.scale.set(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3));
        blackAss.updateHitbox();
        blackAss.screenCenter();
        blackAss.zIndex = 9000;
        blackAss.alpha = 0;
        currentStage.add(blackAss);

		ver = new FunkinSprite();
        ver.loadGraphic(Paths.image('stages/mainStageAmTake/gf_event', 'shared'));
        ver.zIndex = currentStage.getGirlfriend().zIndex - 1;
        ver.x = 520;
        ver.y = -580;
        ver.visible = false;
        ver.y -= 800;
        currentStage.add(ver);

		solo_time_d = new FunkinSprite(0, 0, Paths.animateAtlas('stages/mainStageAmTake/solotime_cardboard', 'shared'));
        solo_time_d.zIndex = 8;
        solo_time_d.applyStageMatrix = true;

        addAtlasAnim(solo_time_d, "off", "off loop", 24, true);
        addAtlasAnim(solo_time_d, "turn", "turned on", 24, false);
        addAtlasAnim(solo_time_d, "on", "on loop", 24, true);
        solo_time_d.animation.onFinish.add((animName) -> if (animName == "turn") playSoloSign('on'));
        playSoloSign('off');
        currentStage.add(solo_time_d);

        solo_time_d.x += 325;
		solo_time_d.y -= 350;

		solo_time_d.y -= 800;

        currentStage.refresh();

        var gf = currentStage.getGirlfriend();
        gf.anim.onFrameChange.add((name, symb, idx) -> if (name == "fresh solo") {
            trace(symb, idx);
            switch (symb)
            {
		
                case 1:
                    ver.visible = true;
                    FlxTween.tween(ver, {y: ver.y + 800}, 6, {startDelay: 6, ease: FlxEase.cubeOut});

                case 333:
			    	ver.zIndex = currentStage.getGirlfriend().zIndex + 1;
			    	currentStage.refresh();

                case 369:
			    	ver.zIndex = currentStage.getGirlfriend().zIndex - 1;
			    	currentStage.refresh();

                case 371:
                    ver.y += 2;
                case 377:
                    ver.y += 2;
                case 379:
                    ver.y += 5;

                case 381:
                    ver.y -= 5;
                case 383:
    				ver.y -= 4;

                case 387:
    				ver.zIndex = 12;
    				currentStage.refresh();

                case 389:
    				FlxTween.tween(ver, {y: ver.y - 800}, 4, {ease: FlxEase.cubeIn});
            }
        });
    }

    /**
     * Registra una animacion del atlas buscando el id primero como frame label y despues como symbol.
     * (addBySymbol a secas no registra nada si el nombre es un frame label, y entonces play() no hace nada.)
     */
    function addAtlasAnim(spr:FunkinSprite, animName:String, id:String, fps:Int, loop:Bool):Bool
    {
        var norm = (s) -> s.toLowerCase().split(" ").join("").split("_").join("");
        var labels:Array<String> = spr.getFrameLabelList();

        var found:String = null;
        for (l in labels) if (l == id) { found = l; break; }
        if (found == null) for (l in labels) if (norm(l) == norm(id)) { found = l; break; }

        if (found != null)
        {
            spr.anim.addByFrameLabel(animName, found, fps, loop);
            return true;
        }

        try
        {
            spr.anim.addBySymbol(animName, id, fps, loop);
        }
        catch (e:Dynamic) {}

        if (spr.animation.getNameList().contains(animName)) return true;

        var symbols:Array<String> = [];
        try { for (k in spr.library.dictionary.keys()) symbols.push(k); } catch (e:Dynamic) {}
        trace('[FreshAnimania] No se encontro "' + id + '" en el atlas. Labels: ' + labels + ' | Symbols: ' + symbols);
        return false;
    }

    function playSoloSign(name:String):Void
    {
        if (solo_time_d == null) return;
        if (!solo_time_d.animation.getNameList().contains(name)) return;
        solo_time_d.animation.play(name, true);
    }

    override function onBeatHit(event:SongTimeScriptEvent):Void
    {
        super.onBeatHit(event);

        var beat = event.beat;
        var currentStage:Dynamic = PlayState.instance.currentStage;

        switch (beat)
        {
            case 1:
                trace('primer beat');
            case 108:
                var dad = currentStage.getDad();
                dad.zIndex = 9999;
                currentStage.refresh();
                blackAss.alpha = 1;
                FlxTween.tween(dad, {alpha: 0}, 0.8, {startDelay: 1.2, ease: FlxEase.cubeOut});
            case 112:
                FlxTween.cancelTweensOf(currentStage.getDad());
                currentStage.getDad().alpha = 1;
                var vin2 = currentStage.getNamedProp('vin2');
                vin2.alpha = 1;

                var dad = currentStage.getDad();
                dad.zIndex = 20;
                currentStage.refresh();
                blackAss.alpha = 1;
                FlxTween.tween(blackAss, {alpha: 0}, 7, {ease: FlxEase.smootherStepInOut});
                FlxTween.tween(vin2, {alpha: 0.8}, 12, {ease: FlxEase.smootherStepInOut});
            case 116:
                trace('comenzando evento');
                moveIn();
            case 128:
                FlxTween.tween(solo_time_d, {y: solo_time_d.y + 800}, 4, {ease: FlxEase.sineOut});
				trace('inicio');
            case 143:
                playSoloSign('turn');
                FlxTween.tween(solo_time_d, {y: solo_time_d.y - 800}, 7, {startDelay: 12, ease: FlxEase.sineIn});
				trace('prende');
            case 144:
                var vin2 = currentStage.getNamedProp('vin2');
                vin2.alpha = 0;

                blackAss.color = FlxColor.WHITE;
                blackAss.blend = BlendMode.ADD;
                blackAss.alpha = 1;
                FlxTween.tween(blackAss, {alpha: 0}, 1.2, {ease: FlxEase.sineOut});
            case 174:
                trace('quitando evento');
                moveOut();
        }
    }

    var sfxSounds:FunkinSound = null;

	function onCountdownStart(event)
	{
		sfxSounds = FunkinSound.load(Paths.inst("fresh-animania", "-sfx"));
		super.onCountdownStart(event);
	}

    function onSongStart(event:Dynamic)
	{
		super.onSongStart(event);
		PlayState.instance.vocals.add(sfxSounds);
		sfxSounds.play(true);
	}


    function moveIn()
    {
        var opponentStrumline:Dynamic = PlayState.instance.opponentStrumline;
        var playerStrumline:Dynamic = PlayState.instance.playerStrumline;
		var ogHealthbar:Dynamic = PlayState.instance.healthBar;
        var health:Dynamic = ModuleHandler.getModule('CurvedHealthBarModule').redBar;
		var health2:Dynamic = ModuleHandler.getModule('CurvedHealthBarModule').greenBar;
        var healthBG:Dynamic = ModuleHandler.getModule('CurvedHealthBarModule').bg;
		var score:Dynamic = ModuleHandler.getModule('AnimaniaScoreModule').scoreLabel;
		var scoreDigits:Dynamic = ModuleHandler.getModule('AnimaniaScoreModule').scoreDigits;
		var fcSprite:Dynamic = ModuleHandler.getModule('FullComboModule').fcSprite;
        var iconP1:Dynamic = PlayState.instance.iconP1;
        var iconP2:Dynamic = PlayState.instance.iconP2;

        var offset = (AmScroll.isDown() ? -200 : 200);
        var offsetScore = (AmScroll.isPref() ? -200 : 200);

        FlxTween.tween(health, {y: health.y + offset}, 10, {ease: FlxEase.sineInOut});
		FlxTween.tween(ogHealthbar, {y: ogHealthbar.y + offset}, 10, {ease: FlxEase.sineInOut});
		FlxTween.tween(health2, {y: health2.y + offset}, 10, {ease: FlxEase.sineInOut});
        FlxTween.tween(healthBG, {y: healthBG.y + offset}, 10, {ease: FlxEase.sineInOut});
		FlxTween.tween(score, {y: score.y + offsetScore}, 10, {ease: FlxEase.sineInOut});
		FlxTween.tween(fcSprite, {y: fcSprite.y + offsetScore}, 10, {ease: FlxEase.sineInOut});
		for (i in 0...scoreDigits.length)
		{
			FlxTween.tween(scoreDigits[i], {y: scoreDigits[i].y + offsetScore}, 10, {ease: FlxEase.sineOut});
		}

        FlxTween.tween(iconP1, {y: iconP1.y + offset}, 10, {ease: FlxEase.sineInOut});
        FlxTween.tween(iconP2, {y: iconP2.y + offset}, 10, {ease: FlxEase.sineInOut});


        FlxTween.tween(opponentStrumline, {x: opponentStrumline.x - 100, alpha: 0.75}, 12.25, {ease: FlxEase.sineOut});
		if (AmMlpc.playerStrum())
		{
        FlxTween.tween(playerStrumline, {x: playerStrumline.x - FlxG.width/4 + 20}, 14.55, {ease: FlxEase.sineInOut});
		}

		if (AmMlpc.oppScale())
		{
        FlxTween.num(opponentStrumline.strumlineScale.x, .65, 12.25, {ease: FlxEase.sineOut}, v -> opponentStrumline.strumlineScale.x = v);
        FlxTween.num(opponentStrumline.strumlineScale.y, .65, 12.25, {ease: FlxEase.sineOut}, v -> opponentStrumline.strumlineScale.y = v);
		}
		if (AmMlpc.playerStrum())
		{
        FlxTween.num(playerStrumline.strumlineScale.x, 1.1, 14.55, {ease: FlxEase.sineInOut}, v -> playerStrumline.strumlineScale.x = v);
		FlxTween.num(playerStrumline.strumlineScale.y, 1.1, 14.55, {ease: FlxEase.sineInOut}, v -> playerStrumline.strumlineScale.y = v);
		}
	}

    function moveOut()
    {
        var opponentStrumline:Dynamic = PlayState.instance.opponentStrumline;
        var playerStrumline:Dynamic = PlayState.instance.playerStrumline;
		var ogHealthbar:Dynamic = PlayState.instance.healthBar;
        var health:Dynamic = ModuleHandler.getModule('CurvedHealthBarModule').redBar;
		var health2:Dynamic = ModuleHandler.getModule('CurvedHealthBarModule').greenBar;
        var healthBG:Dynamic = ModuleHandler.getModule('CurvedHealthBarModule').bg;
		var score:Dynamic = ModuleHandler.getModule('AnimaniaScoreModule').scoreLabel;
		var scoreDigits:Dynamic = ModuleHandler.getModule('AnimaniaScoreModule').scoreDigits;
		var fcSprite:Dynamic = ModuleHandler.getModule('FullComboModule').fcSprite;
        var iconP1:Dynamic = PlayState.instance.iconP1;
        var iconP2:Dynamic = PlayState.instance.iconP2;

        var offset = (AmScroll.isDown() ? -200 : 200 );
        var offsetScore = (AmScroll.isPref() ? -200 : 200);

        FlxTween.tween(health, {y: health.y - offset}, 1.5, {ease: FlxEase.sineOut});
		FlxTween.tween(ogHealthbar, {y: ogHealthbar.y - offset}, 1.5, {ease: FlxEase.sineOut});
		FlxTween.tween(health2, {y: health2.y - offset}, 1.5, {ease: FlxEase.sineOut});
        FlxTween.tween(healthBG, {y: healthBG.y - offset}, 1.5, {ease: FlxEase.sineOut});
		FlxTween.tween(score, {y: score.y - offsetScore}, 1.5, {ease: FlxEase.sineOut});
        FlxTween.tween(fcSprite, {y: fcSprite.y - offsetScore}, 1.5, {ease: FlxEase.sineOut});
		for (i in 0...scoreDigits.length)
		{
			FlxTween.tween(scoreDigits[i], {y: scoreDigits[i].y - offsetScore}, 1.5, {ease: FlxEase.sineOut});
		}

        FlxTween.tween(iconP1, {y: iconP1.y - offset}, 1.5, {ease: FlxEase.sineOut});
        FlxTween.tween(iconP2, {y: iconP2.y - offset}, 1.5, {ease: FlxEase.sineOut});

        FlxTween.tween(opponentStrumline, {x: opponentStrumline.x + 100, alpha: 1}, 2.65, {ease: FlxEase.backOut});
		if (AmMlpc.playerStrum())
		{
        FlxTween.tween(playerStrumline, {x: playerStrumline.x + FlxG.width/4 - 20}, 2.45, {ease: FlxEase.cubeOut});
		}

		if (AmMlpc.oppScale())
		{
        FlxTween.num(opponentStrumline.strumlineScale.x, 1, 2.65, {ease: FlxEase.backOut}, v -> opponentStrumline.strumlineScale.x = v);
		FlxTween.num(opponentStrumline.strumlineScale.y, 1, 2.65, {ease: FlxEase.backOut}, v -> opponentStrumline.strumlineScale.y = v);
		}
		if (AmMlpc.playerStrum())
		{
        FlxTween.num(playerStrumline.strumlineScale.x, 1, 2.45, {ease: FlxEase.cubeOut}, v -> playerStrumline.strumlineScale.x = v);
		FlxTween.num(playerStrumline.strumlineScale.y, 1, 2.45, {ease: FlxEase.cubeOut}, v -> playerStrumline.strumlineScale.y = v);
		}
    }

    public override function onSongEnd(event:CountdownScriptEvent):Void
	{
		super.onSongEnd(event); 
		if (!PlayStatePlaylist.isStoryMode)
			hasPlayedCutscene = true;

		if (!hasPlayedCutscene)
		{
			PlayState.instance.isInCutscene = true;
			PlayState.instance.mayPauseGame = false;
			hasPlayedCutscene = true;

			event.cancel();

			startCutscene();
		}
		else
		{
			hasPlayedCutscene = false;
			PlayState.instance.isInCutscene = false;
			PlayState.instance.mayPauseGame = true;
		}
	}

    function startCutscene()
	{
		PlayState.instance.isInCutscene = true;
		PlayState.instance.mayPauseGame = false;
		hasPlayedCutscene = true;

		FlxTween.tween(PlayState.instance.camHUD, {alpha: 0}, 1, {ease: FlxEase.backOut});
		PlayState.instance.tweenCameraZoom(0.9, 1.9, true, FlxEase.quadInOut);
		PlayState.instance.tweenCameraToPosition(PlayState.instance.cameraFollowPoint.x + 100, PlayState.instance.cameraFollowPoint.y + 50, 1.9, FlxEase.quadInOut);
		var blackScreen = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		blackScreen.scrollFactor.set();
		blackScreen.cameras = [PlayState.instance.camCutscene];
		PlayState.instance.add(blackScreen);
		blackScreen.alpha = 0;
		FlxTween.tween(blackScreen, {alpha: 1}, 1.75, {ease: FlxEase.quadInOut});

		FlxTimer.wait(2, startVideo);
	}

    function startVideo()
	{
		VideoCutscene.play(Paths.videos('FRESH_CUTSCENE.mkv'), CutsceneType.ENDING);
		VideoCutscene.vid.alpha = 0;
		FlxTween.tween(VideoCutscene.vid, {alpha: 1}, .35, {ease: FlxEase.cubeOut});
	}
}

class DadBattleAnimania extends Song
{
	function new()
	{
		super('dadbattle-animania');
	}

	var useDangerBar:Bool = true;
	var useGodRays:Bool = true;

	var videoBeat = 223;

	var bfRef = null;
	var dadRef = null;
	var reflectionShaderDad = null;
	var reflectionShaderBf = null;
	var reflectionTime = 0;

	var chromShader = null;
	var chromChangeTween = null;

	var shaderTime = 0.0;

	var vid = null;
	var videoStarted = false;
	var hiddenHud = [];

	var videoToken = 0;
	var videoPrecached = false;
	var videoReady = false;
	var videoPending = false;
	var videoPlaying = false;
	var videoFinished = false;
	var videoWait = 0.0;
	var videoPlayTime = 0.0;
	var videoStallTime = 0.0;
	var videoMaxWait = 3.0;
	var videoStallMax = 2.0;
	var videoEndBeat = 250;

	var overlayBaseAlpha = null;
	var dadIdleBase = "";

	var dangerBar = null;
	var dangerShader = null;
	var dangerBarTried = false;
	var dangerSource = null;
	var dangerPulse = -300.0;

	var godRaysSpr = null;
	var godRaysShader = null;

	var godRaysZoomFactor = 0.0;
	var godRaysScrollX = 1.0;
	var godRaysScrollY = 0.0;
	var godRaysBaseX = 0.0;
	var godRaysBaseY = 0.0;
	var godRaysBaseScaleX = 1.0;
	var godRaysBaseScaleY = 1.0;
	var godRaysBaseW = 1.0;
	var godRaysBaseH = 1.0;


	var useModchart = !Save.instance.modOptions["lowQuality"];
	var dadYYPos = -100;
	var oppFieldScale = 1.15;
	var hideOpponentCovers = true;
	var oppAnchorDX = 0.0;
	var oppAnchorDY = 0.0;

	var mlOpp = null;
	var mlPlr = null;
	var mlTw = new StringMap();
	var mlPlaced = false;
	var mlStage = 0;
	var mlTriggers = [];
	var mlInIdle = true;
	var mlOppRecs = [];
	var mlPlrRecs = [];
	var mlPlrRecScale = 1.0;
	var mlPlrNoteScale = 1.0;
	var mlOppIncomingFn = null;
	var mlPlrIncomingFn = null;
	var mlPostFn = null;

	function mlLane()
	{
		return {ox: 0.0, oy: 0.0, bobAmp: 0.0, alpha: 1.0, pulse: 1.0, ax: 0.0, ay: 0.0, pa: 1.0,
			b0: 0.0, b1: 0.0, b2: 0.0, b3: 0.0, offs: [0.0, 0.0, 0.0, 0.0], ry: [0.0, 0.0, 0.0, 0.0], waveOn: false};
	}

	function mlTo(name, L, field, target, secs, ease, delay)
	{
		var key = name + ":" + field;
		var old = mlTw.get(key);
		if (old != null) old.cancel();

		var tw = FlxTween.num(Reflect.field(L, field), target, secs, {ease: ease, startDelay: delay}, function(v) {
			Reflect.setField(L, field, v);
		});
		mlTw.set(key, tw);
	}

	function mlBob(name, L, half)
	{
		var c = 0;
		while (c < 4)
		{
			var f = "b" + c;
			var key = name + ":" + f;
			var old = mlTw.get(key);
			if (old != null) old.cancel();

			Reflect.setField(L, f, -1.0);
			var vals = {};
			Reflect.setField(vals, f, 1.0);
			mlTw.set(key, FlxTween.tween(L, vals, half, {type: 4, ease: FlxEase.sineInOut, startDelay: c * 0.573 * half}));
			c += 1;
		}
	}

	function mlUndoLane(s, L, recs)
	{
		if (s == null || L == null) return;
		if (L.ax != 0) s.x -= L.ax;
		if (L.ay != 0) s.y -= L.ay;
		L.ax = 0.0;
		L.ay = 0.0;
		L.pa = 1.0;

		var c = 0;
		while (c < 4)
		{
			if (L.ry[c] != 0 && c < recs.length && recs[c] != null) recs[c].y -= L.ry[c];
			L.ry[c] = 0.0;
			c += 1;
		}
		L.waveOn = false;
	}

	function mlUndo(game)
	{
		if (!mlPlaced || game == null || mlOpp == null) return;

		mlUndoLane(game.opponentStrumline, mlOpp, mlOppRecs);
		mlUndoLane(game.playerStrumline, mlPlr, mlPlrRecs);

		var c = 0;
		while (c < mlPlrRecs.length)
		{
			var r = mlPlrRecs[c];
			if (r != null) r.scale.set(mlPlrRecScale, mlPlrRecScale);
			c += 1;
		}
	}

	function mlHidePre(game)
	{
		if (game == null || mlPlaced) return;

		if (game.playerStrumline != null && game.playerStrumline.alpha != 0) game.playerStrumline.alpha = 0;
		if (game.opponentStrumline != null && game.opponentStrumline.alpha != 0) game.opponentStrumline.alpha = 0;
	}

	function mlInit(game)
	{
		mlUndo(game);

		for (k in mlTw.keys())
		{
			var t = mlTw.get(k);
			if (t != null) t.cancel();
		}
		mlTw = new StringMap();

		useModchart = !Save.instance.modOptions["lowQuality"];

		mlOpp = mlLane();
		mlPlr = mlLane();
		mlStage = 0;
		mlInIdle = true;
		mlPlrNoteScale = 1.0;
		mlTriggers = [31, 37, videoBeat, 284, 384];

		mlOpp.alpha = 0.0;
		if (useModchart)
		{
			mlOpp.ox = -200;
			mlOpp.oy = dadYYPos - 50;
			mlOpp.bobAmp = 7.5;
			mlBob("opp", mlOpp, 1.309);
		}

		mlPlr.alpha = 0.0;
		mlPlr.ox = 50;
		mlPlr.oy = 50;

		mlHidePre(game);

		if (mlPostFn == null)
		{
			mlPostFn = function() {
				mlPost();
			};
			FlxG.signals.postUpdate.add(mlPostFn);
		}
	}

	function mlPlace(game)
	{
		if (game == null || game.currentStage == null || mlOpp == null) return;

		var stage = game.currentStage;
		var s = game.opponentStrumline;
		var dad = stage.getDad();
		if (s == null || dad == null) return;

		var c = 0;
		mlPlrRecs = [];
		mlOppRecs = [];
		while (c < 4)
		{
			mlPlrRecs[c] = game.playerStrumline.getByIndex(c);
			mlOppRecs[c] = s.getByIndex(c);
			c += 1;
		}

		if (!mlPlaced)
		{
			mlPlrRecScale = mlPlrRecs[0].scale.x;

			s.isDownscroll = true;
			s.strumlineScale.set(oppFieldScale, oppFieldScale);

			game.remove(s, true);
			stage.add(s);
			s.cameras = [game.camGame];

			var m = 0;
			while (m < s.members.length)
			{
				var mem = s.members[m];
				if (mem != null && Std.isOfType(mem, FunkinSprite)) mem.visible = false;
				m += 1;
			}

			s.showNotesplash = !hideOpponentCovers;

			mlOppIncomingFn = function(n) {
				mlOnIncoming(n, 0);
			};
			mlPlrIncomingFn = function(n) {
				mlOnIncoming(n, 1);
			};
			s.onNoteIncoming.add(mlOppIncomingFn);
			game.playerStrumline.onNoteIncoming.add(mlPlrIncomingFn);
		}

		s.visible = useModchart;

		s.zIndex = dad.zIndex - 2;
		s.x = dad.x + dad.width * 0.6 - s.width * 0.5 + oppAnchorDX;
		s.y = dad.y + dad.height * 0.3 + oppAnchorDY;
		mlOpp.ax = 0.0;
		mlOpp.ay = 0.0;
		stage.refresh();

		mlPlaced = true;

		mlApply(s, mlOpp, mlOppRecs);
		mlApply(game.playerStrumline, mlPlr, mlPlrRecs);
	}

	function mlOnIncoming(n, lane)
	{
		if (n == null) return;

		var L = (lane == 0) ? mlOpp : mlPlr;
		if (L == null) return;

		n.alpha = L.alpha;
		var h = n.holdNoteSprite;
		if (h != null) h.alpha = L.alpha;

		n.yOffset = L.offs[n.direction % 4];
		if (h != null) h.yOffset = L.offs[n.direction % 4];

		if (lane == 1 && mlPlrNoteScale != 1.0) n.scale.set(n.scale.x * mlPlrNoteScale, n.scale.y * mlPlrNoteScale);
	}

	function mlApply(s, L, recs)
	{
		if (s == null) return;

		if (s.alpha != L.alpha) s.alpha = L.alpha;
		if (L.alpha <= 0.0) return;

		if (L.ox != L.ax)
		{
			s.x += L.ox - L.ax;
			L.ax = L.ox;
		}
		if (L.oy != L.ay)
		{
			s.y += L.oy - L.ay;
			L.ay = L.oy;
		}

		var amp = L.bobAmp;
		if (amp == 0 && !L.waveOn) return;

		var offs = L.offs;
		offs[0] = amp * L.b0;
		offs[1] = amp * L.b1;
		offs[2] = amp * L.b2;
		offs[3] = amp * L.b3;
		L.waveOn = (amp != 0);

		var ry = L.ry;
		var c = 0;
		while (c < 4)
		{
			var d = offs[c] - ry[c];
			if (d != 0)
			{
				recs[c].y += d;
				ry[c] = offs[c];
			}
			c += 1;
		}

		var nm = s.notes.members;
		var nl = nm.length;
		var i = 0;
		while (i < nl)
		{
			var n = nm[i];
			i += 1;
			if (n != null && n.alive) n.yOffset = offs[n.direction % 4];
		}

		var hm = s.holdNotes.members;
		var hl = hm.length;
		i = 0;
		while (i < hl)
		{
			var h = hm[i];
			i += 1;
			if (h != null && h.alive) h.yOffset = offs[h.noteDirection % 4];
		}
	}

	function mlPost()
	{
		if (!mlPlaced) return;

		var game = PlayState.instance;
		if (game == null) return;

		mlPostLane(game.opponentStrumline, mlOpp);
		mlPostLane(game.playerStrumline, mlPlr);
	}

	function mlPostLane(s, L)
	{
		if (s == null || L == null || !L.waveOn || L.alpha <= 0.0) return;

		var songPos = Conductor.instance.songPosition;
		var hm = s.holdNotes.members;
		var hl = hm.length;
		var i = 0;
		while (i < hl)
		{
			var h = hm[i];
			i += 1;
			if (h == null || !h.alive) continue;

			if (h.hitNote && !h.missedNote && songPos > h.strumTime && h.sustainLength > 0) h.y += L.offs[h.noteDirection % 4];
		}
	}

	function mlApplyPulse()
	{
		var L = mlPlr;
		if (L.pulse == L.pa) return;

		L.pa = L.pulse;
		var sc = mlPlrRecScale * L.pulse;
		var c = 0;
		while (c < mlPlrRecs.length)
		{
			mlPlrRecs[c].scale.set(sc, sc);
			c += 1;
		}
	}

	function mlUpdate(game, elapsed)
	{
		if (!mlPlaced)
		{
			mlHidePre(game);
			return;
		}
		if (game.currentStage == null) return;

		if (useModchart)
		{
			mlOpponentIdle(game);
			mlDrainHolds(game, elapsed);
		}

		mlApply(game.opponentStrumline, mlOpp, mlOppRecs);
		mlApply(game.playerStrumline, mlPlr, mlPlrRecs);
		mlApplyPulse();
	}

	function mlBeat(beat)
	{
		if (!mlPlaced) return;

		var bl = Conductor.instance.beatLengthMs / 1000;

		while (mlStage < mlTriggers.length && beat >= mlTriggers[mlStage])
		{
			mlFire(mlStage, bl);
			mlStage += 1;
		}

		if (beat > 283 && beat % 2 == 0)
		{
			mlPlr.pulse = 1.1;
			mlTo("plr", mlPlr, "pulse", 0.95, bl, FlxEase.sineOut, 0);
		}
	}

	function mlFire(stage, bl)
	{
		if (stage == 0)
		{
			if (useModchart)
			{
				mlTo("opp", mlOpp, "alpha", 0.5, 0.5 * bl, FlxEase.quadOut, 0);
				mlTo("opp", mlOpp, "oy", dadYYPos, 0.5 * bl, FlxEase.circOut, 0);
			}
		}
		else if (stage == 1)
		{
			mlTo("plr", mlPlr, "alpha", 1, 1.6 * bl, FlxEase.quadOut, 0);
			mlTo("plr", mlPlr, "oy", 0, 1.6 * bl, FlxEase.circOut, 0);
			mlTo("plr", mlPlr, "ox", 0, 2 * bl, FlxEase.circOut, 0);
		}
		else if (stage == 2)
		{
			mlTo("plr", mlPlr, "alpha", 0, bl, FlxEase.circOut, 0);
		}
		else if (stage == 3)
		{
			mlTo("plr", mlPlr, "alpha", 1, 1.75 * bl, FlxEase.sineInOut, 0);
			mlPlrNoteScale = 0.95;
		}
		else if (stage == 4)
		{
			var whereWeGo = AmScroll.isDown() ? 30 : -30;
			mlTo("plr", mlPlr, "alpha", 0, bl, FlxEase.sineIn, 0);
			mlTo("plr", mlPlr, "oy", whereWeGo, bl, FlxEase.sineIn, 0);
		}
	}

	function mlVideoEnd()
	{
		if (mlPlr == null) return;

		mlBob("plr", mlPlr, 0.873);
		mlTo("plr", mlPlr, "bobAmp", 10.4, 6.5, FlxEase.circOut, 0.5);
	}

	function mlHit(dir)
	{
		var xx = -200;
		var yy = dadYYPos;

		if (dir == 0) xx -= 25;
		else if (dir == 1) yy += 20;
		else if (dir == 2) yy -= 45;
		else if (dir == 3) xx += 35;

		mlInIdle = false;
		mlTo("opp", mlOpp, "ox", xx, 0.1, FlxEase.circOut, 0);
		mlTo("opp", mlOpp, "oy", yy, 0.1, FlxEase.circOut, 0);
	}

	function mlOpponentIdle(game)
	{
		if (mlInIdle) return;

		var dad = game.currentStage.getDad();
		if (dad == null || dad.animation.curAnim == null) return;

		if (dad.animation.curAnim.name.indexOf("idle") != -1)
		{
			mlInIdle = true;
			mlTo("opp", mlOpp, "ox", -200, 0.25, FlxEase.circOut, 0);
			mlTo("opp", mlOpp, "oy", dadYYPos + (dad.idleSuffix == "" ? 0 : -50), 0.25, FlxEase.circOut, 0);
		}
	}

	function mlDrainHolds(game, elapsed)
	{
		var hm = game.opponentStrumline.holdNotes.members;
		var n = hm.length;
		var i = 0;
		while (i < n)
		{
			var h = hm[i];
			i += 1;
			if (h == null || !h.alive) continue;

			if (h.hitNote && !h.missedNote && h.sustainLength > 0) mlDrainHealth(game, 0.075 * elapsed);
		}
	}

	function mlDrainHealth(game, amount)
	{
		if (game.health <= .1) return;

		var bf = game.currentStage.getBoyfriend();
		var mult = (bf != null && bf.idleSuffix != "") ? Math.max(1, game.health * .85) : 1;
		game.health -= amount * mult;
	}

	var refShader = "
	#pragma header

	uniform float iTime;

	uniform float bend;
	uniform float rightBend;

	float rand(vec2 co)
	{
        return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
	}

	vec3 applyHue(vec3 aColor, float aHue)
	{
        float angle = radians(aHue);
		vec3 k = vec3(0.57735, 0.57735, 0.57735);
		float cosAngle = cos(angle);
		return aColor * cosAngle + cross(k, aColor) * sin(angle) + k * dot(k, aColor) * (1.0 - cosAngle);
	}

	vec3 applyHSBCEffect(vec3 color)
	{
        color = applyHue(color, -26.0);
		return color;
	}

	void main()
	{
    	vec2 uv = openfl_TextureCoordv;

		float x = uv.x * 2.0 - 1.0;

		float centerCurve = 1.0 - x * x;

		float rightCurve = smoothstep(0.0, 1.0, uv.x);
		rightCurve *= rightCurve;

		uv.y -= centerCurve * bend;
		uv.y -= rightCurve * rightBend;

		vec4 color = flixel_texture2D(bitmap, uv);

		if (color.a < 0.01)
			discard;

		uv.y += sin((uv.x * 56.0) + iTime * 3.0) * 0.011;

		vec4 refl = flixel_texture2D(bitmap, uv);

		vec2 px = 1.0 / openfl_TextureSize;
		vec4 blur = vec4(0.0);

		blur += flixel_texture2D(bitmap, uv + vec2(-6.0 * px.x, 0.0));
		blur += flixel_texture2D(bitmap, uv + vec2(-3.0 * px.x, 0.0));
		blur += refl * 2.0;
		blur += flixel_texture2D(bitmap, uv + vec2(3.0 * px.x, 0.0));
		blur += flixel_texture2D(bitmap, uv + vec2(6.0 * px.x, 0.0));

		refl = blur / 6.0;
		refl.rgb *= 0.45;

		float lum = dot(refl.rgb, vec3(0.299, 0.587, 0.114));
		float sparkle = step(0.995, rand(floor(uv * 350.0) + floor(iTime * 8.0))) * smoothstep(0.55, 1.0, lum);

		refl.rgb += vec3(sparkle * 0.45);

		float visibility = smoothstep(0.6, 1.0, uv.y);
		float a = refl.a * visibility;

		refl.rgb = applyHSBCEffect(refl.rgb / max(refl.a, 0.0001)) * refl.a;

		gl_FragColor = vec4(refl.rgb * a, a);
	}";

	var dangerGrad = "
	#pragma header

	uniform float cutoff;
	uniform float fadeSize;
	uniform vec3 gradientColor;
	uniform float gradientAlpha;

	void main()
	{
		vec2 uv = openfl_TextureCoordv;
		vec4 tex = flixel_texture2D(bitmap, uv);

		if (tex.a <= 0.0 || uv.x < cutoff - 5.0)
			discard;

		float visibility = 1.0 - smoothstep(cutoff, cutoff + fadeSize, uv.x);

		float a = tex.a * visibility * gradientAlpha;

		gl_FragColor = vec4(gradientColor * a, a);
	}";

	var godLight = "
	#pragma header

	uniform float iTime;
	uniform vec2 resolution;
	uniform vec3 rayColor;

	float rayStrength(vec2 raySource, vec2 rayRefDirection, vec2 coord, float seedA, float seedB, float speed)
	{
		vec2 sourceToCoord = coord - raySource;
		float cosAngle = dot(normalize(sourceToCoord), rayRefDirection);

		return clamp(
			(0.45 + 0.15 * sin(cosAngle * seedA + iTime * speed)) +
			(0.30 + 0.20 * cos(-cosAngle * seedB + iTime * speed)),
			0.0,
			1.0
		) *
		clamp(
			(resolution.x - length(sourceToCoord)) / resolution.x,
			0.5,
			1.0
		);
	}

	void main()
	{
		vec2 uv = openfl_TextureCoordv;

		vec2 coord = vec2(
			uv.x * resolution.x,
			(1.0 - uv.y) * resolution.y
		);

		vec2 rayPos1 = vec2(
			resolution.x * 0.2,
			resolution.y * 1.5
		);

		vec2 rayRefDir1 = normalize(vec2(1.0, -0.116));

		vec2 rayPos2 = vec2(
			resolution.x * 0.3,
			resolution.y * 1.6
		);

		vec2 rayRefDir2 = normalize(vec2(1.0, 0.241));

		vec4 rays1 = vec4(1.0) *
			rayStrength(
				rayPos1,
				rayRefDir1,
				coord,
				36.2214,
				21.11349,
				1.5
			);

		vec4 rays2 = vec4(1.0) *
			rayStrength(
				rayPos2,
				rayRefDir2,
				coord,
				22.39910,
				18.0234,
				1.1
			);

		vec4 rays = rays1 * 0.5 + rays2 * 0.4;

		float brightness = 1.0 - coord.y / resolution.y;

		rays.rgb *= rayColor;

		float contrast = 2.0;
		rays.rgb = (rays.rgb - 0.5) * contrast + 0.5;
		rays.rgb = clamp(rays.rgb, 0.0, 1.0);

		float spriteAlpha = flixel_texture2D(bitmap, uv).a;

		rays.rgb *= spriteAlpha;
		gl_FragColor = vec4(rays.rgb, spriteAlpha);
	}";

	function applyStagePosition(char, stageCharData)
	{
		if (char == null || stageCharData == null) return;

		char.zIndex = stageCharData.zIndex;
		char.x = stageCharData.position[0] - char.characterOrigin.x;
		char.y = stageCharData.position[1] - char.characterOrigin.y;

		var finalScale = char.getBaseScale() * stageCharData.scale;
		char.setScale(finalScale);

		char.scrollFactor.x = stageCharData.scroll[0];
		char.scrollFactor.y = stageCharData.scroll[1];

		char.alpha = stageCharData.alpha;
		char.angle = stageCharData.angle;
	}

	function mirrorAnimation(refChar, realChar)
	{
		if (refChar == null || realChar == null) return;
		if (realChar.animation.curAnim == null) return;

		if (refChar.animation.curAnim == null || refChar.animation.curAnim.name != realChar.animation.curAnim.name)
		{
			refChar.playAnimation(realChar.animation.curAnim.name, false);
		}
	}

	function getCurvedRedBar()
	{
		var mod = ModuleHandler.getModule("CurvedHealthBarModule");
		if (mod == null) return null;
		return mod.redBar;
	}

	function trySetupDangerBar(game)
	{
		if (!Save.instance.modOptions["shaders"] || dangerBar != null || dangerBarTried) return;
		if (game.healthBar == null) return;

		var curved = getCurvedRedBar();

		if (curved == null && shaderTime < 1.0 && ModuleHandler.getModule("CurvedHealthBarModule") != null) return;

		dangerBarTried = true;
		dangerSource = curved;

		dangerBar = new FunkinSprite();
		dangerBar.loadGraphic(Paths.image("ui/healthbar/WHITEBAR"));
		dangerBar.scrollFactor.set(0, 0);
		dangerBar.cameras = [game.camHUD];
		dangerBar.zIndex = 805;

		dangerShader = new FlxRuntimeShader(dangerGrad);
		dangerShader.setFloat("cutoff", 0.5);
		dangerShader.setFloat("fadeSize", 0.5);
		dangerShader.setFloatArray("gradientColor", [1.0, 0.0, 0.0]);
		dangerShader.setFloat("gradientAlpha", 1.0);
		dangerBar.shader = dangerShader;

		game.add(dangerBar);
		game.refresh();
	}

	function updateDangerBar(game, elapsed)
	{
		trySetupDangerBar(game);
		if (dangerBar == null || dangerShader == null) return;

		var hv = game.healthBar.value;

		dangerPulse += elapsed * hv;

		if (dangerSource != null)
		{
			dangerBar.x = dangerSource.x;
			dangerBar.y = dangerSource.y;
			dangerBar.flipY = dangerSource.flipY;
		}
		else
		{
			dangerBar.x = game.healthBar.x;
			dangerBar.y = game.healthBar.y;
			dangerBar.flipY = AmScroll.isDown();
		}

		dangerShader.setFloat("cutoff", 1 - (hv / 2));
		dangerShader.setFloat("fadeSize", (hv / 2) * .9);
		dangerShader.setFloat("gradientAlpha", Math.cos(FlxEase.sineInOut(dangerPulse)));
	}

	function setupGodRays(game)
	{
		if (!Save.instance.modOptions["shaders"]) return;

		var stage = game.currentStage;

		godRaysSpr = new StageProp();
		godRaysSpr.makeSolidColor(Std.int(FlxG.width * 1.5), FlxG.height, FlxColor.BLACK);
		godRaysSpr.screenCenter();
		godRaysSpr.scrollFactor.set(godRaysScrollX, godRaysScrollY);

		var holyGrad = stage.getNamedProp("holygrad");
		if (holyGrad != null) holyGrad.alpha = 0;
		godRaysSpr.zIndex = (holyGrad != null) ? holyGrad.zIndex - 2 : stage.getDad().zIndex - 3;

		godRaysShader = new FlxRuntimeShader(godLight);
		godRaysShader.setFloatArray("rayColor", [1.3, 1.2, 0.9]);
		godRaysShader.setFloatArray("resolution", [godRaysSpr.width, godRaysSpr.height]);
		godRaysShader.setFloat("iTime", 0);

		godRaysSpr.shader = godRaysShader;
		godRaysSpr.blend = BlendMode.ADD;
		godRaysSpr.alpha = 0;

		stage.addProp(godRaysSpr, "godRays");
		stage.refresh();

		godRaysBaseX = godRaysSpr.x;
		godRaysBaseY = godRaysSpr.y;
		godRaysBaseScaleX = godRaysSpr.scale.x;
		godRaysBaseScaleY = godRaysSpr.scale.y;
		godRaysBaseW = godRaysSpr.width;
		godRaysBaseH = godRaysSpr.height;

		applyGodRaysZoomFactor(game);
	}

	function applyGodRaysZoomFactor(game)
	{
		if (godRaysSpr == null) return;

		var cam = game.camGame;
		var zoom = cam.zoom;
		if (zoom <= 0) return;

		var s = Math.max(0, (1 - godRaysZoomFactor) / zoom + godRaysZoomFactor);

		godRaysSpr.scale.set(godRaysBaseScaleX * s, godRaysBaseScaleY * s);
		godRaysSpr.updateHitbox();

		var w = godRaysBaseW * s;
		var h = godRaysBaseH * s;

		var cx = godRaysBaseX + godRaysBaseW * 0.5 - cam.scroll.x * godRaysScrollX;
		var cy = godRaysBaseY + godRaysBaseH * 0.5 - cam.scroll.y * godRaysScrollY;

		var ox = cam.width * 0.5;
		var oy = cam.height * 0.5;

		var nx = (cx - ox) * s + ox;
		var ny = (cy - oy) * s + oy;

		godRaysSpr.x = nx - w * 0.5 + cam.scroll.x * godRaysScrollX;
		godRaysSpr.y = ny - h * 0.5 + cam.scroll.y * godRaysScrollY;
	}

	function hookVideo(v, token, game)
	{
		v.bitmap.onFormatSetup.add(function() {
			if (token != videoToken || vid != v) return;
			v.setGraphicSize(FlxG.width, FlxG.height);
			v.updateHitbox();
			v.screenCenter();
			videoReady = true;
		});

		v.bitmap.onEndReached.add(function() {
			if (token != videoToken || vid != v || !videoPlaying) return;
			onVideoEnd(game);
		});

		v.bitmap.onEncounteredError.add(function(msg) {
			if (token != videoToken || vid != v) return;
			trace("[DadBattleAnimania] error de video: " + msg);

			if (videoStarted) onVideoEnd(game);
			else destroyVideo(game);
		});
	}

	function destroyVideo(game)
	{
		videoToken += 1;
		videoReady = false;
		videoPending = false;
		videoPlaying = false;
		videoPrecached = false;

		if (vid == null) return;

		var v = vid;
		vid = null;

		v.visible = false;
		try
		{
			v.stop();
		}
		catch (e:Dynamic) {}
		if (game != null) game.remove(v, true);
		try
		{
			v.destroy();
		}
		catch (e:Dynamic) {}
	}

	function destroyVideoLater(v, game)
	{
		v.visible = false;
		try
		{
			v.stop();
		}
		catch (e:Dynamic) {}
		if (game != null) game.remove(v, true);

		new FlxTimer().start(0.05, function(_) {
			try
			{
				v.destroy();
			}
			catch (e:Dynamic) {}
		});
	}

	function setupVideo(game)
	{
		destroyVideo(game);

		var token = videoToken;
		var path = Paths.videos("DADBATTLE_SOLOTIME_CUTSCENE.mkv");

		var v = new FunkinVideoSprite();
		v.bitmap.volumeAdjust = 0;
		v.scrollFactor.set();
		v.cameras = [game.camHUD];
		v.zIndex = 0;
		v.visible = false;
		v.antialiasing = true;

		vid = v;
		hookVideo(v, token, game);

		var ok = false;
		try
		{
			ok = v.precache(path);
		}
		catch (e:Dynamic)
		{
			ok = false;
		}
		videoPrecached = ok;

		if (!ok)
		{
			try
			{
				ok = v.load(path);
			}
			catch (e:Dynamic)
			{
				ok = false;
			}
		}

		if (!ok)
		{
			vid = null;
			videoToken += 1;
			try
			{
				v.destroy();
			}
			catch (e:Dynamic) {}
			return;
		}

		game.add(v);
		game.refresh();
	}

	function setHudHidden(game, hidden)
	{
		if (hidden)
		{
			if (hiddenHud.length > 0) return;

			var objs = [game.healthBarBG, game.healthBar, game.iconP1, game.iconP2, dangerBar];

			var mod = ModuleHandler.getModule("CurvedHealthBarModule");
			if (mod != null)
			{
				objs.push(mod.bg);
				objs.push(mod.redBar);
				objs.push(mod.greenBar);
			}

			var score = ModuleHandler.getModule("AnimaniaScoreModule");
			if (score != null)
			{
				objs.push(score.scoreLabel);
				for (i in 0...score.scoreDigits.length)
				{
					var i = score.scoreDigits[i];
					objs.push(i);
				}
			}

			var fc = ModuleHandler.getModule("FullComboSpr");
			if (fc != null)
			{
				objs.push(fc.fcSprite);
			}

			for (o in objs)
			{
				if (o == null) continue;
				hiddenHud.push({obj: o, alpha: o.alpha});
				o.alpha = 0;
			}
		}
		else
		{
			for (h in hiddenHud) h.obj.alpha = h.alpha;
			hiddenHud = [];
		}
	}

	function startVideo(game)
	{
		if (videoStarted) return;
		videoStarted = true;

		if (vid == null)
		{
			onVideoEnd(game);
			return;
		}

		vid.bitmap.volumeAdjust = 0;
		if (videoPrecached) vid.resume();
		else vid.play();

		videoWait = 0.0;
		videoPlayTime = 0.0;
		videoStallTime = 0.0;

		if (videoReady)
		{
			showVideo(game);
		}
		else
		{
			videoPending = true;
		}
	}

	function showVideo(game)
	{
		videoPending = false;
		videoPlaying = true;
		videoPlayTime = 0.0;
		videoStallTime = 0.0;

		vid.visible = true;
		vid.antialiasing = true;

		setHudHidden(game, true);

		game.disableKeys = true;
		new FlxTimer().start(.15, function(_) {
			if (game.vocals != null) game.vocals.playerVolume = 1;
		});
	}

	function updateVideo(game, elapsed)
	{
		if (!videoStarted)
		{
			var bt = Conductor.instance.currentBeatTime;
			if (bt >= videoBeat && bt < videoEndBeat) startVideo(game);
			return;
		}

		if (videoFinished) return;

		if (videoPending)
		{
			if (vid == null)
			{
				onVideoEnd(game);
				return;
			}

			if (videoReady)
			{
				showVideo(game);
				return;
			}

			videoWait += elapsed;
			if (videoWait >= videoMaxWait)
			{
				trace("[DadBattleAnimania] el video no se pudo mostrar a tiempo: se sigue sin video");
				onVideoEnd(game);
			}
		}
		else if (videoPlaying)
		{
			videoPlayTime += elapsed;
			if (vid == null)
			{
				onVideoEnd(game);
				return;
			}

			var stalled = false;
			if (videoPlayTime > 1.0 && FlxG.sound.music != null && FlxG.sound.music.playing)
			{
				try
				{
					stalled = !vid.bitmap.isPlaying;
				}
				catch (e:Dynamic)
				{
					stalled = false;
				}
			}

			if (stalled)
			{
				videoStallTime += elapsed;
				if (videoStallTime >= videoStallMax)
				{
					trace("[DadBattleAnimania] el video se quedo sin reproducir: se cierra");
					onVideoEnd(game);
				}
			}
			else
			{
				videoStallTime = 0.0;
			}
		}
	}

	function onVideoEnd(game)
	{
		if (videoFinished) return;
		videoFinished = true;

		var v = vid;
		vid = null;
		videoToken += 1;
		videoPending = false;
		videoPlaying = false;
		videoReady = false;

		if (v != null) destroyVideoLater(v, game);

		game.camGame.flash();
		setHudHidden(game, false);
		game.disableKeys = false;

		var bf = game.currentStage.getBoyfriend();
		if (bf != null) bf.idleSuffix = "";

		var dad = game.currentStage.getDad();
		if (dad != null) dad.idleSuffix = "-alt";

		var overlay = game.currentStage.getNamedProp("fgRedOverlay");
		if (Save.instance.modOptions["shaders"] && overlay != null)
		{
			FlxTween.cancelTweensOf(overlay);
			FlxTween.tween(overlay, {alpha: 0}, 8, {startDelay: 1, ease: FlxEase.sineInOut});
		}

		startGodRaysSequence(game);

		mlVideoEnd();
	}

	function resetRunState(game)
	{
		if (game == null || game.currentStage == null) return;

		var stage = game.currentStage;

		setHudHidden(game, false);
		game.disableKeys = false;

		videoStarted = false;
		videoFinished = false;
		videoWait = 0.0;
		videoPlayTime = 0.0;
		videoStallTime = 0.0;
		setupVideo(game);

		var bf = stage.getBoyfriend();
		if (bf != null) bf.idleSuffix = "-angry";
		var dad = stage.getDad();
		if (dad != null) dad.idleSuffix = dadIdleBase;

		var overlay = stage.getNamedProp("fgRedOverlay");
		if (overlay != null)
		{
			FlxTween.cancelTweensOf(overlay);
			if (overlayBaseAlpha != null) overlay.alpha = overlayBaseAlpha;
		}

		if (godRaysSpr != null)
		{
			FlxTween.cancelTweensOf(godRaysSpr);
			godRaysSpr.alpha = 0;
		}
		var holyGrad = stage.getNamedProp("holygrad");
		if (holyGrad != null)
		{
			FlxTween.cancelTweensOf(holyGrad);
			holyGrad.alpha = 0;
		}

		if (chromChangeTween != null)
		{
			chromChangeTween.cancel();
			chromChangeTween = null;
		}
		if (chromShader != null)
		{
			chromShader.setFloat("strength", .1);
			game.camGame.filters = [new ShaderFilter(chromShader)];
		}

		dangerPulse = -300.0;

		mlInit(game);
	}

	function startGodRaysSequence(game)
	{
		if (!Save.instance.modOptions["shaders"] || godRaysSpr == null) return;

		var holyGrad = game.currentStage.getNamedProp("holygrad");

		FlxTween.cancelTweensOf(godRaysSpr);
		FlxTween.tween(godRaysSpr, {alpha: 0.1}, 3, {startDelay: 2, ease: FlxEase.sineInOut});
		FlxTween.tween(godRaysSpr, {alpha: 0}, 6, {startDelay: 20.75, ease: FlxEase.sineInOut});

		if (holyGrad != null)
		{
			FlxTween.cancelTweensOf(holyGrad);
			FlxTween.tween(holyGrad, {alpha: 0.6}, 3, {startDelay: 2, ease: FlxEase.sineInOut});
			FlxTween.tween(holyGrad, {alpha: 0}, 6, {startDelay: 20.75, ease: FlxEase.sineInOut});
		}
	}

	function godRaysEffect(alpha, time, easeStr)
	{
		if (godRaysSpr == null) return;

		FlxTween.cancelTweensOf(godRaysSpr);

		var easeFunction = Reflect.field(FlxEase, easeStr);
		if (easeFunction == null) easeFunction = FlxEase.sineInOut;

		if (time <= 0)
		{
			godRaysSpr.alpha = alpha;
		}
		else
		{
			FlxTween.tween(godRaysSpr, {alpha: alpha}, time, {ease: easeFunction});
		}
	}

	function onCreate(event)
	{
		var game = PlayState.instance;
		if (game == null || game.currentStage == null) return;

		var realBf = game.currentStage.getBoyfriend();
		var realDad = game.currentStage.getDad();

		if (Save.instance.modOptions["shaders"])
		{
		if (realBf != null)
		{
			bfRef = CharacterDataParser.fetchCharacter(realBf.characterId);
			if (bfRef != null)
			{
				game.currentStage.addCharacter(bfRef, CharacterType.OTHER);
				applyStagePosition(bfRef, game.currentStage._data.characters.bf);

				bfRef.zIndex = realBf.zIndex - 1;
				bfRef.flipX = false;
				bfRef.flipY = true;
				bfRef.useRenderTexture = true;
				bfRef.scale.y = 0.75;
				bfRef.x -= 25;
				bfRef.y += bfRef.height / 1.27;
				bfRef.skew.x = -5;

				reflectionShaderBf = new FlxRuntimeShader(refShader);
				reflectionShaderBf.setFloat("bend", 0.05);
				reflectionShaderBf.setFloat("rightBend", 0.0);
				bfRef.shader = reflectionShaderBf;
			}
		}

		if (realDad != null)
		{
			dadRef = CharacterDataParser.fetchCharacter(realDad.characterId);
			if (dadRef != null)
			{
				game.currentStage.addCharacter(dadRef, CharacterType.OTHER);
				applyStagePosition(dadRef, game.currentStage._data.characters.dad);

				dadRef.zIndex = realDad.zIndex - 1;
				game.currentStage.refresh();

				dadRef.x -= 45;
				dadRef.flipX = false;
				dadRef.flipY = true;
				dadRef.useRenderTexture = true;
				dadRef.skew.y = -11;
				dadRef.scale.y = 0.75;
				dadRef.y += dadRef.height / 1.3;
				dadRef.skew.x = -7;

				reflectionShaderDad = new FlxRuntimeShader(refShader);
				reflectionShaderDad.setFloat("bend", 0.1);
				reflectionShaderDad.setFloat("rightBend", 0.11);
				dadRef.shader = reflectionShaderDad;
			}
		}
		}

		if (Save.instance.modOptions["shaders"])
		{
			chromShader = new FlxRuntimeShader(Assets.getText(Paths.frag('chromaticAbberation')));
			chromShader.setFloat("strength", .1);
			game.camGame.filters = [new ShaderFilter(chromShader)];
		}

		setupGodRays(game);

		var ov = game.currentStage.getNamedProp("fgRedOverlay");
		overlayBaseAlpha = (ov != null) ? ov.alpha : null;
		dadIdleBase = (realDad != null) ? realDad.idleSuffix : "";

		videoStarted = false;
		videoFinished = false;
		hiddenHud = [];
		dangerPulse = -300.0;
		setupVideo(game);

		if (realBf != null) realBf.idleSuffix = "-angry";

		mlInit(game);
	}

	function onCountdownStart(event)
	{
		mlPlace(PlayState.instance);
	}

	function onSongRetry(event)
	{
		var game = PlayState.instance;
		if (game == null) return;

		resetRunState(game);
	}

	function onNoteHit(event)
	{
		if (!useModchart || !mlPlaced) return;

		var game = PlayState.instance;
		if (game == null || game.currentStage == null) return;

		if (game.opponentStrumline.notes.members.indexOf(event.note) == -1) return;

		mlDrainHealth(game, 0.0125);
		mlHit(event.note.noteData.getDirection() % 4);
	}

	function onUpdate(event)
	{
		var game = PlayState.instance;
		if (game == null || game.currentStage == null) return;

		shaderTime += event.elapsed;

		updateVideo(game, event.elapsed);

		if (bfRef != null || dadRef != null)
		{
			reflectionTime += event.elapsed;

			if (dadRef != null)
			{
				if (reflectionShaderDad != null) reflectionShaderDad.setFloat("iTime", reflectionTime);
				mirrorAnimation(dadRef, game.currentStage.getDad());
			}

			if (bfRef != null)
			{
				if (reflectionShaderBf != null) reflectionShaderBf.setFloat("iTime", reflectionTime);
				mirrorAnimation(bfRef, game.currentStage.getBoyfriend());
			}
		}

		if (chromShader != null)
		{
			var overlay = game.currentStage.getNamedProp("fgRedOverlay");
			if (overlay != null)
			{
				chromShader.setFloat("strength", overlay.alpha / 8);
			}
		}

		updateDangerBar(game, event.elapsed);

		if (godRaysShader != null)
		{
			godRaysShader.setFloat("iTime", shaderTime);
		}

		applyGodRaysZoomFactor(game);

		mlUpdate(game, event.elapsed);
	}

	function onResume(event)
	{
		var game = PlayState.instance;
		if (game == null) return;

		if (vid != null && (videoPlaying || videoPending)) vid.resume();

		if (chromShader == null) return;
		game.camGame.filters = [new ShaderFilter(chromShader)];
	}

	function onSongEvent(event)
	{
		if (event == null || event.eventData == null) return;

		if (event.eventData.eventKind == "Blank")
		{
			var value1 = event.eventData.getString("value1");
			if (value1 == null) return;

			var kind = value1.toLowerCase();

			if (kind == "chroma")
			{
				chromaEffect(event.eventData.getFloat("value2"), event.eventData.getFloat("value3"), event.eventData.getString("value4"));
			}
			else if (kind == "godrays")
			{
				godRaysEffect(event.eventData.getFloat("value2"), event.eventData.getFloat("value3"), event.eventData.getString("value4"));
			}
		}
	}

	function onBeatHit(event)
	{
		var game = PlayState.instance;
		if (game == null || game.currentStage == null) return;

		mlBeat(event.beat);

		if (event.beat >= videoBeat && event.beat < videoEndBeat)
			startVideo(game);

		if (event.beat > videoBeat - 1 && event.beat < 250 && game.vocals != null)
			game.vocals.playerVolume = 1;
	}

	function onPause(event)
	{
		if (vid != null && (videoPlaying || videoPending)) vid.pause();
	}

	function onGameOver(event)
	{
		var game = PlayState.instance;
		if (game == null) return;

		if (Save.instance.modOptions["shaders"])
			game.camGame.filters = [];

		if (vid != null)
		{
			try
			{
				vid.stop();
			}
			catch (e:Dynamic) {}
			vid.visible = false;
		}
		videoPending = false;
		videoPlaying = false;
		setHudHidden(game, false);
		game.disableKeys = false;
	}

	function onDestroy(event)
	{
		var game = PlayState.instance;

		if (game != null)
		{
			if (mlOppIncomingFn != null && game.opponentStrumline != null) game.opponentStrumline.onNoteIncoming.remove(mlOppIncomingFn);
			if (mlPlrIncomingFn != null && game.playerStrumline != null) game.playerStrumline.onNoteIncoming.remove(mlPlrIncomingFn);
		}
		if (mlPostFn != null)
		{
			FlxG.signals.postUpdate.remove(mlPostFn);
			mlPostFn = null;
		}
		mlOppIncomingFn = null;
		mlPlrIncomingFn = null;
		mlPlaced = false;
		mlTw = new StringMap();
		mlOpp = null;
		mlPlr = null;
		mlPlrRecs = [];
		mlOppRecs = [];

		if (dangerBar != null)
		{
			if (game != null) game.remove(dangerBar, true);
			dangerBar.destroy();
			dangerBar = null;
		}

		destroyVideo(game);
		videoStarted = false;
		videoFinished = false;
		hiddenHud = [];

		bfRef = null;
		dadRef = null;
		reflectionShaderBf = null;
		reflectionShaderDad = null;
		reflectionTime = 0;
		shaderTime = 0.0;
		chromShader = null;
		chromChangeTween = null;
		dangerPulse = -300.0;

		dangerShader = null;
		dangerSource = null;
		dangerBarTried = false;
		godRaysShader = null;
		godRaysSpr = null;
	}

	function chromaEffect(strength, time, easeStr)
	{
		if (chromShader == null) return;

		if (chromChangeTween != null)
			chromChangeTween.cancel();

		var easeFunction = Reflect.field(FlxEase, easeStr);
		if (easeFunction == null) easeFunction = FlxEase.smootherStepOut;

		if (time <= 0)
		{
			chromShader.setFloat("strength", strength);
		}
		else
		{
			chromChangeTween = FlxTween.num(chromShader.getFloat("strength"), strength, time, {ease: easeFunction}, function(stng) {
				chromShader.setFloat("strength", stng);
			});
		}
	}
}

class EggnogAnimaniaSong extends Song
{
	function new()
	{
		super('eggnog-animania');
	}

	function shadersEnabled():Bool
	{
		return Save.instance.modOptions["shaders"] == true;
	}

	var playEggnogCountdownSounds:Bool = true;

	var firefliesZoomFactor:Float = 0.35;

	var fireFliesShader = null;
	var fireFliesSpr = null;
	var fireFliesTime:Float = 0;
	var fireFliesBaseScaleX:Float = 1;
	var fireFliesBaseScaleY:Float = 1;

	var fireFliesFrag:String = "
#pragma header
uniform float iTime;
uniform vec2 iResolution;
uniform float iFireflyCount;
uniform float iFarFireflyCount;
uniform float uFireflySize;
uniform float uGlowRange;
#define MAX_FIREFLIES 24.0
#define MAX_FAR_FIREFLIES 24.0
const vec3 warmColor = vec3(0.9255, 0.7137, 0.5137);
const vec3 coolColor = vec3(0.9137, 0.9020, 0.6667);

float N21(vec2 p) {
    vec3 a = fract(vec3(p.xyx) * vec3(213.897, 653.453, 253.098));
    a += dot(a, a.yzx + 79.76);
    return fract((a.x + a.y) * a.z);
}
vec2 N22(vec2 p) {
    float n = N21(p);
    return vec2(n, N21(n + p));
}

float glowFalloffSq(float d2) {
    float r2 = uGlowRange * uGlowRange;
    if (d2 >= r2) return 0.0;
    float invDist = inversesqrt(max(d2, 0.00001));
    float glow = uFireflySize * invDist;
    float t = d2 / r2;
    glow *= (1.0 - t * t);
    return min(glow, 1.0);
}

void main() {
    vec2 uv = openfl_TextureCoordv * 2.0 - 1.0;
    float intensity = 0.0;
    float alpha = 0.0;

    for (float i = 0.0; i < MAX_FIREFLIES; i++) {
        if (i >= iFireflyCount) break;
        vec2 rnd = N22(vec2(i, i * 2.0));
        float angle = iTime * rnd.x + i;
        
        vec2 rndMod = N22(vec2(i + 0.5, i * 3.0 + 0.1));
        float rndSq = rndMod.x * rndMod.x;
        float radius = 2.0 * (0.1 + 0.9 * rndSq);
        vec2 center = 0.1 * vec2(sin(iTime * 0.4 + i), cos(iTime * 0.4 + i * 1.7));

        vec2 point = vec2(cos(angle) * radius, sin(angle)) + center;
        vec2 diff = uv - point;
        float d2 = dot(diff, diff);
        float glow = glowFalloffSq(d2);
        glow *= 0.35 + 0.65 * (0.5 + 0.5 * sin(angle * 1.35));
        intensity += glow;
        alpha += glow;
    }

    for (float i = 0.0; i < MAX_FAR_FIREFLIES; i++) {
        if (i >= iFarFireflyCount) break;
        float idx = i + 60.0;
        vec2 rnd = N22(vec2(idx, idx + 2.0));
        float angle = iTime * rnd.x + idx;
        
        vec2 rndMod = N22(vec2(idx + 0.5, idx * 3.0 + 0.1));
        float rndSq = rndMod.x * rndMod.x;
        float radius = 1.5 * (0.1 + 0.9 * rndSq);
        vec2 center = 0.08 * vec2(cos(iTime * 0.35 + idx), sin(iTime * 0.35 + idx * 1.4));

        vec2 point = vec2(cos(angle) * radius, sin(angle)) + center;
        vec2 diff = uv - point;
        float d2 = dot(diff, diff);
        float glow = glowFalloffSq(d2);
        glow *= 0.25 + 0.55 * (0.5 + 0.5 * sin(angle * 1.15));
        intensity += glow;
        alpha += glow;
    }

    alpha = clamp(alpha, 0.0, 1.0);
    vec3 color = mix(coolColor, warmColor, alpha);
    gl_FragColor = vec4(color * intensity, alpha);
}";

	override function onCreate(event)
	{
		super.onCreate(event);

		fireFliesShader = null;
		fireFliesSpr = null;
		fireFliesTime = 0;

		createFadeIn();
		createFireflies();
	}

	function createFadeIn():Void
	{
		if (!PlayStatePlaylist.isStoryMode)
			return;

		var play = PlayState.instance;

		var screeeen = new FunkinSprite();
		screeeen.makeSolidColor(2000, 2000, 0xFF000000);
		screeeen.screenCenter();
		screeeen.cameras = [play.camHUD];
		screeeen.zIndex = 999999;
		screeeen.alpha = 1;
		play.add(screeeen);

		FlxTween.tween(screeeen, {alpha: 0}, 1, {ease: FlxEase.sineIn});

		play.refresh();
	}

	override function onCountdownStep(event)
	{
		super.onCountdownStep(event);

		if (!playEggnogCountdownSounds)
			return;

		var soundPath:String = null;

		switch (Std.string(event.step))
		{
			case "THREE":
				soundPath = 'intro3';
			case "TWO":
				soundPath = 'intro2';
			case "ONE":
				soundPath = 'intro1';
			case "GO":
				soundPath = 'introGo';
			default:
		}

		if (soundPath == null)
			return;

		FunkinSound.playOnce(Paths.sound("week5/" + soundPath + "-eggnog", "shared"), 1);
	}

	override function onBeatHit(event)
	{
		super.onBeatHit(event);

		var play = PlayState.instance;
		if (play == null || play.isPlayerDying)
			return;

		var stage = play.currentStage;
		if (stage == null)
			return;

		switch (event.beat)
		{
			case 221:
				var snowman = stage.getNamedProp("snowman");
				if (snowman != null)
					FlxTween.tween(snowman, {alpha: .4}, .25, {ease: FlxEase.backOut});

			case 222:
				var cops = stage.getNamedProp("cops");
				if (cops != null)
					cops.playAnimation("throw", true, true);

			case 224:
				if (play.health > .3)
					play.health -= .2;

			case 226:
				var dad = stage.getDad();
				if (dad != null)
					dad.playAnimation("eggL", true, true);

				var snowman = stage.getNamedProp("snowman");
				if (snowman != null)
					FlxTween.tween(snowman, {alpha: 1}, .25, {ease: FlxEase.backOut});

			case 232:
				setAngryIdle(stage);

			case 284:
				setAngryIdle(stage);
		}
	}

	function setAngryIdle(stage):Void
	{
		var dad = stage.getDad();
		if (dad == null)
			return;

		dad.idleSuffix = "-angry";
		dad.shouldAlternate = false;
	}

	function createFireflies():Void
	{
		if (!shadersEnabled())
			return;

		var stage = PlayState.instance.currentStage;
		if (stage == null)
			return;

		fireFliesShader = new FlxRuntimeShader(fireFliesFrag);
		fireFliesShader.setFloat("iTime", 0);

		fireFliesSpr = new FunkinSprite();
		fireFliesSpr.makeSolidColor(Std.int(FlxG.width * 2.5), Std.int(FlxG.height * 2.5), 0xFF000000);
		fireFliesSpr.zIndex = 390;
		stage.add(fireFliesSpr);
		stage.refresh();
		fireFliesSpr.scrollFactor.set(0.75, 0.75);
		fireFliesSpr.screenCenter();
		fireFliesSpr.blend = BlendMode.ADD;
		fireFliesSpr.shader = fireFliesShader;

		fireFliesBaseScaleX = fireFliesSpr.scale.x;
		fireFliesBaseScaleY = fireFliesSpr.scale.y;

		fireFliesShader.setFloat("iFireflyCount", 20);
		fireFliesShader.setFloat("iFarFireflyCount", 25);
		fireFliesShader.setFloat("uFireflySize", 0.01);
		fireFliesShader.setFloat("uGlowRange", 0.2);
		fireFliesShader.setFloatArray("iResolution", [fireFliesSpr.width, fireFliesSpr.height]);
	}

	override function onUpdate(event)
	{
		super.onUpdate(event);

		if (fireFliesShader == null || fireFliesSpr == null)
			return;

		fireFliesTime += event.elapsed * .25;
		fireFliesShader.setFloat("iTime", fireFliesTime);

		var zoom = FlxG.camera.zoom;
		var f = (1 - firefliesZoomFactor) / zoom + firefliesZoomFactor;
		fireFliesSpr.scale.set(fireFliesBaseScaleX * f, fireFliesBaseScaleY * f);
	}
}

class WinterHorrorlandAnimaniaSong extends Song
{

  var SKIP_COUNTDOWN:Bool = true;

  var OPPONENT_NOTE_DRAIN:Float = 0.0075;
  var OPPONENT_HOLD_DRAIN:Float = 0.05;

  var PLAYER_STRUM_SCALE:Float = 0.95;
  var CENTER_PLAYER_STRUMLINE:Bool = false;

  var HINT_CONTROL:String = "SPACE";

  var INTRO_LENGTH:Float = 7.8;

  var SNOW_ENABLED:Bool = true;
  var SNOW_ZINDEX:Int = 395;
  var SNOW_ZOOM_FACTOR:Float = 0.9;
  var SNOW_LAYERS:Int = 30;
  var SNOW_DEPTH:Float = 0.3;
  var SNOW_BASE_WIDTH:Float = 0.2;
  var SNOW_BASE_SPEED:Float = 0.6;
  var SNOW_BASE_ALPHA:Float = 0.55;
  var SNOW_BASE_COLOR = 0xFFDEADB9;
  var SNOW_RED_COLOR = 0xFFEB6083;

  var ps = null;

  var chromShader = null;
  var chromTween = null;
  var chromaValue:Float = 0;

  var barUp = null;
  var barDown = null;
  var barTween = null;
  var barVis:Float = 160;
  var barW:Float = 1;
  var barH:Float = 1;
  var barBaseScaleX:Float = 1;
  var barBaseScaleY:Float = 1;

  var darkLight = null;
  var blend2 = null;
  var snowman = null;
  var darkLightBaseAlpha:Float = 0;
  var snowmanBaseX:Float = 0;

  var hudStrumY:Float = 0;
  var hudBarY:Float = 0;
  var hudBarBgY:Float = 0;
  var hudScoreY:Float = 0;

  var snowShader = null;
  var snowSpr = null;
  var snowTime:Float = 0;
  var snowTimeSpeed:Float = 1;
  var snowWidth:Float = 0.2;
  var snowBaseScaleX:Float = 1;
  var snowBaseScaleY:Float = 1;
  var snowSpeedTween = null;
  var snowAlphaTween = null;
  var snowWidthTween = null;

  var hintText = null;
  var introBlack = null;
  var cutsceneSound = null;
  var cutsceneBf = null;

  var ass = [];
  var timers = [];

  var seenCutscene:Bool = false;
  var playedCutscene:Bool = false;
  var allowEnd:Bool = false;

  public function new()
  {
    super('winter-horrorland-animania');
  }

  override function onCreate(event:ScriptEvent):Void
  {
    super.onCreate(event);

    ps = PlayState.instance;
    if (ps == null) return;

    resetRuntimeState();
    setupChroma();
    styleSubtitles();
    setIntroCamera();
    createSnow();

    ps.opponentStrumline.x -= FlxG.width / 1.5;
    ps.opponentStrumline.alpha = 0;

    darkLight = getProp("darkLight");
    blend2 = getProp("blend2");
    snowman = getProp("snowman");
    if (darkLight != null) darkLightBaseAlpha = darkLight.alpha;
    if (snowman != null) snowmanBaseX = snowman.x;

    if (ps.isChartingMode)
    {
      if (darkLight != null) darkLight.alpha = 0;
      return;
    }

    if (blend2 != null) blend2.alpha = .25;
    ps.camHUD.alpha = 0;

    applyPlayerStrumlineMode();
    storeHudBase();
    createBars();
    createHint();

    FunkinMemory.cacheSound(Paths.sound("songs/lemon-intro"));
    FunkinMemory.cacheTexture(Paths.image("stages/xMassCityMallNasty/ha"));
  }

  override function onDestroy(event:ScriptEvent):Void
  {
    super.onDestroy(event);
    ps = null;
  }

  override function onGameOver(event:ScriptEvent):Void
  {
    super.onGameOver(event);
    if (ps == null) return;
    ps.camGame.filters = [];
  }

  override function onSongRetry(event:SongRetryEvent):Void
  {
    super.onSongRetry(event);
    if (ps == null) return;

    allowEnd = false;
    cancelTimers();
    chromaEffect(0, 0, null);
    applyChromaFilter();
    setIntroCamera();
    resetSnow();

    if (ps.isChartingMode) return;

    FlxTween.cancelTweensOf(ps.camHUD);
    ps.camHUD.alpha = 0;

    FlxTween.cancelTweensOf(ps.playerStrumline);
    ps.playerStrumline.y = hudStrumY;
    ps.playerStrumline.alpha = 1;

    FlxTween.cancelTweensOf(ps.healthBar);
    FlxTween.cancelTweensOf(ps.healthBarBG);
    ps.healthBar.y = hudBarY;
    ps.healthBarBG.y = hudBarBgY;
    var st = getScoreText();
    if (st != null)
    {
      FlxTween.cancelTweensOf(st);
      st.y = hudScoreY;
    }

    if (barTween != null) barTween.cancel();
    barTween = null;
    barVis = 160;

    if (darkLight != null)
    {
      FlxTween.cancelTweensOf(darkLight);
      darkLight.alpha = darkLightBaseAlpha;
    }
    if (blend2 != null)
    {
      FlxTween.cancelTweensOf(blend2);
      blend2.alpha = .25;
    }
    if (snowman != null) snowman.x = snowmanBaseX;

    if (hintText != null)
    {
      FlxTween.cancelTweensOf(hintText);
      hintText.alpha = 0;
      hintText.scale.set(1, 1);
    }

    var i = 0;
    while (i < ass.length)
    {
      var ha = ass[i];
      i = i + 1;
      if (ha != null)
      {
        FlxTween.cancelTweensOf(ha);
        ps.currentStage.remove(ha);
        ha.kill();
        ha.destroy();
      }
    }
    ass = [];

    introBlack = makeBlack();
  }

  override function onUpdate(event:UpdateScriptEvent):Void
  {
    super.onUpdate(event);
    if (ps == null) return;

    layoutBars();
    updateSnow(event.elapsed);
    drainOnOpponentHolds(event.elapsed);
  }

  override function onCountdownStart(event:CountdownScriptEvent):Void
  {
    super.onCountdownStart(event);
    if (ps == null) return;

    var charting = ps.isChartingMode;

    if (!playedCutscene && !charting && !seenCutscene)
    {
      playedCutscene = true;
      event.cancel();
      startCutscene();
      return;
    }

    if (seenCutscene)
    {
      ps.tweenCameraZoom(1.6, 0, false);

      var black = introBlack;
      if (black == null) black = makeBlack();
      introBlack = null;
      fadeOutBlack(black, 1.8, FlxEase.backOut);
      ps.refresh();
    }

    seenCutscene = true;
    ps.isInCutscene = false;
    chromaEffect(.05, 2, "sineInOut");

    if (SKIP_COUNTDOWN && !charting)
    {
      event.cancel();
      skipCountdown();
    }
  }

  function skipCountdown()
  {
    Countdown.stopCountdown();
    ps.isInCountdown = true;
    ps.camHUD.visible = true;
    Conductor.instance.update(ps.startTimestamp);
  }

  function startCutscene()
  {
    ps.isInCutscene = true;
    chromaEffect(.1, 0, "sineOut");

    var black = makeBlack();
    moveBars(60, 0, null, 0);

    var bf = ps.currentStage.getBoyfriend();
    var dad = ps.currentStage.getDad();

    cutsceneSound = FunkinSound.load(Paths.sound("songs/lemon-intro"), 1, false, true, false);

    cutsceneBf = new FunkinSprite(bf.x + 592, bf.y + 208, Paths.animateAtlas("stages/xMassCityMallNasty/intro-cutscene", "shared"), {useRenderTexture: true});
    cutsceneBf.zIndex = bf.zIndex + 15;
    bf.visible = false;
    cutsceneBf.animation.onFinish.add(function(name)
    {
      cutsceneBf.visible = false;
      bf.visible = true;
    });

    var colorShader = new AdjustColorShader();
    colorShader.hue = -10;
    colorShader.saturation = -20;
    colorShader.contrast = 0;
    colorShader.brightness = 0;
    cutsceneBf.shader = colorShader;
    ps.currentStage.add(cutsceneBf);

    if (snowman != null) snowman.x = snowmanBaseX + 350;
    ps.currentStage.refresh();
    ps.refresh();

    later(.15, function(_)
    {
      if (cutsceneSound != null) cutsceneSound.play(true);
      cutsceneBf.animation.play("spritemap", true);
      fadeOutBlack(black, .5, FlxEase.sineOut);

      ps.tweenCameraZoom(2, 0, false);
      ps.tweenCameraZoom(1.8, .75, false, FlxEase.cubeOut);
    });

    later(.15 + 33 / 24, function(_)
    {
      ps.tweenCameraZoom(1.7, 13 / 24, false, FlxEase.quadInOut);
      ps.tweenCameraToPosition(ps.cameraFollowPoint.x + 120, ps.cameraFollowPoint.y - 50, 13 / 24, FlxEase.quadInOut);
      chromaEffect(0, .15, "sineOut");
      moveBars(85, 1.1, FlxEase.backOut, 0);
    });

    later(.15 + 90 / 24, function(_)
    {
      ps.tweenCameraZoom(.9, 26 / 24, false, FlxEase.quadInOut);
      ps.tweenCameraToPosition(-250, -500, 26 / 24, FlxEase.quadInOut);
      moveBars(35, 1.1, FlxEase.backOut, 0);
    });

    later(.15 + 97 / 24, function(_)
    {
      moveBars(80, .35, FlxEase.backOut, .6);
      if (dad != null)
      {
        dad.playAnimation("trans");
        dad.animation.onFinish.addOnce(function(name)
        {
          dad.playAnimation("singRIGHT-alt");
          ps.tweenCameraZoom(1.1, .35, false, FlxEase.backOut);
          moveBars(80, .35, FlxEase.backOut, .6);
        });
      }
    });

    later(.15 + 114 / 24, function(_)
    {
      chromaEffect(.25, .15, "sineOut");
      ps.camGame.shake(0.0025, 15 / 25);
      if (darkLight != null)
      {
        darkLight.alpha = .5;
        FlxTween.tween(darkLight, {alpha: .6}, 24 / 24, {ease: FlxEase.bounceIn});
        FlxTween.tween(darkLight, {alpha: .9}, 25 / 24, {startDelay: 1, ease: FlxEase.quadOut});
      }
      later(1, function(_)
      {
        chromaEffect(0.05, 1, "cubeOut");
      });
    });

    later(INTRO_LENGTH, function(_)
    {
      ps.startCountdown();
    });
  }

  override function onSongStart(event:ScriptEvent):Void
  {
    super.onSongStart(event);
    FlxG.sound.music.volume = 0;
    FlxG.sound.music.fadeOut(1, 1);
  }

  override function onSongEnd(event:ScriptEvent):Void
  {
    super.onSongEnd(event);
    if (ps == null) return;

    if (!allowEnd)
    {
      allowEnd = true;
      event.cancel();
      later(1, function(_)
      {
        ps.endSong();
      });
    }
  }

  override function onSongEvent(event:SongEventScriptEvent):Void
  {
    super.onSongEvent(event);

    var data = event.eventData;
    if (data == null || data.eventKind != "Blank") return;

    var v1 = data.getString("value1");
    if (v1 == null || v1.toLowerCase() != "chroma") return;

    var strength = data.getFloat("value2");
    var time = data.getFloat("value3");
    if (strength == null) strength = 0;
    if (time == null) time = 0;
    chromaEffect(strength, time, data.getString("value4"));
  }

  override function onNoteHit(event:HitNoteScriptEvent):Void
  {
    super.onNoteHit(event);
    if (ps == null || event.note == null || event.note.noteData == null) return;

    if (Math.floor(event.note.noteData.data / 4) != 1) return;

    if (ps.health > .1) ps.health = ps.health - OPPONENT_NOTE_DRAIN;
  }

  function drainOnOpponentHolds(elapsed)
  {
    if (ps.isInCutscene || ps.opponentStrumline == null) return;

    var members = ps.opponentStrumline.holdNotes.members;
    var i = 0;
    while (i < members.length)
    {
      var h = members[i];
      i = i + 1;
      if (h == null || !h.alive) continue;

      if (h.hitNote && !h.missedNote && h.sustainLength > 0 && ps.health > .1)
      {
        ps.health = ps.health - OPPONENT_HOLD_DRAIN * elapsed;
      }
    }
  }

  override function onBeatHit(event:SongTimeScriptEvent):Void
  {
    super.onBeatHit(event);
    if (ps == null) return;

    snowBeat(event.beat);

    if (ps.isChartingMode) return;

    var beat = event.beat;

    if (beat == 8)
    {
      chromaEffect(.35, 0, "sineOut");
      chromaEffect(.15, 41 / 24, "cubeOut");

      if (darkLight != null)
      {
        darkLight.alpha = .4;
        FlxTween.tween(darkLight, {alpha: .7}, 41 / 24, {ease: FlxEase.cubeOut});
      }
      if (blend2 != null)
      {
        blend2.alpha = 1;
        FlxTween.tween(blend2, {alpha: .6}, 41 / 24, {ease: FlxEase.cubeOut});
      }

      moveBars(110, 1.1, FlxEase.backOut, 0);

      if (snowman != null) snowman.x = snowmanBaseX;

      if (hintText != null && hintText.visible)
      {
        FlxTween.tween(hintText, {"scale.x": 1.1, "scale.y": 1.1, alpha: 1}, 1.25, {ease: FlxEase.cubeOut});
      }
    }
    else if (beat == 16)
    {
      if (hintText != null && hintText.visible)
      {
        FlxTween.tween(hintText, {"scale.x": 0.9, "scale.y": 0.9, alpha: 0}, 2.25, {ease: FlxEase.sineIn});
      }
    }
    else if (beat == 22)
    {
      tweenAlpha(darkLight, .85, 15 / 24, FlxEase.linear);
      FlxTween.tween(ps.camHUD, {alpha: 1}, 1.25, {ease: FlxEase.backOut});
      hudIntro();
      chromaEffect(.075, 3, "sineOut");
    }
    else if (beat == 24)
    {
      moveBars(-190, 1.1, FlxEase.backOut, 0);
    }
    else if (beat == 40)
    {
      tweenAlpha(darkLight, 1, 25 / 24, FlxEase.quadInOut);
    }
    else if (beat == 56)
    {
      tweenAlpha(darkLight, .6, 30 / 24, FlxEase.quadInOut);
    }
    else if (beat == 72)
    {
      tweenAlpha(darkLight, 1, 56 / 24, FlxEase.linear);
    }
    else if (beat == 84)
    {
      tweenAlpha(darkLight, 0, 12 / 24, FlxEase.cubeOut);
      createHahaha(-800, -800);
    }
    else if (beat == 85)
    {
      createHahaha(-1150, -665);
    }
    else if (beat == 86)
    {
      createHahaha(-1350, -1115);
    }
    else if (beat == 87)
    {
      createHahaha(-850, -1150);
    }
    else if (beat == 88)
    {
      if (blend2 != null)
      {
        blend2.alpha = 1;
        FlxTween.tween(blend2, {alpha: .7}, 18 / 24, {ease: FlxEase.cubeOut});
      }

      var i = 0;
      while (i < ass.length)
      {
        fadeHahaha(ass[i]);
        i = i + 1;
      }
      ass = [];
    }
    else if (beat == 386)
    {
      var screen = makeBlack();
      screen.alpha = 0;
      FlxTween.tween(screen, {alpha: 1}, 1.5, {ease: FlxEase.sineOut});
    }
  }

  function createHahaha(xx, yy)
  {
    var ha = new FunkinSprite(xx, yy);
    ha.loadTexture("stages/xMassCityMallNasty/ha");
    ha.zIndex = 10000;
    ha.angle = FlxG.random.float(-10, 10);
    ps.currentStage.add(ha);
    ha.scrollFactor.set(1, 1);
    ps.currentStage.refresh();
    ass[ass.length] = ha;

    ha.scale.set(.9, .9);
    FlxTween.tween(ha, {"scale.x": 1.1, "scale.y": 1.1, angle: ha.angle + FlxG.random.float(-7, 7)}, .15, {ease: FlxEase.cubeOut});
  }

  function fadeHahaha(ha)
  {
    if (ha == null) return;
    FlxTween.tween(ha, {"scale.x": .5, "scale.y": .5, angle: ha.angle + FlxG.random.float(-10, 10), alpha: 0}, .25, {
      ease: FlxEase.cubeOut,
      onComplete: function(_)
      {
        if (ps != null && ps.currentStage != null) ps.currentStage.remove(ha);
        ha.kill();
        ha.destroy();
      }
    });
  }

  function hudIntro()
  {
    var d = ps.playerStrumline.isDownscroll ? 25 : -25;

    ps.playerStrumline.y = hudStrumY + d;
    ps.playerStrumline.alpha = 0;
    FlxTween.tween(ps.playerStrumline, {y: hudStrumY, alpha: 1}, .5, {ease: FlxEase.cubeOut});

    ps.healthBar.y = hudBarY - d;
    ps.healthBarBG.y = hudBarBgY - d;
    FlxTween.tween(ps.healthBar, {y: hudBarY}, .5, {ease: FlxEase.cubeOut});
    FlxTween.tween(ps.healthBarBG, {y: hudBarBgY}, .5, {ease: FlxEase.cubeOut});

    var st = getScoreText();
    if (st != null)
    {
      st.y = hudScoreY - d;
      FlxTween.tween(st, {y: hudScoreY}, .5, {ease: FlxEase.cubeOut});
    }
  }

  function createBars()
  {
    barW = Math.max(FlxG.width, ps.camGame.width) * 1.5;
    barH = FlxG.height * 1.25;
    barBaseScaleX = barW / 2;
    barBaseScaleY = barH / 2;

    barUp = makeBar();
    barDown = makeBar();
    barVis = 160;
    layoutBars();
  }

  function makeBar()
  {
    var bar = new FunkinSprite();
    bar.makeSolidColor(Std.int(barW), Std.int(barH), FlxColor.BLACK);
    bar.scrollFactor.set(0, 0);
    bar.zIndex = 5000;
    ps.add(bar);
    ps.refresh();
    return bar;
  }

  function layoutBars()
  {
    if (barUp == null || barDown == null || ps == null) return;

    var cam = ps.camGame;
    var z = cam.zoom;
    if (z < 0.05) z = 0.05;

    var cx = cam.width / 2;
    var cy = cam.height / 2;
    var w = barW / z;
    var h = barH / z;

    barUp.scale.set(barBaseScaleX / z, barBaseScaleY / z);
    barUp.updateHitbox();
    barUp.x = cx - w / 2;
    barUp.y = (cy + (barVis - cy) / z) - h;

    barDown.scale.set(barBaseScaleX / z, barBaseScaleY / z);
    barDown.updateHitbox();
    barDown.x = cx - w / 2;
    barDown.y = cy + ((cam.height - barVis) - cy) / z;
  }

  function moveBars(target, time, ease, delay)
  {
    if (delay > 0)
    {
      later(delay, function(_)
      {
        moveBars(target, time, ease, 0);
      });
      return;
    }

    if (barTween != null) barTween.cancel();
    barTween = null;

    if (time <= 0)
    {
      barVis = target;
      return;
    }

    barTween = FlxTween.num(barVis, target, time, {ease: ease}, function(v)
    {
      barVis = v;
    });
  }

  function setupChroma()
  {
    try
    {
      chromShader = new FlxRuntimeShader(Assets.getText(Paths.frag("chromaticAbberation")));
      chromShader.setFloat("strength", 0);
      applyChromaFilter();
    }
    catch (e:Dynamic)
    {
      chromShader = null;
      trace("[winter-horrorland-animania] No se pudo crear el shader de aberración cromática: " + e);
    }
  }

  function applyChromaFilter()
  {
    if (chromShader == null || ps == null) return;
    ps.camGame.filters = [new ShaderFilter(chromShader)];
  }

  function chromaEffect(strength, time, easeStr)
  {
    if (chromShader == null) return;

    if (chromTween != null) chromTween.cancel();
    chromTween = null;

    if (time <= 0)
    {
      chromaValue = strength;
      chromShader.setFloat("strength", strength);
    }
    else
    {
      chromTween = FlxTween.num(chromaValue, strength, time, {ease: getEase(easeStr)}, function(v)
      {
        chromaValue = v;
        chromShader.setFloat("strength", v);
      });
    }
  }

  function getEase(name)
  {
    var f = null;
    if (name != null)
    {
      try
      {
        f = Reflect.field(FlxEase, name);
      }
      catch (e:Dynamic)
      {
        f = null;
      }
    }
    if (f == null) f = FlxEase.smootherStepOut;
    return f;
  }

  var SNOW_FRAG:String = "
#pragma header

uniform float iTime;
uniform int iLayers;
uniform float iDepth;
uniform float iWidth;
uniform float iSpeed;

const vec2 EFFECT_SCALE = vec2(6.0, 4.0);

float snowing(in vec2 uv)
{
    const mat3 p = mat3(13.323122, 23.5112, 21.71123,
                        21.1212, 28.7312, 11.9312,
                        21.8112, 14.7212, 61.3934);
    uv.y = 1.0 - uv.y;
    float depth = iDepth;
    float width = iWidth;
    float speed = iSpeed;
    float acc = 0.0;
    float dof = 5.0 * sin(iTime * 0.1);

    float angle = iTime * 2.0;
    float s = sin(angle);
    float c = cos(angle);
    const float cos1 = 0.5403023058681398;
    const float sin1 = 0.8414709848078965;

    for (int fi = 0; fi < iLayers; fi++)
    {
        float fi_f = float(fi);
        vec2 q = uv * (1.0 + fi_f * depth);
        float w = width * fract(fi_f * 7.238917) - width * 0.1 * s;
        q += vec2(q.y * w, speed * iTime / (1.0 + fi_f * depth * 0.03));

        vec3 n = vec3(floor(q), 31.189 + fi_f);
        vec3 m = floor(n) * 0.00001 + fract(n);

        vec3 pm = vec3(dot(p[0], m), dot(p[1], m), dot(p[2], m));
        vec3 r = fract((31415.9 + m) / fract(pm));

        vec2 s_xy = abs(mod(q, 1.0) - 0.5 + 0.9 * r.xy - 0.45);
        s_xy += 0.01 * abs(2.0 * fract(10.0 * q.yx) - 1.0);
        float d = 0.6 * max(s_xy.x - s_xy.y, s_xy.x + s_xy.y) + max(s_xy.x, s_xy.y) - 0.01;
        float edge = 0.05 + 0.05 * min(0.5 * abs(fi_f - 5.0 - dof), 1.0);
        acc += smoothstep(edge, -edge, d) * (r.x / (1.0 + 0.02 * fi_f * depth));

        float new_s = s * cos1 + c * sin1;
        float new_c = c * cos1 - s * sin1;
        s = new_s;
        c = new_c;
    }
    return (acc + acc * acc) / 1.75;
}

void main()
{
    vec4 texColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
    float alpha = snowing(openfl_TextureCoordv.xy * EFFECT_SCALE) * 1.25;
    vec3 flakeColor = texColor.rgb;
    gl_FragColor = vec4(flakeColor * alpha, alpha * texColor.a);
}";

  function createSnow()
  {
    if (!SNOW_ENABLED || !Save.instance.modOptions["shaders"]) return;

    try
    {
      snowShader = new FlxRuntimeShader(SNOW_FRAG);
    }
    catch (e:Dynamic)
    {
      snowShader = null;
      trace("[winter-horrorland-animania] No se pudo crear el shader de nieve: " + e);
      return;
    }

    snowShader.setFloat("iTime", 0);
    snowShader.setInt("iLayers", SNOW_LAYERS);
    snowShader.setFloat("iDepth", SNOW_DEPTH);
    snowShader.setFloat("iWidth", SNOW_BASE_WIDTH);
    snowShader.setFloat("iSpeed", SNOW_BASE_SPEED);

    snowSpr = new FunkinSprite();
    snowSpr.makeSolidColor(Std.int(FlxG.width * 4), Std.int(FlxG.height * 4), FlxColor.WHITE);
    snowSpr.zIndex = SNOW_ZINDEX;
    ps.currentStage.add(snowSpr);
    ps.currentStage.refresh();
    snowSpr.scrollFactor.set(1.5, 1.5);
    snowSpr.screenCenter();
    snowSpr.x -= 1200;
    snowSpr.y -= 1100;
    snowSpr.shader = snowShader;
    snowSpr.color = SNOW_BASE_COLOR;
    snowSpr.alpha = SNOW_BASE_ALPHA;

    snowBaseScaleX = snowSpr.scale.x;
    snowBaseScaleY = snowSpr.scale.y;
  }

  function updateSnow(elapsed)
  {
    if (snowShader == null || snowSpr == null) return;

    snowTime = snowTime + elapsed * snowTimeSpeed;
    snowShader.setFloat("iTime", snowTime);

    var z = ps.camGame.zoom;
    if (z < 0.05) z = 0.05;
    var m = (1 / z) * (1 - SNOW_ZOOM_FACTOR) + SNOW_ZOOM_FACTOR;
    snowSpr.scale.set(snowBaseScaleX * m, snowBaseScaleY * m);
  }

  function resetSnow()
  {
    if (snowSpeedTween != null) snowSpeedTween.cancel();
    if (snowAlphaTween != null) snowAlphaTween.cancel();
    if (snowWidthTween != null) snowWidthTween.cancel();
    snowSpeedTween = null;
    snowAlphaTween = null;
    snowWidthTween = null;

    snowTime = 0;
    snowTimeSpeed = 1;
    snowWidth = SNOW_BASE_WIDTH;

    if (snowShader == null || snowSpr == null) return;

    snowShader.setFloat("iTime", 0);
    snowShader.setFloat("iWidth", SNOW_BASE_WIDTH);
    snowShader.setFloat("iSpeed", SNOW_BASE_SPEED);
    snowSpr.alpha = SNOW_BASE_ALPHA;
    snowSpr.color = SNOW_BASE_COLOR;
  }

  function tweenSnowSpeed(target, time)
  {
    if (snowSpeedTween != null) snowSpeedTween.cancel();
    snowSpeedTween = FlxTween.num(snowTimeSpeed, target, time, {ease: FlxEase.sineInOut}, function(v)
    {
      snowTimeSpeed = v;
    });
  }

  function tweenSnowAlpha(from, to, time)
  {
    if (snowAlphaTween != null) snowAlphaTween.cancel();
    snowAlphaTween = FlxTween.num(from, to, time, {ease: FlxEase.sineInOut}, function(v)
    {
      if (snowSpr != null) snowSpr.alpha = v;
    });
  }

  function tweenSnowWidth(target, time)
  {
    if (snowWidthTween != null) snowWidthTween.cancel();
    snowWidthTween = FlxTween.num(snowWidth, target, time, {ease: FlxEase.sineInOut}, function(v)
    {
      snowWidth = v;
      if (snowShader != null) snowShader.setFloat("iWidth", v);
    });
  }

  function snowBeat(beat)
  {
    if (snowShader == null || snowSpr == null) return;

    if (beat == 85)
    {
      snowSpr.alpha = 0;
      snowSpr.color = SNOW_RED_COLOR;
    }
    else if (beat == 86)
    {
      snowShader.setFloat("iSpeed", 0.9);
    }
    else if (beat == 87)
    {
      tweenSnowAlpha(0.0, 1.0, 1.6);
      tweenSnowSpeed(5, 1.6);
      tweenSnowWidth(0.9, 1.6);
    }
    else if (beat == 120)
    {
      tweenSnowSpeed(4.3, 1);
    }
    else if (beat == 152)
    {
      tweenSnowSpeed(3.8, 1);
    }
    else if (beat == 184)
    {
      tweenSnowSpeed(5.7, .3);
    }
    else if (beat == 216)
    {
      tweenSnowSpeed(.4, .3);
      tweenSnowAlpha(1.0, .6, 1);
    }
    else if (beat == 240)
    {
      tweenSnowSpeed(3.2, 3);
      tweenSnowAlpha(.6, 1, 3);
    }
    else if (beat == 264)
    {
      tweenSnowSpeed(.3, 3);
    }
    else if (beat == 280)
    {
      tweenSnowSpeed(5, 3);
    }
    else if (beat == 312)
    {
      tweenSnowSpeed(2.4, 3);
    }
    else if (beat == 344)
    {
      tweenSnowSpeed(7, 4);
    }
  }

  function resetRuntimeState()
  {
    seenCutscene = false;
    playedCutscene = false;
    allowEnd = false;
    chromShader = null;
    chromTween = null;
    chromaValue = 0;
    snowShader = null;
    snowSpr = null;
    snowTime = 0;
    snowTimeSpeed = 1;
    snowWidth = SNOW_BASE_WIDTH;
    snowBaseScaleX = 1;
    snowBaseScaleY = 1;
    snowSpeedTween = null;
    snowAlphaTween = null;
    snowWidthTween = null;
    barUp = null;
    barDown = null;
    barTween = null;
    barVis = 160;
    hintText = null;
    introBlack = null;
    cutsceneSound = null;
    cutsceneBf = null;
    darkLight = null;
    blend2 = null;
    snowman = null;
    ass = [];
    timers = [];
  }

  function getProp(name)
  {
    if (ps == null || ps.currentStage == null) return null;
    return ps.currentStage.getNamedProp(name);
  }

  function getScoreText()
  {
    var st = null;
    try
    {
      st = ps.scoreText;
    }
    catch (e:Dynamic)
    {
      st = null;
    }
    return st;
  }

  function storeHudBase()
  {
    hudStrumY = ps.playerStrumline.y;
    hudBarY = ps.healthBar.y;
    hudBarBgY = ps.healthBarBG.y;
    var st = getScoreText();
    if (st != null) hudScoreY = st.y;
  }

  function applyPlayerStrumlineMode()
  {
    if (AmMlpc.playerStrum())
    {
    ps.playerStrumline.strumlineScale.set(PLAYER_STRUM_SCALE, PLAYER_STRUM_SCALE);
    }
    if (CENTER_PLAYER_STRUMLINE) ps.playerStrumline.x = (FlxG.width - ps.playerStrumline.width) / 2;
  }

  function setIntroCamera()
  {
    if (ps.startTimestamp > 10) return;
    if (ps.currentStage == null) return;

    var bf = ps.currentStage.getBoyfriend();
    if (bf == null) return;

    var camPos = bf.cameraFocusPoint;
    ps.tweenCameraToPosition(camPos.x + 450, camPos.y + 300, 0);
  }

  function styleSubtitles()
  {
    if (ps.subtitles == null) return;

    var members = ps.subtitles.members;
    var i = 0;
    while (i < members.length)
    {
      var m = members[i];
      i = i + 1;
      if (m != null && Std.isOfType(m, FlxText))
      {
        m.font = Paths.font("RuthlessSketch.ttf");
        m.alpha = .8;
        m.size = 26;
      }
    }
  }

  function createHint()
  {
    var keyName = HINT_CONTROL;
    try
    {
      keyName = PlayerSettings.player1.controls.getDialogueNameFromToken(HINT_CONTROL, true);
    }
    catch (e:Dynamic)
    {
      keyName = HINT_CONTROL;
    }

    hintText = new FlxText(0, 0, FlxG.width, ("PRESS <M>" + keyName + "<M> to dodge or attack").toUpperCase(), 32);
    hintText.scrollFactor.set();
    hintText.cameras = [ps.camCutscene];
    hintText.font = Paths.font("Blueprint.ttf");
    hintText.alignment = "center";
    hintText.y = FlxG.height - 65;
    hintText.color = FlxColor.PINK;
    hintText.visible = ps.currentDifficulty == "hard";
    hintText.alpha = 0;

    var marker = new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFD11B36), "<M>");
    hintText.applyMarkup(hintText.text, [marker]);
    ps.add(hintText);
  }

  function makeBlack()
  {
    var b = new FunkinSprite();
    b.makeSolidColor(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.BLACK);
    b.scrollFactor.set(0, 0);
    b.x = -FlxG.width;
    b.y = -FlxG.height;
    b.cameras = [ps.camCutscene];
    ps.add(b);
    return b;
  }

  function fadeOutBlack(b, time, ease)
  {
    FlxTween.tween(b, {alpha: 0}, time, {
      ease: ease,
      onComplete: function(_)
      {
        if (ps != null) ps.remove(b, true);
        b.destroy();
      }
    });
  }

  function tweenAlpha(obj, value, time, ease)
  {
    if (obj == null) return;
    FlxTween.tween(obj, {alpha: value}, time, {ease: ease});
  }

  function later(seconds, fn)
  {
    var t = new FlxTimer();
    t.start(seconds, fn);
    timers[timers.length] = t;
    return t;
  }

  function cancelTimers()
  {
    var i = 0;
    while (i < timers.length)
    {
      var t = timers[i];
      i = i + 1;
      if (t != null) t.cancel();
    }
    timers = [];
  }
}

class TimeBarModule extends Module
{

  var BAR_HEIGHT:Float = 9;

  var BAR_ALPHA:Float = 0.8;

  var BAR_COLOR = 0xFFFFFFFF;

  var BAR_ZINDEX:Int = 900;

  var BAR_OVERSCAN:Float = 2;

  var bar = null;
  var drawHook = null;

  static var MEGA_ALLOWED_STAGES:Array<String> = [
    "mainStageAmTake",
    "serviceEnterance",
    "xMasCityMallAmTake",
    "xMasCityMallAmTakeDark",
    "xMasCityMallNastyAmTake",
	"phoneCallStreet"
  ];

  function isAllowedStage():Bool
  {
    var play = PlayState.instance;
    if (play == null || play.currentStage == null) return false;
    return MEGA_ALLOWED_STAGES.indexOf(play.currentStage.id) != -1;
  }

  public function new()
  {
    super('TimeBarModule', 1000, {state: PlayState});
  }

  override function onStateChangeEnd(event:StateChangeScriptEvent):Void
  {
    super.onStateChangeEnd(event);

    removeDrawHook();
    bar = null;

    if (!Std.isOfType(event.targetState, PlayState)) return;

    var ps = PlayState.instance;
    if (ps == null) return;
    if (!isAllowedStage()) return;

    createBar(ps);
  }

  override function onStateChangeBegin(event:StateChangeScriptEvent):Void
  {
    super.onStateChangeBegin(event);

    removeDrawHook();
    bar = null;
  }

  override function onDestroy(event:ScriptEvent):Void
  {
    super.onDestroy(event);

    removeDrawHook();
    bar = null;
  }

  function createBar(ps)
  {
    bar = new FunkinSprite();
    bar.makeSolidColor(2, 2, BAR_COLOR);
    bar.scrollFactor.set(0, 0);
    bar.cameras = [ps.camHUD];
    bar.alpha = BAR_ALPHA;
    bar.zIndex = BAR_ZINDEX;
    bar.visible = false;

    ps.add(bar);
    ps.refresh();

    drawHook = function()
    {
      onPreDraw();
    };
    FlxG.signals.preDraw.add(drawHook);
  }

  function removeDrawHook()
  {
    if (drawHook == null) return;

    FlxG.signals.preDraw.remove(drawHook);
    drawHook = null;
  }

  function onPreDraw()
  {
    if (bar == null) return;

    var ps = PlayState.instance;

    if (ps == null || FlxG.state != ps || !bar.exists)
    {
      removeDrawHook();
      bar = null;
      return;
    }

    layoutBar(ps.camHUD, getProgress());
  }

  function getProgress()
  {
    var music = FlxG.sound.music;
    if (music == null || music.length <= 0) return 0;

    var pos = Conductor.instance.songPosition - Conductor.instance.combinedOffset;
    var p = pos / music.length;

    if (p < 0) p = 0;
    if (p > 1) p = 1;
    return p;
  }

  function layoutBar(cam, progress)
  {
    if (progress <= 0)
    {
      bar.visible = false;
      return;
    }
    bar.visible = true;

    var z = cam.zoom;
    if (z < 0.05) z = 0.05;

    var cx = cam.width / 2;
    var cy = cam.height / 2;

    var screenLeft = -BAR_OVERSCAN;
    var screenTop = -BAR_OVERSCAN;
    var screenW = cam.width * progress + BAR_OVERSCAN;
    var screenH = BAR_HEIGHT + BAR_OVERSCAN;

    bar.scale.set(screenW / z / bar.frameWidth, screenH / z / bar.frameHeight);
    bar.updateHitbox();
    bar.x = cx + (screenLeft - cx) / z;
    bar.y = cy + (screenTop - cy) / z;
  }
}

class BoyfriendAnimaniaCharacter extends MultiAnimateAtlasCharacter
{
	function new()
	{
		super('bf-animania');
	}

	function onCreate(e)
	{
		super.onCreate(e);
		ignoreExclusionPref.push("singDOWN");
	}

	function onNoteHit(event:HitNoteScriptEvent)
	{
		if (event != null && event.note != null && event.note.kind == "stop bope")
		{
			canPlayOtherAnims = true;
			playAnimation("singDOWN", true, true);
			return;
		}

		if (isBannedKind(event.note.kind))
			return;

		if (event.note.noteData.getMustHitNote() && characterType == CharacterType.BF && !event.eventCanceled)
		{
			if (event.note.holdNoteSprite != null)
				lastHoldFinish = event.note.strumTime + event.note.noteData.length;

			holdTimer = 0;
			switch (event.note.kind)
			{
				case "beatbox":
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'beatbox');
				case "blush":
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'blush');
				case "mom":
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'alt' + (idleSuffix.indexOf("angry") != -1 ? "-angry" : ""));
				case "fresh":
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'fresh');
				case "cheer":
					playAnimation("hey", true, false);
				case "cheer-alt":
					playAnimation("cheer-alt", true, false);
				case "erect-up":
					playAnimation("erect up", true, false);
				default:
					this.playSingAnimation(event.note.noteData.getDirection(), false, idleSuffix.indexOf("angry") != -1 ? "angry" : "");
			}
		}
	}

	function onNoteMiss(event)
	{
		if (isBannedKind(event.note.kind))
			return;

		if (event.note.noteData.getMustHitNote() && characterType == CharacterType.BF && !event.eventCanceled)
		{
			lastHoldFinish = null;
			holdTimer = 0;
			switch (event.note.kind)
			{
				case "mom":
					this.playSingAnimation(event.note.noteData.getDirection(), true, 'alt');
				case "fresh":
					this.playSingAnimation(event.note.noteData.getDirection(), true, 'fresh');
				default:
					this.playSingAnimation(event.note.noteData.getDirection(), true, "");
			}
		}
	}

	var lastHoldFinish:Null<Float> = null;

	function isBannedKind(kind:String):Bool
	{
		var animania = ModuleHandler.getModule("AnimaniaStuff");
		if (animania == null)
			return false;
		return animania.scriptCall("isBannedNoteKind", [kind]) == true;
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

	var coolDeathSprite:FunkinSprite;
	var deathTimerManager:FlxTimerManager;

	override function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reverse:Bool = false):Void
	{
		if (name == "erect up")
		{
			holdTimer = -5;
		}

		if (name == "cheer-alt")
		{
			holdTimer = -12;
		}
		super.playAnimation(name, restart, ignoreOther, reverse);
	}

	override function onAnimationFinished(prefix:String):Void
	{
		switch (prefix)
		{
			case "cheer-alt":
			default:
				super.onAnimationFinished(prefix);
		}

	}
}

class BoyfriendChristmasAnimaniaCharacter extends MultiAnimateAtlasCharacter
{
	function new()
	{
		super('bf-christmas-animania');
	}

	override function onCreate(event:ScriptEvent):Void
	{
		super.onCreate(event);

		GameOverSubState.musicSuffix = '-xmas';
		GameOverSubState.blueBallSuffix = '-xmas';
	}

	var lastHoldFinish:Null<Float> = null;

	function onNoteHit(event:HitNoteScriptEvent)
	{

		if (event.note.noteData.getMustHitNote() && characterType == CharacterType.BF && !event.eventCanceled)
		{
			if (event.note.holdNoteSprite != null)
				lastHoldFinish = event.note.strumTime + event.note.noteData.length;
			switch (event.note.kind)
			{
				case "mom":
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'alt');
					return;

				case "cheer":
					holdTimer = 0;
					playAnimation("hey", true, false);
					return;

				default:
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, "");
					return;
			}
		}
	}

	function onNoteMiss(event)
	{

		if (event.note.noteData.getMustHitNote() && characterType == CharacterType.BF && !event.eventCanceled)
		{
			switch (event.note.kind)
			{
				case "mom":
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), true, 'alt');
					return;

				case "fresh":
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), true, 'both');
					return;

				default:
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), true, "");
					return;
			}
		}

		super.onNoteMiss(event);
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

	override function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reverse:Bool = false):Void
	{
		if (!debug)
		{
			if (name == "firstDeath")
			{
				shader = null;
			}
			else if (name == "deathLoop")
			{
				Conductor.instance.forceBPM(100);
			}
			else if (name == "deathConfirm")
			{
				GameOverSubState.instance.targetCameraZoom *= 1.15;
				FlxTween.tween(FlxG.camera, {zoom: GameOverSubState.instance.targetCameraZoom}, 2, {ease: FlxEase.backOut});
				GameOverSubState.instance.cameraFollowPoint.x += 225;
				GameOverSubState.instance.cameraFollowPoint.y -= 75;
			}
		}
		super.playAnimation(name, restart, ignoreOther, reverse);
	}
}

class DadAnimaniaCharacter extends AnimateAtlasCharacter
{
	function new()
	{
		super('dad-animania');
	}

	override function onCreate(event:ScriptEvent):Void
	{
		super.onCreate(event);
	}

	var lastHoldFinish:Null<Float> = null;

	public override function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reversed:Bool = false):Void
	{
		switch (name)
		{
			case "angy":
				idleSuffix = "-angry";

			case "imok":
				idleSuffix = "";

			default:
				super.playAnimation(name, restart, ignoreOther, reversed);
		}
	}

	function onNoteHit(event:HitNoteScriptEvent)
	{

		if (!event.note.noteData.getMustHitNote() && characterType == CharacterType.DAD && !event.eventCanceled)
		{
			if (event.note.holdNoteSprite != null)
				lastHoldFinish = event.note.strumTime + event.note.noteData.length;
			switch (event.note.kind)
			{
				case "mom":
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'alt');
					return;

				case "beatbox":
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'beatbox');
					return;

				default:
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, idleSuffix.indexOf("angry") != -1 ? "angry" : "");
					return;
			}
		}
		super.onNoteHit(event);
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
}

class DadBeastCharacter extends AnimateAtlasCharacter
{
	function new()
	{
		super('dad-beast');
	}

	override function onCreate(event:ScriptEvent):Void
	{
		super.onCreate(event);
	}

	override function onNoteHit(event:HitNoteScriptEvent):Void
	{
		if (!event.note.noteData.getMustHitNote() && characterType == CharacterType.DAD && !event.eventCanceled)
		{
			holdTimer = 0;
			switch (event.note.kind)
			{
				case "mom":
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'alt');

				default:
					this.playSingAnimation(event.note.noteData.getDirection(), false, "");
			}
			return;
		}

		super.onNoteHit(event);
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

		icon.loadTextureAtlas("icons/beast-dearest", null, icon.getDefaultAtlasSettings());
		icon.antialiasing = true;

		animania.scriptCall("makeAmTakeAnimatedIcon", [icon, !isOpponent]);

		icon.snapToTargetSize();
	}
}

class ParentsChristmasAnimaniaCharacter extends AnimateAtlasCharacter
{
	function new()
	{
		super('parents-christmas-animania');
	}

	override function onCreate(event:ScriptEvent):Void
	{
		super.onCreate(event);
	}

	var lastHoldFinish:Null<Float> = null;

	function onNoteHit(event:HitNoteScriptEvent)
	{
		if (!event.note.noteData.getMustHitNote() && characterType == CharacterType.DAD && !event.eventCanceled)
		{
			if (event.note.holdNoteSprite != null)
				lastHoldFinish = event.note.strumTime + event.note.noteData.length;
			switch (event.note.kind)
			{
				case "mom":
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'alt' + idleSuffix);
					return;

				case "both":
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'both' + idleSuffix);
					return;

				case "parents-miss":
					event.cancel();
					idleSuffix = "-angry";
					shouldAlternate = false;
					return;
				default:
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, idleSuffix.indexOf("angry") != -1 ? "angry" : "");
					return;
			}
		}
	}

	function onNoteMiss(e)
	{
		if (!e.note.noteData.getMustHitNote() && characterType == CharacterType.DAD)
			return;

		super.onNoteMiss(e);
	}

	public override function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reversed:Bool = false):Void
	{
		var doBasic:Bool = false;
		switch (name)
		{
			case "skibidi":
				idleSuffix = "";
				shouldAlternate = true;
				danceEvery = 1;
			case "cocoaSoloLookLeft":
				canPlayOtherAnims = true;
				doBasic = true;
			case "cocoaSoloLookRight":
				doBasic = true;
				canPlayOtherAnims = true;
			default:
				super.playAnimation(name, restart, ignoreOther, reversed);
		}

		if (doBasic)
			super.playAnimation(name, restart, ignoreOther, reversed);
	}

	override function onAnimationFinished(prefix:String):Void
	{
		trace(prefix);
		switch (prefix)
		{
			case "cocoaSolo" | "cocoaSoloLeft":
				trace("я сосу большие яйца <3");

			case "cocoaSoloLookLeft":
				trace("я сосу большие яйца <3 2");
				canPlayOtherAnims = true;
				playAnimation("cocoaSoloLeft", true, true);

			case "cocoaSoloLookRight":
				canPlayOtherAnims = true;
				playAnimation("cocoaSolo", true, true);
				/*new FlxTimer().start(4, () ->
				{
					canPlayOtherAnims = true;
				});*/

			case "singRIGHTmiss":
				super.onAnimationFinished(prefix);

			default:
				super.onAnimationFinished(prefix);
		}
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

}

class GirlfriendAnimaniaCharacter extends AnimateAtlasCharacter
{
	function new()
	{
		super('gf-animania');
	}

	public var altDanceAnim:Bool = FlxG.random.bool(100);

	var awesomeAnims = ["fresh solo"];

	public override function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reversed:Bool = false):Void
	{
		switch (name)
		{
			case "pre-dance":

			case "end-dance":

			case "stop drop dance":
				idleSuffix = "";
				return;
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
				idleSuffix = "";
				dance(true);
				return;

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

class KomiCharacter extends MultiSparrowCharacter
{
	function new()
	{
		super('komi');
	}

	var myIcon:HealthIcon = null;
	var iconIsPlayer:Bool = false;
	var iconIsAlive:Bool = true;
	var iconTimer:Float = 0;
	var iconAnimPostfix:String = "";
	var iconBaseX:Float = 0;
	var iconBaseY:Float = 0;
	var lastIconAnim:String = null;
	var iconOffsets:Dynamic = null;

	var LOSING_THRESHOLD:Float = 0.25 * 2;
	var ICON_POSITION_OFFSET:Float = 26;
	var dirNames:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];

	var lastNoteAnimation:String = null;
	var lastHoldFinish:Null<Float> = null;

	override function onUpdate(event:UpdateScriptEvent):Void
	{
		if (myIcon != null && PlayState.instance != null && PlayState.instance.healthBar != null)
		{
			if (!isDead && iconIsAlive)
			{
				if (iconTimer < 4)
				{
					iconTimer += event.elapsed * 6;
					if (iconTimer > 4) iconTimer = 4;
				}

				holdLoopIcon();
			}

			updateKomiIconState();
			updateKomiIconOffsets();
			updateKomiIconPosition();
		}

		super.onUpdate(event);
	}

	function isMyNote(mustHit:Bool):Bool
	{
		return (mustHit && characterType == CharacterType.BF) || (!mustHit && characterType == CharacterType.DAD);
	}

	function isHoldingNoteNow():Bool
	{
		if (lastNoteAnimation == null || lastHoldFinish == null) return false;
		if (lastHoldFinish < Conductor.instance.songPosition) return false;
		return characterType != CharacterType.BF || isHoldingNote();
	}

	function holdLoopIcon():Void
	{
		if (isHoldingNoteNow() && isSinging() && myIcon.isAnimationFinished())
		{
			iconTimer = 0;
			holdTimer = 0;
			myIcon.playAnimation(lastNoteAnimation + iconAnimPostfix, null, true);
		}
	}

	function updateKomiIconState():Void
	{
		var health:Float = iconIsPlayer ? PlayState.instance.health : Constants.HEALTH_MAX - PlayState.instance.health;

		iconAnimPostfix = (health < LOSING_THRESHOLD) ? "-alt" : "";

		if (iconTimer < 4) return;

		var cur:String = myIcon.getCurrentAnimation();

		if (cur == "idle")
		{
			if (health < LOSING_THRESHOLD) myIcon.playAnimation("toLosing");
		}
		else if (cur == "losing")
		{
			if (health > LOSING_THRESHOLD) myIcon.playAnimation("fromLosing");
		}
		else if (cur == "toLosing")
		{
			if (myIcon.isAnimationFinished()) myIcon.playAnimation("losing", "idle");
		}
		else if (cur == "fromLosing")
		{
			if (myIcon.isAnimationFinished()) myIcon.playAnimation("idle");
		}
		else
		{
			myIcon.playAnimation(iconAnimPostfix != "" ? "losing" : "idle", null, false);
		}
	}

	function updateKomiIconOffsets():Void
	{
		var anim:String = myIcon.getCurrentAnimation();
		if (anim == lastIconAnim) return;
		lastIconAnim = anim;

		var offs:Array<Float> = iconOffsets.get(anim);
		if (offs == null) offs = [0.0, 0.0];

		myIcon.iconOffset.set(iconBaseX + offs[0], iconBaseY + offs[1]);
		myIcon.updateHitbox();
	}

	function updateKomiIconPosition():Void
	{
		var bar = PlayState.instance.healthBar;
		var barPercent:Float = FlxMath.remapToRange(bar.value, 0, 2, 100, 0) * 0.01;

		if (iconIsPlayer) myIcon.x = bar.x + (bar.width * barPercent - ICON_POSITION_OFFSET);
		else myIcon.x = bar.x + (bar.width * barPercent) - (myIcon.width - ICON_POSITION_OFFSET);

		myIcon.y = bar.y - (myIcon.height / 2);
	}

	override function initHealthIcon(isOpponent:Bool):Void
	{
		super.initHealthIcon(isOpponent);

		if (PlayState.instance == null) return;

		var icon = isOpponent ? PlayState.instance.iconP2 : PlayState.instance.iconP1;
		if (icon == null) return;

		myIcon = icon;
		iconIsPlayer = !isOpponent;
		iconIsAlive = true;
		iconTimer = 0;
		iconAnimPostfix = "";
		lastIconAnim = null;

		icon.autoUpdate = false;
		icon.flipX = true;

		icon.animation.addByPrefix("losing", "lose0", 1, true);
		icon.animation.addByPrefix("idle", "basic0", 1, true);

		icon.animation.addByPrefix("toLosing", "basic-to-lose", 24, false);
		icon.animation.addByPrefix("fromLosing", "lose-to-basic", 24, false);

		icon.animation.addByPrefix("singLEFT", "right", 24, false);
		icon.animation.addByPrefix("singRIGHT", "left", 24, false);
		icon.animation.addByPrefix("singUP", "up", 24, false);
		icon.animation.addByPrefix("singDOWN", "down", 24, false);

		icon.animation.addByPrefix("singLEFT-alt", "alt right", 24, false);
		icon.animation.addByPrefix("singRIGHT-alt", "alt left", 24, false);
		icon.animation.addByPrefix("singUP-alt", "alt up", 24, false);
		icon.animation.addByPrefix("singDOWN-alt", "alt down", 24, false);

		icon.playAnimation("idle", null, true);

		iconBaseX = icon.iconOffset.x;
		iconBaseY = icon.iconOffset.y;

		iconOffsets = new StringMap();
		iconOffsets.set("singUP", [0.0, 5.0]);
		iconOffsets.set("singUP-alt", [0.0, 5.0]);
		iconOffsets.set("toLosing", [6.0, 1.0]);
		iconOffsets.set("singLEFT", [-5.0, 0.0]);
		iconOffsets.set("singLEFT-alt", [-5.0, 0.0]);
	}

	override function onDestroy(event:ScriptEvent):Void
	{
		if (myIcon != null)
		{
			myIcon.autoUpdate = true;
			myIcon = null;
		}
		super.onDestroy(event);
	}

	override function onNoteHit(event:HitNoteScriptEvent):Void
	{
		super.onNoteHit(event);
		if (event.eventCanceled) return;

		if (event.note.holdNoteSprite != null && isMyNote(event.note.noteData.getMustHitNote()))
			lastHoldFinish = event.note.strumTime + event.note.noteData.length;
	}

	override function onNoteMiss(event:NoteScriptEvent):Void
	{
		super.onNoteMiss(event);
		if (isMyNote(event.note.noteData.getMustHitNote())) lastHoldFinish = null;
	}

	override function onNoteHoldDrop(event:HoldNoteScriptEvent):Void
	{
		super.onNoteHoldDrop(event);
		if (isMyNote(event.holdNote.noteData.getMustHitNote())) lastHoldFinish = null;
	}

	override function playSingAnimation(dir:NoteDirection, miss:Bool = false, suffix:String = ''):Void
	{
		super.playSingAnimation(dir, miss, suffix);

		lastNoteAnimation = 'sing' + dirNames[Std.int(dir) % 4];

		if (iconIsAlive && myIcon != null)
		{
			iconTimer = 0;
			myIcon.playAnimation(lastNoteAnimation + iconAnimPostfix, null, true);
		}
	}

	override function onBeatHit(event:SongTimeScriptEvent):Void
	{
		super.onBeatHit(event);
		if (PlayState.instance == null) return;

		if (event.beat == 168)
		{
			iconIsAlive = false;
		}
	}
}

class TadanoCharacter extends MultiAnimateAtlasCharacter
{
	function new()
	{
		super('tadano');
	}

	override function onCreate(event:ScriptEvent):Void
	{
		super.onCreate(event);

		GameOverSubState.musicSuffix = '-tadano';
		GameOverSubState.blueBallSuffix = '-tadano';

		PauseSubState.musicSuffix = '-phonecall';
	}

	function isBannedKind(kind:String):Bool
	{
		var animania = ModuleHandler.getModule("AnimaniaStuff");
		if (animania == null)
			return false;
		return animania.scriptCall("isBannedNoteKind", [kind]) == true;
	}

	override function onNoteHit(event:HitNoteScriptEvent):Void
	{
		if (isBannedKind(event.note.kind))
			return;

		if (event.note.noteData.getMustHitNote() && characterType == CharacterType.BF && !event.eventCanceled)
		{
			holdTimer = 0;
			switch (event.note.kind)
			{
				case "mom":
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'alt');
				case "fresh":
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'both');
				default:
					this.playSingAnimation(event.note.noteData.getDirection(), false, idleSuffix.indexOf("alt") != -1 ? "alt" : "");
			}
			return;
		}

		if (!event.note.noteData.getMustHitNote() && characterType == CharacterType.DAD && !event.eventCanceled)
			super.onNoteHit(event);
	}

	override function onNoteMiss(event:NoteScriptEvent):Void
	{
		if (event.note.noteData.getMustHitNote() && characterType == CharacterType.BF && !event.eventCanceled)
		{
			holdTimer = 0;
			switch (event.note.kind)
			{
				case "mom":
					this.playSingAnimation(event.note.noteData.getDirection(), true, 'alt');
				case "fresh":
					this.playSingAnimation(event.note.noteData.getDirection(), true, 'both');
				default:
					this.playSingAnimation(event.note.noteData.getDirection(), true, idleSuffix.indexOf("alt") != -1 ? "alt" : "");
			}
			return;
		}

		super.onNoteMiss(event);
	}

	override function onNoteGhostMiss(event:GhostMissNoteScriptEvent):Void
	{
		super.onNoteGhostMiss(event);

		if (characterType == CharacterType.BF && !event.eventCanceled)
		{
			this.playSingAnimation(event.dir, true, idleSuffix.indexOf("alt") != -1 ? "alt" : "");
		}
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

		var offs = new StringMap();
		offs.set("idle", [0.0, 0.0]);
		offs.set("toLosing", [0.0, 15.0]);
		offs.set("losing", [0.0, -5.0]);

		animania.scriptCall("makeAmTakeAnimatedIcon", [icon, !isOpponent, offs]);
	}

	override function onAnimationFinished(prefix:String):Void
	{
		switch (prefix)
		{
			case "intro":
				super.onAnimationFinished(prefix);
				dance(true);

			default:
				super.onAnimationFinished(prefix);
		}
	}

	override function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reverse:Bool = false):Void
	{
		if (name == "firstDeath")
		{
			setupDeath();
		}
		else if (name == "deathLoop" && !debug)
		{
			var go = GameOverSubState.instance;
			if (go != null)
			{
				FlxTween.tween(go.cameraFollowPoint, {x: go.cameraFollowPoint.x - 450}, 3.5, {ease: FlxEase.sineOut});
			}
			if (coolRetrySprite != null)
			{
				coolRetrySprite.alpha = 1;
				coolRetrySprite.anim.play("start", true);
			}
		}
		else if (name == "deathConfirm" && !debug)
		{
			var go = GameOverSubState.instance;
			if (coolRetrySprite != null)
			{
				coolRetrySprite.anim.play("confirm", true);
			}
			if (go != null)
			{
				FlxTween.cancelTweensOf(go.cameraFollowPoint);
				FlxTween.tween(go.cameraFollowPoint, {y: go.cameraFollowPoint.y - 350}, 3.5, {startDelay: .8, ease: FlxEase.backInOut});
			}
			return;
		}

		super.playAnimation(name, restart, ignoreOther, reverse);
	}

	var coolRetrySprite:FunkinSprite = null;

	function findGameOverBg():FlxSprite
	{
		var go = GameOverSubState.instance;
		var i:Int = 0;
		while (i < go.members.length)
		{
			var m = go.members[i];
			if (m != null && m != this && Std.isOfType(m, FlxSprite) && m.scrollFactor.x == 0 && m.width >= FlxG.width * 2)
				return m;
			i = i + 1;
		}

		var bg = new FunkinSprite().makeSolidColor(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.screenCenter();
		go.insert(0, bg);
		return bg;
	}

	function setupDeath():Void
	{
		if (debug)
			return;

		var ps = PlayState.instance;
		var curvedBar = ModuleHandler.getModule('CurvedHealthBarModule');
		var go = GameOverSubState.instance;
		if (ps == null || go == null)
			return;

		ps.persistentDraw = true;

		var darkBg = findGameOverBg();
		darkBg.alpha = .9;
		FlxTween.tween(darkBg, {alpha: 0.5}, 1, {ease: FlxEase.backOut});

		var goUP:Bool = AmScroll.isDown();
		var dir:Float = goUP ? 1 : -1;

		var hudObjs:Array<Dynamic> = [curvedBar.redBar, curvedBar.greenBar, curvedBar.bg, ps.iconP1, ps.iconP2];
		var i:Int = 0;
		while (i < hudObjs.length)
		{
			var obj = hudObjs[i];
			if (obj != null)
				FlxTween.tween(obj, {y: obj.y - 250 * dir, alpha: 0}, 1.75, {ease: FlxEase.smootherStepIn, startDelay: .25});
			i = i + 1;
		}

		var strumObjs:Array<Dynamic> = [ps.playerStrumline, ps.opponentStrumline];
		i = 0;
		while (i < strumObjs.length)
		{
			var obj = strumObjs[i];
			if (obj != null)
				FlxTween.tween(obj, {y: obj.y + 250 * dir, alpha: 0}, 1.75, {ease: FlxEase.smootherStepIn, startDelay: .5});
			i = i + 1;
		}

		FlxTween.tween(darkBg, {alpha: 0.75}, 1.25, {ease: FlxEase.backOut, startDelay: 1});

		coolRetrySprite = new FunkinSprite(this.x - 850, this.y + 450, Paths.animateAtlas("characters/phonecall/tadano-phone-death-text", "shared"));
		coolRetrySprite.anim.addByFrameLabel("start", "start", 24, false);
		coolRetrySprite.anim.addByFrameLabel("loop", "loop", 24, true);
		coolRetrySprite.anim.addByFrameLabel("confirm", "confirm", 24, false);
		coolRetrySprite.anim.onFinish.add(function(n:String):Void
		{
			if (n == "start") coolRetrySprite.anim.play("loop", true);
		});
		go.add(coolRetrySprite);
		coolRetrySprite.alpha = 0.0001;
	}
}

class KomiStandCharacter extends MultiSparrowCharacter
{
	function new()
	{
		super('komi-stand');
	}

	override function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reverse:Bool = false):Void
	{
		super.playAnimation(name, restart, ignoreOther, reverse);
		if (name == "endConv")
			this.danceEvery = 99999;
	}

	var myIcon:HealthIcon = null;
	var iconIsPlayer:Bool = false;
	var iconBaseX:Float = 0;
	var iconBaseY:Float = 0;
	var lastIconAnim:String = null;
	var iconOffsets:Dynamic = null;

	var LOSING_THRESHOLD:Float = 0.25 * 2;
	var ICON_POSITION_OFFSET:Float = 26;

	override function onUpdate(event:UpdateScriptEvent):Void
	{
		if (myIcon != null && PlayState.instance != null && PlayState.instance.healthBar != null)
		{
			updateStandIconState();
			updateStandIconOffsets();
			updateStandIconPosition();
		}

		super.onUpdate(event);
	}

	function updateStandIconState():Void
	{
		var health:Float = iconIsPlayer ? PlayState.instance.health : Constants.HEALTH_MAX - PlayState.instance.health;
		var cur:String = myIcon.getCurrentAnimation();

		if (cur == "idle")
		{
			if (health < LOSING_THRESHOLD) myIcon.playAnimation("toLosing");
		}
		else if (cur == "losing")
		{
			if (health > LOSING_THRESHOLD) myIcon.playAnimation("fromLosing");
		}
		else if (cur == "toLosing")
		{
			if (myIcon.isAnimationFinished()) myIcon.playAnimation("losing", "idle");
		}
		else if (cur == "fromLosing")
		{
			if (myIcon.isAnimationFinished()) myIcon.playAnimation("idle");
		}
		else
		{
			myIcon.playAnimation("idle", null, false);
		}
	}

	function updateStandIconOffsets():Void
	{
		var anim:String = myIcon.getCurrentAnimation();
		if (anim == lastIconAnim) return;
		lastIconAnim = anim;

		var offs:Array<Float> = iconOffsets.get(anim);
		if (offs == null) offs = [0.0, 0.0];

		myIcon.iconOffset.set(iconBaseX + offs[0], iconBaseY + offs[1]);
		myIcon.updateHitbox();
	}

	function updateStandIconPosition():Void
	{
		var bar = PlayState.instance.healthBar;
		var barPercent:Float = FlxMath.remapToRange(bar.value, 0, 2, 100, 0) * 0.01;

		if (iconIsPlayer) myIcon.x = bar.x + (bar.width * barPercent - ICON_POSITION_OFFSET);
		else myIcon.x = bar.x + (bar.width * barPercent) - (myIcon.width - ICON_POSITION_OFFSET);

		myIcon.y = bar.y - (myIcon.height / 2);
	}

	override function initHealthIcon(isOpponent:Bool):Void
	{
		super.initHealthIcon(isOpponent);

		if (PlayState.instance == null) return;

		var icon = isOpponent ? PlayState.instance.iconP2 : PlayState.instance.iconP1;
		if (icon == null) return;

		myIcon = icon;
		iconIsPlayer = !isOpponent;
		lastIconAnim = null;

		icon.autoUpdate = false;

		icon.animation.addByPrefix("losing", "lose0", 1, true);
		icon.animation.addByPrefix("idle", "basic0", 1, true);

		icon.animation.addByPrefix("toLosing", "basic-to-lose", 24, false);
		icon.animation.addByPrefix("fromLosing", "lose-to-basic", 24, false);
		icon.playAnimation("idle", null, true);

		iconBaseX = icon.iconOffset.x;
		iconBaseY = icon.iconOffset.y;

		iconOffsets = new StringMap();
		iconOffsets.set("toLosing", [6.0, 1.0]);
	}

	override function onDestroy(event:ScriptEvent):Void
	{
		if (myIcon != null)
		{
			myIcon.autoUpdate = true;
			myIcon = null;
		}
		super.onDestroy(event);
	}
}

class TadanoStandCharacter extends MultiSparrowCharacter
{
	function new()
	{
		super('tadano-stand');
	}

	override function onCreate(event:ScriptEvent):Void
	{
		super.onCreate(event);

		GameOverSubState.musicSuffix = '-tadano';
		GameOverSubState.blueBallSuffix = '-tadano';

		PauseSubState.musicSuffix = '-phonecall';
	}

	var BANNED_FALLBACK:Array<String> = ["noAnimation", "noanim", "parents-miss", "solotime"];

	function isBannedKind(kind:String):Bool
	{
		if (kind == null) return false;

		var am = ModuleHandler.getModule("AnimaniaModule");
		if (am != null)
		{
			var list = am.scriptGet("BANNED_NOTEKINDS");
			if (list != null) return list.indexOf(kind) != -1;
		}
		return BANNED_FALLBACK.indexOf(kind) != -1;
	}

	override function onNoteHit(event:HitNoteScriptEvent):Void
	{
		if (isBannedKind(event.note.kind))
			return;

		if (event.note.noteData.getMustHitNote() && characterType == CharacterType.BF && !event.eventCanceled)
		{
			holdTimer = 0;
			switch (event.note.kind)
			{
				case "mom":
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'alt');
				case "fresh":
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'both');
				default:
					this.playSingAnimation(event.note.noteData.getDirection(), false, idleSuffix.indexOf("alt") != -1 ? "alt" : "");
			}
			return;
		}

		if (!event.note.noteData.getMustHitNote() && characterType == CharacterType.DAD && !event.eventCanceled)
			super.onNoteHit(event);
	}

	override function onNoteMiss(event:NoteScriptEvent):Void
	{
		if (isBannedKind(event.note.kind))
			return;

		if (event.note.noteData.getMustHitNote() && characterType == CharacterType.BF && !event.eventCanceled)
		{
			holdTimer = 0;
			switch (event.note.kind)
			{
				case "mom":
					this.playSingAnimation(event.note.noteData.getDirection(), true, 'alt');
				case "fresh":
					this.playSingAnimation(event.note.noteData.getDirection(), true, 'both');
				default:
					this.playSingAnimation(event.note.noteData.getDirection(), true, idleSuffix.indexOf("alt") != -1 ? "alt" : "");
			}
			return;
		}

		super.onNoteMiss(event);
	}

	override function initHealthIcon(isOpponent:Bool):Void
	{
		super.initHealthIcon(isOpponent);

		if (PlayState.instance == null) return;

		var icon = isOpponent ? PlayState.instance.iconP2 : PlayState.instance.iconP1;
		if (icon == null) return;

		var animania = ModuleHandler.getModule("AnimaniaStuff");
		if (animania == null) return;

		var offs = new StringMap();
		offs.set("idle", [0.0, 0.0]);
		offs.set("toLosing", [0.0, 5.0]);
		offs.set("losing", [0.0, -5.0]);

		animania.scriptCall("makeAmTakeAnimatedIcon", [icon, !isOpponent, offs]);
	}

	var deathActive:Bool = false;
	var coolRetrySprite:FunkinSprite = null;
	var retryAnim:String = "";
	var deathTimerManager:FlxTimerManager = null;

	var leftBlack:FlxSprite = null;
	var rightBlack:FlxSprite = null;
	var blackGradient:FlxSprite = null;
	var leftPos:Dynamic = null;
	var rightPos:Dynamic = null;
	var gradPos:Dynamic = null;

	var deathKomi:BaseCharacter = null;
	var savedHud:Array<Dynamic> = [];
	var savedCamFilters:Dynamic = null;
	var bpmForced:Bool = false;

	override function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reverse:Bool = false):Void
	{
		if (name == "firstDeath")
		{
			createDeathSprites();
		}
		else if (name == "deathConfirm")
		{
			if (confirmDeathSprites()) return;
		}

		if (name == "deathLoop")
			return;

		super.playAnimation(name, restart, ignoreOther, reverse);
		if (name == "endAnimation")
			this.danceEvery = 99999;
	}

	function findGameOverBg():FlxSprite
	{
		var go = GameOverSubState.instance;
		var i:Int = 0;
		while (i < go.members.length)
		{
			var m = go.members[i];
			if (m != null && m != this && Std.isOfType(m, FlxSprite) && m.scrollFactor.x == 0 && m.width >= FlxG.width * 2)
				return m;
			i = i + 1;
		}

		var bg = new FunkinSprite().makeSolidColor(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.screenCenter();
		go.insert(0, bg);
		return bg;
	}

	function playRetryAnim(name:String):Void
	{
		if (coolRetrySprite == null) return;
		retryAnim = name;
		coolRetrySprite.anim.play(name, true);
	}

	function pinToScreen(spr:FlxSprite, sx:Float, sy:Float, z:Float):Void
	{
		var inv:Float = 1 / z;
		var cw:Float = FlxG.camera.width * 0.5;
		var ch:Float = FlxG.camera.height * 0.5;

		spr.scale.set(inv, inv);
		spr.x = ((sx + spr.width * 0.5) - cw) * inv + cw - spr.width * 0.5;
		spr.y = ((sy + spr.height * 0.5) - ch) * inv + ch - spr.height * 0.5;
	}

	function pinFixedSprites():Void
	{
		var z:Float = FlxG.camera.zoom;
		if (z <= 0) return;

		if (leftBlack != null && leftPos != null) pinToScreen(leftBlack, leftPos.x, 0, z);
		if (rightBlack != null && rightPos != null) pinToScreen(rightBlack, rightPos.x, 0, z);
		if (blackGradient != null && gradPos != null) pinToScreen(blackGradient, 0, gradPos.y, z);
	}

	override function onUpdate(event:UpdateScriptEvent):Void
	{
		super.onUpdate(event);

		if (deathActive) pinFixedSprites();
	}

	function createDeathSprites():Void
	{
		var ps = PlayState.instance;
		var go = GameOverSubState.instance;
		if (ps == null || go == null) return;

		deathActive = true;

		deathTimerManager = new FlxTimerManager();
		go.add(deathTimerManager);

		savedCamFilters = FlxG.camera.filters;
		FlxG.camera.filters = ps.camHUD.filters;
		go.targetCameraZoom *= FlxG.camera.zoom / 0.65;

		ps.persistentDraw = true;

		var darkBg:FlxSprite = findGameOverBg();
		darkBg.alpha = 0;

		leftBlack = new FunkinSprite().makeSolidColor(400, FlxG.height, FlxColor.BLACK);
		leftBlack.scrollFactor.set();
		leftPos = {x: -400.0};
		FlxTween.tween(leftPos, {x: -100.0}, 6, {ease: FlxEase.sineInOut});
		go.add(leftBlack);

		rightBlack = new FunkinSprite().makeSolidColor(400, FlxG.height, FlxColor.BLACK);
		rightBlack.scrollFactor.set();
		rightPos = {x: FlxG.width + 0.0};
		FlxTween.tween(rightPos, {x: FlxG.width - 300.0}, 6, {ease: FlxEase.sineInOut});
		go.add(rightBlack);

		pinFixedSprites();

		go.remove(this);
		go.add(this);

		var stage = ps.currentStage;
		var komi:BaseCharacter = (stage != null) ? stage.getDad() : null;
		if (komi != null)
		{
			deathKomi = komi;
			go.add(komi);
			komi.danceEvery = 9999;
			komi.playAnimation("gameOver", true, true, false);
			komi.isDead = true;
		}

		var goUP:Bool = AmScroll.isDown();
		var dir:Float = goUP ? 1 : -1;

		savedHud = [];
		var hudObjs:Array<Dynamic> = [ps.healthBar, ps.iconP1, ps.iconP2];
		for (obj in hudObjs)
		{
			if (obj == null) continue;
			savedHud.push({obj: obj, y: obj.y, alpha: obj.alpha});
			FlxTween.tween(obj, {y: obj.y - 250 * dir, alpha: 0}, 1.75, {ease: FlxEase.smootherStepIn, startDelay: 0});
		}

		var strumObjs:Array<Dynamic> = [ps.playerStrumline, ps.opponentStrumline];
		for (obj in strumObjs)
		{
			if (obj == null) continue;
			savedHud.push({obj: obj, y: obj.y, alpha: obj.alpha});
			FlxTween.tween(obj, {y: obj.y + 250 * dir, alpha: 0}, 1.75, {ease: FlxEase.smootherStepIn, startDelay: .15});
		}

		FlxTween.tween(darkBg, {alpha: 0.75}, 1.25, {ease: FlxEase.backOut, startDelay: .5});

		coolRetrySprite = new FunkinSprite(this.x + this.offset.x + 240, this.y + this.offset.y,
			Paths.animateAtlas("characters/phonecall/tadano-phone-stand-death-text", "shared"));
		coolRetrySprite.anim.addByFrameLabel("start", "start", 24, false);
		coolRetrySprite.anim.addByFrameLabel("loop", "loop", 24, false);
		coolRetrySprite.anim.addByFrameLabel("confirm", "confirm", 24, false);
		coolRetrySprite.anim.onFinish.add(function(n:String):Void
		{
			if (n == "start") playRetryAnim("loop");
		});
		coolRetrySprite.applyStageMatrix = true;
		coolRetrySprite.alpha = 0.00001;

		new FlxTimer(deathTimerManager).start(.25, function(tmr:FlxTimer):Void
		{
			var go2 = GameOverSubState.instance;
			if (go2 == null || coolRetrySprite == null) return;

			coolRetrySprite.alpha = 1;
			playRetryAnim("start");

			if (go2.isEnding) return;

			go2.startDeathMusic(0, false);
			Conductor.instance.forceBPM(112);
			bpmForced = true;

			var music = go2.gameOverMusic;
			if (music != null) music.fadeIn(12, 0, 1);
		});

		go.add(coolRetrySprite);

		var prevClose = go.closeCallback;
		go.closeCallback = function():Void
		{
			cleanupDeath();
			if (prevClose != null) prevClose();
		};
	}

	function confirmDeathSprites():Bool
	{
		var go = GameOverSubState.instance;
		if (!deathActive || go == null) return false;

		if (deathTimerManager != null) deathTimerManager.completeAll();
		if (coolRetrySprite != null)
		{
			coolRetrySprite.anim.onFinish.removeAll();
			playRetryAnim("confirm");
		}

		FlxTween.tween(go.cameraFollowPoint, {y: go.cameraFollowPoint.y - 350}, 3.5, {startDelay: .2, ease: FlxEase.elasticInOut});

		FlxTween.cancelTweensOf(leftPos, ["x"]);
		FlxTween.cancelTweensOf(rightPos, ["x"]);
		FlxTween.tween(leftPos, {x: -300.0}, 3.5, {ease: FlxEase.backInOut});
		FlxTween.tween(rightPos, {x: FlxG.width - 100.0}, 3.5, {ease: FlxEase.backInOut});

		blackGradient = FlxGradient.createGradientFlxSprite(FlxG.width, Std.int(FlxG.height * 2.25), [FlxColor.BLACK, FlxColor.BLACK, FlxColor.TRANSPARENT]);
		blackGradient.scrollFactor.set();
		gradPos = {y: -(FlxG.height * 2.0)};
		FlxTween.tween(gradPos, {y: 0.0}, 3.5, {ease: FlxEase.backIn});
		go.add(blackGradient);
		pinFixedSprites();

		return true;
	}

	function cleanupDeath():Void
	{
		if (!deathActive) return;
		deathActive = false;

		var go = GameOverSubState.instance;

		if (deathKomi != null)
		{
			if (go != null) go.remove(deathKomi, true);
			deathKomi.isDead = false;
			deathKomi = null;
		}

		for (entry in savedHud)
		{
			FlxTween.cancelTweensOf(entry.obj);
			entry.obj.y = entry.y;
			entry.obj.alpha = entry.alpha;
		}
		savedHud = [];

		if (leftPos != null) FlxTween.cancelTweensOf(leftPos);
		if (rightPos != null) FlxTween.cancelTweensOf(rightPos);
		if (gradPos != null) FlxTween.cancelTweensOf(gradPos);
		leftPos = null;
		rightPos = null;
		gradPos = null;

		leftBlack = null;
		rightBlack = null;
		blackGradient = null;
		coolRetrySprite = null;
		deathTimerManager = null;

		FlxG.camera.filters = savedCamFilters;
		savedCamFilters = null;

		if (bpmForced)
		{
			Conductor.instance.forceBPM(null);
			bpmForced = false;
		}
	}

	override function onBeatHit(event:SongTimeScriptEvent):Void
	{
		super.onBeatHit(event);

		var gameOver = GameOverSubState.instance;
		if (gameOver != null && event.beat % 2 == 0)
		{
			FlxG.camera.zoom += 0.0075;
			if (PlayState.instance.isPlayerDying && coolRetrySprite != null && retryAnim == "loop")
				playRetryAnim("loop");
		}
	}

	override function onDestroy(event:ScriptEvent):Void
	{
		if (bpmForced)
		{
			Conductor.instance.forceBPM(null);
			bpmForced = false;
		}
		super.onDestroy(event);
	}
}

class SoloTimeNoteKind extends NoteKind
{
	function new()
	{
		super("solotime", "SoloTime Note", "solotime", []);
	}

	var soloType = NoteStyleRegistry.instance.fetchEntry("solotime");

	override function onNoteHit(event:HitNoteScriptEvent)
	{
		if (PlayState.instance != null)
			PlayState.instance.songScore += 800;
		if (event.doesNotesplash)
			createCustomSplash(event.note);
		event.doesNotesplash = false;

    event.stopPropagation();

		super.onNoteHit(event);
	}

	override function onNoteMiss(event)
	{
		event.cancel();
		return;
	}

	function createCustomSplash(note)
	{
		var splash = constructNoteSplash(note);
		if (splash != null)
		{
			var strumline = PlayState.instance.playerStrumline;
			var receptor = strumline.strumlineNotes.members[note.noteData.getDirection()];

			splash.scale.set(strumline.strumlineScale.x, strumline.strumlineScale.y);
			splash.updateHitbox();

			splash.x = (receptor.x + receptor.width / 2) - splash.width / 2 - soloType.getSplashOffsets()[0] * strumline.strumlineScale.x;
			splash.y = (receptor.y + receptor.height / 2) - splash.height / 2 - soloType.getSplashOffsets()[1] * strumline.strumlineScale.y;
		}
	}

	function constructNoteSplash(note):NoteSplash
	{
		var result = new NoteSplash(soloType);
		result.zIndex = 355;
		result.play(note.noteData.getDirection());
		PlayState.instance.playerStrumline.add(result);
		return result;
	}

	var timeLeft:Float = 0;
	var appearTime:Float = 500;

	override function onUpdate(event:UpdateScriptEvent)
	{
		for (note in getNotes())
		{
			note.alpha = (Math.min(Math.max(1 - ((note.strumTime - Conductor.instance.songPosition) / appearTime), 0), 1) * 3) - .25;

			if (note.hasBeenHit || note.hasMissed) continue;
    }

		super.onUpdate(event);
	}

	override function onNoteIncoming(event:NoteScriptEvent)
	{
		event.note.alpha *= .75;
		super.onNoteIncoming(event);
	}
}

class NoAnimationNoteKind extends NoteKind
{
  function new()
  {
    super("noanimation", "no animation note", null, []);
  }

  override function onNoteHit(event:HitNoteScriptEvent)
  {
    event.stopPropagation();

    super.onNoteHit(event);
  }
}

class FuckUpNoteKind extends NoteKind
{
	function new()
	{
		super("Fuck Up", "Fuck Up", "fuckup", [
			{
				name: "Custom Anim",
				description: "Custom Anim Name",
				type: "String",
				data: {
					defaultValue: ""
				}
			},
			{
				name: "valMin",
				description: "MinRandomTime",
				type: "Float",
				data: {
					min: -0.3,
					max: 0.3,
					step: 0.01,
					precision: 2,
					defaultValue: 0.1
				}
			},
			{
				name: "valMax",
				description: "MaxRandomTime",
				type: "Float",
				data: {
					min: -0.3,
					max: 0.3,
					step: 0.01,
					precision: 2,
					defaultValue: 0.2
				}
			},
			{
				name: "holdTimer",
				description: "hold Timer",
				type: "Float",
				data: {
					min: 0.0,
					max: 12,
					step: 0.1,
					precision: 2,
					defaultValue: 0
				}
			},
			{
				name: "conOrPress",
				description: "Confirm or Press",
				type: "Int",
				data: {
					min: 0,
					max: 1,
					step: 1,
					precision: 0,
					defaultValue: 1
				}
			},
			{
				name: "sex",
				description: "Reddit Mode",
				type: "Bool",
				data: {
					defaultValue: false
				}
			}
		]);
	}

	override function onNoteHit(event:NoteScriptEvent)
	{
		event.cancel();
		super.onNoteHit(event);
	}

	function playForcedAnimRandom()
	{
	}

	override function onNoteMiss(event)
	{
		super.onNoteMiss(event);
	}

	override function onUpdate(event:UpdateScriptEvent)
	{
		super.onUpdate(event);
	}

	override function onNoteIncoming(event:NoteScriptEvent)
	{
		FlxTimer.wait(((event.note.strumTime - Conductor.instance.songPosition) / 1000)
			- FlxG.random.float(event.note.getParam("valMin") ?? 0.1, event.note.getParam("valMax") ?? 0.2),
			() ->
			{
				var pPress:Bool = ((event.note.getParam("conOrPress") ?? 1) == 1);

				if (!event.note.noteData.getMustHitNote())
					PlayState.instance.opponentStrumline.hitNote(event.note, false, pPress);
				else if (event.note.noteData.getMustHitNote())
					PlayState.instance.playerStrumline.hitNote(event.note, false, pPress);

				var customAnim:String = event.note.getParam("Custom Anim");
				if (customAnim != null && customAnim.trim() != "")
				{
					var char = PlayState.instance?.currentStage?.getDad();
					if (event.note.noteData.getMustHitNote())
						char = PlayState.instance?.currentStage?.getBoyfriend();

					this.noanim = true;
					if (PlayState.instance != null
						&& PlayState.instance.currentStage != null
						&& PlayState.instance.currentStage.getDad() != null)
					{
						char?.canPlayOtherAnims = true;
						char?.playAnimation(customAnim, true, true);
						char?.holdTimer = -event.note.getParam("holdTimer") ?? 0;
					}
				}
			});
		var customAnim:String = event.note.getParam("Custom Anim");
		if (customAnim != null && customAnim.trim() != "")
		{
			this.noanim = true;
		}

		if (event.note.noteData.getMustHitNote())
			event.note.hasBeenHit = true;
		super.onNoteIncoming(event);
	}
}

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

class RimLight
{
	public var shader:DropShadowShader;

	public var color(default, set):Int = 0xFFB5FBFF;
	public var strength(default, set):Float = 0.6;
	public var threshold(default, set):Float = 0;

	public var fullThreshold:Float = 0.1;

	var fade:FlxTween = null;
	var attached = null;

	public function new()
	{
		shader = new DropShadowShader();
		shader.setAdjustColor(0, 0, 0, 0);
		shader.angle = 90;
		shader.distance = 20;
		shader.strength = 1;
		shader.threshold = 0.1;
		apply();
	}

	function apply():Void
	{
		if (shader == null)
			return;

		var k = Math.max(0, Math.min(1, threshold / fullThreshold)) * strength;
		var r = Std.int(((color >> 16) & 0xFF) * k);
		var g = Std.int(((color >> 8) & 0xFF) * k);
		var b = Std.int((color & 0xFF) * k);
		shader.color = 0xFF000000 | (r << 16) | (g << 8) | b;
	}

	function set_color(v:Int):Int
	{
		color = v;
		apply();
		return v;
	}

	function set_strength(v:Float):Float
	{
		strength = v;
		apply();
		return v;
	}

	function set_threshold(v:Float):Float
	{
		threshold = v;
		apply();
		return v;
	}

	public function fadeThreshold(to:Float, time:Float, ease):Void
	{
		stopFade();
		fade = FlxTween.num(threshold, to, time, {ease: ease}, function(v:Float)
		{
			threshold = v;
		});
	}

	public function stopFade():Void
	{
		if (fade != null)
		{
			fade.cancel();
			fade = null;
		}
	}

	public function attach(character):Void
	{
		if (character == null || attached == character)
			return;

		attached = character;

		var animated:Bool = false;
		try
		{
			animated = character.isAnimate;
		}
		catch (err:Dynamic)
		{
		}

		try
		{
			shader.attachedSprite = character;

			if (!animated)
				character.animation.onFrameChange.add(function(name, frameNumber, frameIndex)
				{
					shader.onAttachedFrame(name, frameNumber, frameIndex);
				});
		}
		catch (err:Dynamic)
		{
			trace('[RimLight] no se pudo enlazar el sprite: ' + err);
		}

		character.shader = shader;
	}

	public function detach():Void
	{
		stopFade();

		if (attached != null)
		{
			attached.shader = null;
			attached = null;
		}
	}
}

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

class XMasCityHallAmTakeStage extends ScriptedStage
{
	function new()
	{
		super('xMasCityMallAmTake');
	}

	var railBoppers = [];

	function onCreate(e)
	{
		super.onCreate(e);

		PauseSubState.musicSuffix = '-amtake5';
	}

	var leftTV;
	var rightTV;

	var sshh = "
#pragma header

uniform float uTime;
uniform vec2 uResolution;

uniform float uDensity;
uniform float uFlakeSize;
uniform float uFallSpeed;  
uniform float uWindStrength; 
uniform float uTwinkle;
uniform float uOpacity;   

void main()
{
    vec2 fragCoord = openfl_TextureCoordv.xy * uResolution;

    float snow = 0.0;
    float random = fract(sin(dot(fragCoord.xy, vec2(12.9898,78.233))) * 43758.5453);

    for (int k = 0; k < 6; k++) {
        for (int j = 0; j < 4; j++) {
            int i = 1 + j * 3;
            float cellSize = 2.0 + (float(i) * 3.0);
            float downSpeed = -(0.3 * uFallSpeed) - (sin(uTime*0.4 + float(k+i*20)) + 1.0) * 0.00008 * uFallSpeed;

            vec2 uv = (fragCoord.xy / uResolution.x)
                + vec2(0.01 * uWindStrength * sin((uTime + float(k*6185)) * 0.6 + float(i)) * (5.0/float(i)),
                       downSpeed * (uTime + float(k*1352)) * (1.0/float(i)));

            vec2 uvStep = (ceil((uv) * cellSize - vec2(0.5,0.5)) / cellSize);

            float x = fract(sin(dot(uvStep.xy, vec2(12.9898+float(k)*12.0, 78.233+float(k)*315.156))) * 43758.5453 + float(k)*12.0) - 0.5;
            float y = fract(sin(dot(uvStep.xy, vec2(62.2364+float(k)*23.0, 94.674+float(k)*95.0))) * 62159.8432 + float(k)*12.0) - 0.5;

            float randomMagnitude1 = sin(uTime*2.5) * 0.7 * uTwinkle / cellSize;
            float randomMagnitude2 = cos(uTime*2.5) * 0.7 * uTwinkle / cellSize;

            float d = 5.0 * distance((uvStep.xy + vec2(x*sin(y), y)*randomMagnitude1 + vec2(y, x)*randomMagnitude2), uv.xy);

            float omiVal = fract(sin(dot(uvStep.xy, vec2(32.4691,94.615))) * 31572.1684);

            if (omiVal < uDensity) {
                float newd = (x+1.0) * 0.4 * uFlakeSize * clamp(1.9 - d*(15.0+(x*6.3))*(cellSize/1.4), 0.0, 1.0);
                snow += newd;
            }
        }
    }
    vec4 texColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
    float alpha = clamp(snow + random*0.01, 0.0, 1.0) * texColor.a * uOpacity;
    vec3 flakeColor = texColor.rgb;

    gl_FragColor = vec4(flakeColor * alpha, alpha);
}";

	var snowShader = null;
	var snowSpr = null;
	var snowTime:Float = 0;

	var _lowQualityProps = ['ceiling', 'upFreaks', 'rail-guys-far', 'goku', 'rail-guys-bobby', 'rail-guys-left', 'rail-guys-miku', 'rail-guys-monster', 'rail-guys-right', 'candy', 'alien_ship', 'tree-crushers', 'meat-boy', 'c-toy-1', 'c-toy-2'];

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

	function buildStage()
	{
		var play = PlayState.instance;
		if (play == null)
			return;

		railBoppers = [];
		super.buildStage();

		if (Save.instance.modOptions["lowQuality"])
		{
			removeLowQualityProps();
		}

		for (dataProp in _data.props)
		{
			final prop = getNamedProp(dataProp.name);
			if (prop == null)
				continue;

			if (dataProp.name.indexOf('rail-guys-') != -1)
				railBoppers.push(prop);
		}

		if (!Save.instance.modOptions["lowQuality"])
		{
		leftTV = new FunkinSprite(-1800, -690);
    leftTV.loadTextureAtlas("stages/xMassCityMall/tvl", "shared", {cacheOnLoad: true});
    leftTV.zIndex = 70;
    leftTV.scrollFactor.set(0.875, 0.875);
    leftTV.anim.addByFrameLabel("noise", "noise", 24, false);
    leftTV.anim.onFinish.add(name -> if (name == "noise")
    {
      if (FlxG.random.bool(15))
        leftTV.anim.play("OOGA BOOGA", true);
      else
        leftTV.anim.play(FlxG.random.int(0, 5), true);
    }
    else if (name == "OOGA BOOGA") leftTV.anim.play("noise", true));
    leftTV.anim.addByFrameLabel("0", "f1", 24);
    leftTV.anim.addByFrameLabel("1", "f2", 24);
    leftTV.anim.addByFrameLabel("2", "f3", 24);
    leftTV.anim.addByFrameLabel("3", "f4", 24);
    leftTV.anim.addByFrameLabel("4", "f5", 24);
    leftTV.anim.addByFrameLabel("5", "f6", 24);
    leftTV.anim.addByFrameLabelIndices("OOGA BOOGA", "OOGA BOOGA", [0, 0, 0, 0], 24, false);
    leftTV.anim.play("OOGA BOOGA", true);
    leftTV.flipX = true;
    add(leftTV);

    rightTV = new FunkinSprite(980, -690);
    rightTV.loadTextureAtlas("stages/xMassCityMall/tvr", "shared", {cacheOnLoad: true});
    rightTV.zIndex = 70;
    rightTV.scrollFactor.set(0.875, 0.875);
    rightTV.anim.addByFrameLabel("noise", "noise", 24, false);
    rightTV.anim.onFinish.add(name -> if (name == "noise") rightTV.anim.play(FlxG.random.int(0, 6), true));
    rightTV.anim.addByFrameLabel("0", "f1", 24);
    rightTV.anim.addByFrameLabel("1", "f2", 24);
    rightTV.anim.addByFrameLabel("2", "f3", 24);
    rightTV.anim.addByFrameLabel("3", "f4", 24);
    rightTV.anim.addByFrameLabel("4", "f5", 24);
    rightTV.anim.addByFrameLabel("5", "f6", 24);
    rightTV.anim.addByFrameLabel("6", "f7", 24);
    rightTV.anim.play("noise", true);
    add(rightTV);
		}

		if (Save.instance.modOptions["shaders"])
		{
		snowShader = new FlxRuntimeShader(sshh);
		snowShader.setFloat("uTime", 0);

		snowSpr = new FunkinSprite();
		snowSpr.makeSolidColor(Std.int(FlxG.width * 3.5), Std.int(FlxG.height * 3.5), FlxColor.WHITE);
		snowSpr.zIndex = 395;
		add(snowSpr);
		refresh();
		snowSpr.scrollFactor.set(1.2, 1.2);
		snowSpr.screenCenter();
		snowSpr.shader = snowShader;

		snowShader.setFloatArray("uResolution", [snowSpr.width, snowSpr.height]);

		snowShader.setFloat("uDensity", 0.175);
		snowShader.setFloat("uFlakeSize", 2.0);
		snowShader.setFloat("uFallSpeed", 0.75);
		snowShader.setFloat("uWindStrength", 2.0);
		snowShader.setFloat("uTwinkle", 0.9);
		snowShader.setFloat("uOpacity", 0.9);
		}

		refresh();
	}

	function onUpdate(event)
	{
		super.onUpdate(event);

		if (snowShader != null)
			snowShader.setFloat("uTime", snowTime += event.elapsed);
	}

	var boppersIdle:Int = 2;

	function onBeatHit(event)
	{
		super.onBeatHit(event);

    if (!Save.instance.modOptions["lowQuality"])
    {
      if (FlxG.random.bool(10))
        leftTV.anim.play("noise", true);

      if (FlxG.random.bool(10))
        rightTV.anim.play("noise", true);

      if (event.beat % boppersIdle == 0)
        boppersBop();
    }

		var play = PlayState.instance;
		if (play == null || play.currentSong == null || play.currentSong.id != "cocoa-animania" || play.isPlayerDying)
			return;

		if (event.beat == 12)
		{
			FlxTween.tween(play.camHUD, {alpha: 1}, Conductor.instance.beatLengthMs / 1000, {ease: FlxEase.cubeOut});
			play.cancelCameraZoomTween();
			play.currentCameraZoom = play.stageZoom;
		}
		else if (event.beat == 146)
		{
			moveIn();
		}
		else if (event.beat == 184)
		{
			moveOut();
		}
		else if (event.beat == 256)
		{
			if (PlayStatePlaylist.isStoryMode)
			{
				var screeen = new FunkinSprite();
				screeen.makeGraphic(1, 1, 0xFF4D3A99);
				screeen.scale.set(2000, 2000);
				screeen.screenCenter();
				screeen.alpha = 0;
				add(screeen);
				screeen.camera = play.camHUD;
				screeen.blend = BlendMode.OVERLAY;
				FlxTween.tween(screeen, {alpha: 1}, 4, {ease: FlxEase.sineOut});

				var screeeen = new FunkinSprite();
				screeeen.makeGraphic(1, 1, FlxColor.BLACK);
				screeeen.scale.set(2000, 2000);
				screeeen.screenCenter();
				screeeen.alpha = 0;
				add(screeeen);
				screeeen.camera = play.camHUD;
				FlxTween.tween(screeeen, {alpha: 1}, 4, {ease: FlxEase.sineOut});
			}
		}
	}

	function onCountdownStart(event)
	{
		super.onCountdownStart(event);

		var play = PlayState.instance;
		if (play == null || play.isChartingMode)
			return;

    skipCountdown();
		event.cancel();

		play.camHUD.alpha = 0;

		var gf = getGirlfriend();
		if (gf != null)
			play.tweenCameraToPosition(gf.cameraFocusPoint.x, gf.cameraFocusPoint.y, 0);

		play.tweenCameraZoom(1.4, 0, false);
		FlxTimer.wait(Conductor.instance.beatLengthMs / 1000,
			() -> play.tweenCameraZoom(1.2, Conductor.instance.beatLengthMs * 4 / 1000, false, FlxEase.cubeOut));
	}

  function skipCountdown()
  {
    Countdown.stopCountdown();
    PlayState.instance.isInCountdown = true;
    PlayState.instance.camHUD.visible = true;
    Conductor.instance.update(PlayState.instance.startTimestamp);
  }

	function onSongStart(event)
	{
		super.onSongStart(event);

		var play = PlayState.instance;
		if (play != null && play.isChartingMode)
      play.isInCountdown = false;
			FlxTween.tween(play.camHUD, {alpha: 1}, Conductor.instance.beatLengthMs / 1000, {
        ease: FlxEase.cubeOut,
        startDelay: 4
      });
	}

	function boppersBop()
	{
		for (p in railBoppers)
		{
			var bopperY = p.y;
			p.y += 10;
			new FlxTimer().start(2 / 24, _ -> p.y = bopperY + 7.5);
			new FlxTimer().start(4 / 24, _ -> p.y = bopperY + 2.5);
			new FlxTimer().start(6 / 24, _ -> p.y = bopperY);
		}
	}

	function moveIn()
	{
		var play = PlayState.instance;
		if (play == null)
			return;

		FlxTween.tween(play.opponentStrumline, {x: play.opponentStrumline.x - 40, alpha: 0.75}, 1.75, {ease: FlxEase.sineOut});
		if (AmMlpc.playerStrum())
		{
		FlxTween.tween(play.playerStrumline, {x: play.playerStrumline.x - FlxG.width / 10 + 20}, 1.55, {ease: FlxEase.backOut});
		}

		if (AmMlpc.oppScale())
		{
		FlxTween.num(play.opponentStrumline.strumlineScale.x, .95, 1.75, {ease: FlxEase.sineOut},
			(value) -> play.opponentStrumline.strumlineScale.set(value, value));
		}
		if (AmMlpc.playerStrum())
		{
		FlxTween.num(play.playerStrumline.strumlineScale.x, 1.05, 1.55, {ease: FlxEase.backOut},
			(value) -> play.playerStrumline.strumlineScale.set(value, value));
		}
	}

	function moveOut()
	{
		var play = PlayState.instance;
		if (play == null)
			return;


		FlxTween.tween(play.opponentStrumline, {x: play.opponentStrumline.x + 40, alpha: 1}, 4.65, {ease: FlxEase.backOut});
		if (AmMlpc.playerStrum())
		{
		FlxTween.tween(play.playerStrumline, {x: play.playerStrumline.x + FlxG.width / 10 - 20}, 4.45, {ease: FlxEase.cubeOut});
		}

		if (AmMlpc.oppScale())
		{
		FlxTween.num(play.opponentStrumline.strumlineScale.x, 1, 4.65, {ease: FlxEase.backOut},
			(value) -> play.opponentStrumline.strumlineScale.set(value, value));
		}
		if (AmMlpc.playerStrum())
		{
		FlxTween.num(play.playerStrumline.strumlineScale.x, 1, 4.45, {ease: FlxEase.cubeOut},
			(value) -> play.playerStrumline.strumlineScale.set(value, value));
		}
	}

	override function onNoteHit(e)
	{
		if (e.isComboBreak)
			makeCrowdLaugh();
	}

	function onNoteGhostMiss(e)
	{
		super.onNoteGhostMiss(e);
		makeCrowdLaugh();
	}

	function onNoteMiss(e)
	{
		if (e.eventCanceled || e.note.kind == "solotime")
			return;
		super.onNoteMiss(e);
		makeCrowdLaugh();
	}

	function makeCrowdLaugh()
	{
		if (getNamedProp("cops").getCurrentAnimation().indexOf("snowball") == -1)
			getNamedProp("cops").playAnimation("laugh", true, true);
	}
}

class XMasCityHallAmTakeDarkStage extends ScriptedStage
{
	function new()
	{
		super('xMasCityMallAmTakeDark');
	}

	function lowQualityMode():Bool
	{
		return Save.instance.modOptions["lowQuality"] == true;
	}

	function shadersEnabled():Bool
	{
		return Save.instance.modOptions["shaders"] == true;
	}

	var railBoppers = [];
	var leftTV = null;
	var rightTV = null;
	var boppersIdle:Int = 2;

	var xmasDarkShader = null;

	var snowShader = null;
	var snowSprite = null;
	var snowTime:Float = 0;
	var snowBaseScaleX:Float = 1;
	var snowBaseScaleY:Float = 1;

	var snowZoomFactor:Float = 0.35;

	var snowFrag:String = "
#pragma header

uniform float uTime;
uniform vec2 uResolution;

uniform float uDensity;
uniform float uFlakeSize;
uniform float uFallSpeed;  
uniform float uWindStrength; 
uniform float uTwinkle;
uniform float uOpacity;   

void main()
{
    vec2 fragCoord = openfl_TextureCoordv.xy * uResolution;

    float snow = 0.0;
    float random = fract(sin(dot(fragCoord.xy, vec2(12.9898,78.233))) * 43758.5453);

    for (int k = 0; k < 6; k++) {
        for (int j = 0; j < 4; j++) {
            int i = 1 + j * 3;
            float cellSize = 2.0 + (float(i) * 3.0);
            float downSpeed = -(0.3 * uFallSpeed) - (sin(uTime*0.4 + float(k+i*20)) + 1.0) * 0.00008 * uFallSpeed;

            vec2 uv = (fragCoord.xy / uResolution.x)
                + vec2(0.01 * uWindStrength * sin((uTime + float(k*6185)) * 0.6 + float(i)) * (5.0/float(i)),
                       downSpeed * (uTime + float(k*1352)) * (1.0/float(i)));

            vec2 uvStep = (ceil((uv) * cellSize - vec2(0.5,0.5)) / cellSize);

            float x = fract(sin(dot(uvStep.xy, vec2(12.9898+float(k)*12.0, 78.233+float(k)*315.156))) * 43758.5453 + float(k)*12.0) - 0.5;
            float y = fract(sin(dot(uvStep.xy, vec2(62.2364+float(k)*23.0, 94.674+float(k)*95.0))) * 62159.8432 + float(k)*12.0) - 0.5;

            float randomMagnitude1 = sin(uTime*2.5) * 0.7 * uTwinkle / cellSize;
            float randomMagnitude2 = cos(uTime*2.5) * 0.7 * uTwinkle / cellSize;

            float d = 5.0 * distance((uvStep.xy + vec2(x*sin(y), y)*randomMagnitude1 + vec2(y, x)*randomMagnitude2), uv.xy);

            float omiVal = fract(sin(dot(uvStep.xy, vec2(32.4691,94.615))) * 31572.1684);

            if (omiVal < uDensity) {
                float newd = (x+1.0) * 0.4 * uFlakeSize * clamp(1.9 - d*(15.0+(x*6.3))*(cellSize/1.4), 0.0, 1.0);
                snow += newd;
            }
        }
    }
    vec4 texColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
    float alpha = clamp(snow + random*0.01, 0.0, 1.0) * texColor.a * uOpacity;
    vec3 flakeColor = texColor.rgb;

    gl_FragColor = vec4(flakeColor * alpha, alpha);
}";

	override function onCreate(e)
	{
		snowShader = null;
		snowSprite = null;
		snowTime = 0;

		super.onCreate(e);

		PauseSubState.musicSuffix = '-amtake5';

		createSnowOverlay();
	}

	override function buildStage():Void
	{
		if (PlayState.instance == null)
			return;

		railBoppers = [];
		leftTV = null;
		rightTV = null;

		super.buildStage();

		for (dataProp in _data.props)
		{
			var prop = getNamedProp(dataProp.name);
			if (prop == null)
				continue;

			if (dataProp.name.indexOf('rail-guys-') != -1)
				railBoppers.push(prop);
		}

		if (!lowQualityMode())
		{
			leftTV = new FunkinSprite(-1800, -690);
			leftTV.loadTextureAtlas("stages/xMassCityMallDark/tvl", "shared", {cacheOnLoad: true});
			leftTV.zIndex = 70;
			leftTV.scrollFactor.set(0.875, 0.875);
			leftTV.anim.addByFrameLabel("noise", "noise", 24, false);
			leftTV.anim.onFinish.add(function(name)
			{
				if (name == "noise")
				{
					if (FlxG.random.bool(15))
						leftTV.anim.play("OOGA BOOGA", true);
					else
						leftTV.anim.play(Std.string(FlxG.random.int(0, 5)), true);
				}
				else if (name == "OOGA BOOGA")
				{
					leftTV.anim.play("noise", true);
				}
			});
			leftTV.anim.addByFrameLabel("0", "f1", 24);
			leftTV.anim.addByFrameLabel("1", "f2", 24);
			leftTV.anim.addByFrameLabel("2", "f3", 24);
			leftTV.anim.addByFrameLabel("3", "f4", 24);
			leftTV.anim.addByFrameLabel("4", "f5", 24);
			leftTV.anim.addByFrameLabel("5", "f6", 24);
			leftTV.anim.addByFrameLabelIndices("OOGA BOOGA", "OOGA BOOGA", [0, 0, 0, 0], 24, false);
			leftTV.anim.play("OOGA BOOGA", true);
			leftTV.flipX = true;
			add(leftTV);

			rightTV = new FunkinSprite(980, -690);
			rightTV.loadTextureAtlas("stages/xMassCityMallDark/tvr", "shared", {cacheOnLoad: true});
			rightTV.zIndex = 70;
			rightTV.scrollFactor.set(0.875, 0.875);
			rightTV.anim.addByFrameLabel("noise", "noise", 24, false);
			rightTV.anim.onFinish.add(function(name)
			{
				if (name == "noise")
					rightTV.anim.play(Std.string(FlxG.random.int(0, 6)), true);
			});
			rightTV.anim.addByFrameLabel("0", "f1", 24);
			rightTV.anim.addByFrameLabel("1", "f2", 24);
			rightTV.anim.addByFrameLabel("2", "f3", 24);
			rightTV.anim.addByFrameLabel("3", "f4", 24);
			rightTV.anim.addByFrameLabel("4", "f5", 24);
			rightTV.anim.addByFrameLabel("5", "f6", 24);
			rightTV.anim.addByFrameLabel("6", "f7", 24);
			rightTV.anim.play("noise", true);
			add(rightTV);
		}

		refresh();

		if (Save.instance.modOptions["lowQuality"])
		{
			removeLowQualityProps();
		}
	}

	override function onSongLoaded(event)
	{
		super.onSongLoaded(event);
		applyDarkShader();
	}

	function shadeObject(obj):Void
	{
		if (obj != null)
			obj.shader = xmasDarkShader;
	}

	function applyDarkShader():Void
	{
		if (xmasDarkShader == null)
			xmasDarkShader = HSVBlendedShader.xmasInit();

		shadeObject(getDad());
		shadeObject(getGirlfriend());
		shadeObject(getBoyfriend());

		var gf = getGirlfriend();
		if (gf != null)
		{
			try
			{
				if (gf.fgSnow != null)
					gf.fgSnow.shader = xmasDarkShader;
			}
			catch (err:Dynamic) {}
		}


		if (!lowQualityMode())
		{
			var miku = getNamedProp("rail-guys-miku");
			var bf = getBoyfriend();
			if (miku != null && bf != null)
				miku.alpha = (bf.characterId.indexOf("miku") == -1 ? 1 : 0.0001);

			for (name in ["tree-crushers", "meat-boy", "c-toy-1", "c-toy-2", "alien_ship"])
				shadeObject(getNamedProp(name));
		}

		for (name in ["zonet", "casset", "gang", "coolbud", "cops", "bandage_girl", "santa", "snowfg", "snowman"])
			shadeObject(getNamedProp(name));
	}

	function createSnowOverlay():Void
	{
		if (!shadersEnabled())
			return;

		snowShader = new FlxRuntimeShader(snowFrag);
		snowShader.setFloat("uTime", 0);

		snowSprite = new FunkinSprite();
		snowSprite.makeSolidColor(Std.int(FlxG.width * 3.5), Std.int(FlxG.height * 3.5), 0xFF99BBFF);
		snowSprite.zIndex = 395;
		add(snowSprite);
		refresh();
		snowSprite.scrollFactor.set(1.2, 1.2);
		snowSprite.screenCenter();
		snowSprite.shader = snowShader;

		snowBaseScaleX = snowSprite.scale.x;
		snowBaseScaleY = snowSprite.scale.y;

		snowShader.setFloatArray("uResolution", [snowSprite.width, snowSprite.height]);

		snowShader.setFloat("uDensity", 0.35);
		snowShader.setFloat("uFlakeSize", 2.0);
		snowShader.setFloat("uFallSpeed", 0.75);
		snowShader.setFloat("uWindStrength", 4.0);
		snowShader.setFloat("uTwinkle", 0.9);
		snowShader.setFloat("uOpacity", 0.75);
	}

	override function onUpdate(event)
	{
		super.onUpdate(event);

		if (snowShader == null || snowSprite == null)
			return;

		snowTime += event.elapsed;
		snowShader.setFloat("uTime", snowTime);

		var zoom = FlxG.camera.zoom;
		var f = (1 - snowZoomFactor) / zoom + snowZoomFactor;
		snowSprite.scale.set(snowBaseScaleX * f, snowBaseScaleY * f);
	}

	override function onBeatHit(event)
	{
		super.onBeatHit(event);

		if (lowQualityMode())
			return;

		if (leftTV != null && FlxG.random.bool(10))
			leftTV.anim.play("noise", true);

		if (rightTV != null && FlxG.random.bool(10))
			rightTV.anim.play("noise", true);

		if (event.beat % boppersIdle == 0)
			boppersBop();
	}

	function boppersBop():Void
	{
		for (p in railBoppers)
			bounceProp(p);
	}

	function bounceProp(p):Void
	{
		var bopperY = p.y;
		p.y += 10;
		new FlxTimer().start(2 / 24, function(t) { p.y = bopperY + 7.5; });
		new FlxTimer().start(4 / 24, function(t) { p.y = bopperY + 2.5; });
		new FlxTimer().start(6 / 24, function(t) { p.y = bopperY; });
	}

	override function onNoteHit(e)
	{
		super.onNoteHit(e);

		if (e.isComboBreak)
			makeCrowdLaugh();
	}

	override function onNoteGhostMiss(e)
	{
		super.onNoteGhostMiss(e);
		makeCrowdLaugh();
	}

	override function onNoteMiss(e)
	{
		if (e.eventCanceled || e.note.kind == "solotime")
			return;

		super.onNoteMiss(e);
		makeCrowdLaugh();
	}

	function makeCrowdLaugh():Void
	{
		var cops = getNamedProp("cops");
		if (cops == null)
			return;

		if (cops.getCurrentAnimation().indexOf("snowball") == -1)
			cops.playAnimation("laugh", true, true);
	}

	var _lowQualityProps = ['ceiling', 'upFreaks', 'rail-guys-far', 'goku', 'rail-guys-bobby', 'rail-guys-left', 'rail-guys-miku', 'rail-guys-right', 'candy', 'alien_ship', 'tree-crushers', 'meat-boy', 'c-toy-1', 'c-toy-2'];

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

		if (!ps.isChartingMode)
		{
			event.cancel();
			skipCountdown();
		}
	}

	function setComboPopUpsVisible(how:Bool)
	{
		var popUps = ModuleHandler.getModule('RatingComboModule').ratingPopUps;
		if (popUps != null)
			popUps.visible = how;
	}

	function skipCountdown()
	{
		Countdown.stopCountdown();
		ps.isInCountdown = true;
		ps.camHUD.visible = true;
		Conductor.instance.update(ps.startTimestamp);
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

class HighShader extends FlxRuntimeShader
{
	var currentTime(default, set):Float = 0.0;
	var effectiveness(default, set):Float = 0.0;

	public function new()
	{
		var fragText:String = Assets.getText(Paths.frag('high'));
		super(fragText);
		reset();
	}

	function set_currentTime(nt:Float):Float
	{
		this.setFloat('iTime', nt);
		return currentTime = nt;
	}

	function set_effectiveness(nt:Float):Float
	{
		this.setFloat('effectiveness', nt);
		return effectiveness = nt;
	}

	public function update(elapsed:Float):Void
	{
		currentTime += elapsed;
	}

	public function reset()
	{
		currentTime = 0;
		effectiveness = 0;
	}
}

class TrippyShader extends FlxRuntimeShader
{
	public var currentTime(default, set):Float = 0.0;
	public var darkness(default, set):Float = 0.0;
	public var intensity(default, set):Float = 0.0;

	function set_currentTime(nt:Float):Float
	{
		this.setFloat('iTime', nt);
		return currentTime = nt;
	}

	function set_darkness(nt:Float):Float
	{
		this.setFloat('darkness', nt);
		return darkness = nt;
	}

	function set_intensity(nt:Float):Float
	{
		this.setFloat('intensity', nt);
		return intensity = nt;
	}

	public function new()
	{
		var fragText:String = Assets.getText(Paths.frag('trippy'));
		super(fragText);
		reset();
	}

	public function update(elapsed:Float):Void
	{
		currentTime += elapsed;
	}

	public function reset()
	{
		currentTime = 0;
		darkness = 1.0;
		threshold = 8.0;
	}
}

class HSVBlendedShader extends FlxRuntimeShader
{
	public static function xmasInit():HSVBlendedShader
	{
		var shader = new HSVBlendedShader(0xCC7D6EB8, 9);
		shader.setHue(-35);
		return shader;
	}

	public var hue:Float;
	public var saturation:Float;
	public var contrast:Float;
	public var brightness:Float;
	public var color:Int = 0xFFFFFFFF;
	public var blendMode:Int = BlendMode.MULTIPLY;

	function new(initColor:Int = 0xFFFFFFFF, initBlend:Int = 9)
	{
		super(Assets.getText(Paths.frag('hsvBlended')));
		setColor(initColor);
		setBlendMode(initBlend);
		setHue(1);
		setSaturation(1);
		setContrast(1);
		setBrightness(1);
	}

	function setColor(value:Int):Void
	{
		color = value;

		setFloatArray('blendColor', [
			((value >> 16) & 0xff) / 255.0,
			((value >> 8) & 0xff) / 255.0,
			(value & 0xff) / 255.0,
			((value >> 24) & 0xff) / 255.0
		]);
	}

	function setBlendMode(value:Int):Void
	{
		blendMode = value;
		setInt('iBlendMode', value);
	}

	function setHue(value:Float):Void
	{
		hue = value;
		setFloat('hue', value);
	}

	function setSaturation(value:Float):Void
	{
		saturation = value;
		setFloat('sat', value);
	}

	function setContrast(val:Float):Void
	{
		contrast = val;
		setFloat('contrast', val);
	}

	function setBrightness(val:Float):Void
	{
		brightness = val;
		setFloat('brightness', val);
	}
}

class BloomShader extends FlxRuntimeShader
{
	public function new()
	{
		super(Assets.getText(Paths.frag('bloom')));
		setFloatArray("blurSize", [50, 50]);
		setFloat("quality", 2.); 
	}

	public function setBlurSize(x:Float, y:Float)
	{
		setFloatArray("blurSize", [x, y]);
	}

	public function setQuality(q:Float)
	{
		setFloat("quality", q);
	}
}

class SoloTime extends Module
{
    var MULTI_SHIT = .5;
    var OFFSET = 0.25;

    override function onSongLoaded(event:SongLoadScriptEvent)
    {
		super.onSongLoaded();
		if (PlayState.instance == null || PlayState.instance.currentDifficulty == null) return;
		var currentDifficulty:PlayState = PlayState.instance.currentDifficulty;
        if (currentDifficulty == "easy" || currentDifficulty == "normal" || currentDifficulty == "hard")
        {
            FunkinMemory.cacheTexture(Paths.image("ui/times/solo_time"));
            FunkinMemory.cacheTexture(Paths.image("ui/times/solo_time-xmas"));
        }
    }

    override function onSongEvent(event:SongEventScriptEvent) {
		var camHUD:FunkinCamera = PlayState.instance.camHUD;
        if (event.eventData.eventKind == "SoloTime")
        {
            var suffix = event.eventData.getString("randParam") ?? "";
            FunkinSound.playOnce(Paths.sound("gameplay/solo_time/solotime" + suffix , "shared"));

            var texturePath = "ui/times/solo_time" + suffix;
            var soloTimeTxtSplash = new FunkinSprite();
            soloTimeTxtSplash.loadSparrow(texturePath);
            soloTimeTxtSplash.animation.addByPrefix("anim", "solo_time", 24, false);
            soloTimeTxtSplash.animation.onFinish.add(function(name:String)
            {
                FlxTween.tween(soloTimeTxtSplash, {alpha: 0}, 0.5);
            });
            soloTimeTxtSplash.scale.set(0.75, 0.75);
            soloTimeTxtSplash.zIndex = 150;
            soloTimeTxtSplash.screenCenter(0x10);
            soloTimeTxtSplash.camera = camHUD;
            soloTimeTxtSplash.zIndex = 20;
            soloTimeTxtSplash.x = -120;
            soloTimeTxtSplash.animation.timeScale = 1 / MULTI_SHIT;
            soloTimeTxtSplash.animation.play("anim", true);
            soloTimeTxtSplash.angle = FlxG.random.float(-2, 2);
            FlxTween.tween(soloTimeTxtSplash, {x: soloTimeTxtSplash.x + 20, angle: 0}, 1 * MULTI_SHIT, {ease: FlxEase.cubeOut});
            PlayState.instance.add(soloTimeTxtSplash);

            createCoolBackLine(100, 1, 140, -180, 300);
            createCoolBackLine(350, 1, 60, -180, 650);
            createCoolBackLine(560, 1, 15, -180, 950);

            createBlackLine(-(FlxG.height / 4), -(FlxG.height / 6));
            createBlackLine(FlxG.height, FlxG.height - (FlxG.height / 8));

            PlayState.instance.refresh();
        }
    }

    function constructSoloText()
    {
        var txt = new FlxText();
        txt.setFormat(Paths.font("Blueprint.ttf"), 96, 0xffffffff);
        txt.scale.y *= 0.8;
        return txt;
    }

    function createBlackLine(yPos:Float, targetY:Float):FunkinSprite
    {
        var blackLine:FunkinSprite = new FunkinSprite(0, yPos).makeSolidColor(FlxG.width, Std.int(FlxG.height / 4), FlxColor.BLACK);
        blackLine.camera = PlayState.instance.camHUD;
        blackLine.alpha = 1;
        blackLine.zIndex = 5;
        PlayState.instance.add(blackLine);

        FlxTween.tween(blackLine, {y: targetY}, 10 / 24 * MULTI_SHIT, {
            startDelay: 4 / 24 * MULTI_SHIT,
            ease: FlxEase.quadOut,
            onComplete: function(_) {
                FlxTween.tween(blackLine, {y: yPos}, 10 / 24 * MULTI_SHIT, {
                    startDelay: 30 / 24 * MULTI_SHIT,
                    ease: FlxEase.quadOut,
                    onComplete: function(_)
                    {
                        PlayState.instance.remove(blackLine, true);
                        blackLine.destroy();
                    }
                });
            }
        });
        return blackLine;
    }

    function createCoolBackLine(xPos:Float, zIndex:Int, scaleX:Float, moveAmount:Float, moveEnd:Float)
    {
        var coolBackLine:FunkinSprite = new FunkinSprite(xPos, -100).makeSolidColor(1, Std.int(FlxG.height * 1.75), FlxColor.BLACK);
        coolBackLine.cameras = [PlayState.instance.camHUD];
        coolBackLine.angle = -20;
        coolBackLine.zIndex = zIndex;
        coolBackLine.scale.x = 0.001;
        coolBackLine.updateHitbox();
        PlayState.instance.add(coolBackLine);

        FlxTween.tween(coolBackLine.scale, {x: scaleX}, 9 / 24 * MULTI_SHIT, {startDelay: OFFSET, ease: FlxEase.quadOut});
        FlxTween.tween(coolBackLine, {x: coolBackLine.x - moveAmount}, 10 / 24 * MULTI_SHIT, {startDelay: OFFSET, ease: FlxEase.quadOut});
        FlxTween.tween(coolBackLine.scale, {x: 0.0}, 9 / 24 * MULTI_SHIT, {startDelay: 38 / 24 * MULTI_SHIT + OFFSET, ease: FlxEase.quadOut});
        FlxTween.tween(coolBackLine, {x: coolBackLine.x + moveEnd}, 10 / 24 * MULTI_SHIT, {
            startDelay: 38 / 24 * MULTI_SHIT + OFFSET,
            ease: FlxEase.quadOut,
            onComplete: function(_)
            {
                PlayState.instance.remove(coolBackLine, true);
                coolBackLine.destroy();
            }
        });
    }
}

class CountDownEvent extends SongEvent
{
	public function new()
	{
		super("CountDown");
	}

	public override function getEventSchema()
	{
		return [
			{
				name: 'isPixel',
				title: 'Is it pixel?',
				type: "bool",
				defaultValue: false,
			},
			{
				name: 'curStep',
				title: 'CountDown Step',
				type: "string",
				defaultValue: '3',
			}
		];
	}

	public override function handleEvent(data):Void
	{
		if (PlayState.instance == null || PlayState.instance.currentStage == null)
			return;
		if (PlayState.instance.isMinimalMode)
			return;
		var game = PlayState.instance;

		var isPixel:CountdownStep = data.value.isPixel;
		var countStep:CountdownStep = switch(data.value.curStep.toLowerCase())
		{
			case "3": 
				CountdownStep.THREE;
			case "2": 
				CountdownStep.TWO;
			case "1": 
				CountdownStep.ONE;
			default: 
				CountdownStep.GO;
			case "after": 
				CountdownStep.AFTER;
		}

		Countdown.showCountdownGraphic(countStep, isPixel);
		Countdown.playCountdownSound(countStep, isPixel);


		var event:ScriptEvent = new CountdownScriptEvent((countStep != CountdownStep.AFTER ? 'COUNTDOWN_STEP' : 'COUNTDOWN_END'), countStep);
		game.dispatchEvent(event);

		
		game.refresh();
	}

	public override function loadEvent():Void
	{
		trace('Tryed to load event shit');
	}

	/**
	 * Retrieves the asset path to the icon this event type should use in the chart editor.
	 * To customize this, override getIconPath().
	 */
	/*public override function getIconPath():String
	{
		return 'ui/chart-editor/events/SoloTime';
	}*/

	public override function getTitle():String
	{
		return 'CountDown Event';
	}
}

class CinematicBarsSongEvent extends SongEvent
{
  static final BAR_HEIGHT:Float = 350;
  static final BAR_WIDTH:Float = 15000;
  static final BAR_COLOR:Int = 0xFF000000;

  var upperBar:Null<FlxSprite> = null;
  var lowerBar:Null<FlxSprite> = null;

  var baseUpperY:Float = 0;
  var baseLowerY:Float = 0;

  public function new()
  {
    super('CinematicBars');
  }

  public override function onCountdownStart(event:ScriptEvent):Void
  {
    destroyBars();

    upperBar = new FlxSprite(-((BAR_WIDTH - FlxG.width) / 2), -BAR_HEIGHT);
    upperBar.makeGraphic(Std.int(BAR_WIDTH), Std.int(BAR_HEIGHT), BAR_COLOR);
    upperBar.cameras = [PlayState.instance.camHUD];
    upperBar.zIndex = PlayState.instance.healthBar.zIndex - 8;
    PlayState.instance.add(upperBar);

    lowerBar = new FlxSprite(-((BAR_WIDTH - FlxG.width) / 2), FlxG.height);
    lowerBar.makeGraphic(Std.int(BAR_WIDTH), Std.int(BAR_HEIGHT), BAR_COLOR);
    lowerBar.cameras = [PlayState.instance.camHUD];
    lowerBar.zIndex = PlayState.instance.healthBar.zIndex - 8;
    PlayState.instance.add(lowerBar);

    PlayState.instance.refresh();

    baseUpperY = upperBar.y;
    baseLowerY = lowerBar.y;
  }

  public override function onDestroy(event:ScriptEvent):Void
  {
    destroyBars();
  }

  public override function onSongEnd(event:ScriptEvent):Void
  {
    destroyBars();
  }

  public override function onGameOver(event:ScriptEvent):Void
  {
    destroyBars();
  }

  function destroyBars():Void
  {
    if (upperBar != null)
    {
      FlxTween.cancelTweensOf(upperBar);
      if (PlayState.instance != null) PlayState.instance.remove(upperBar, true);
      upperBar.destroy();
      upperBar = null;
    }

    if (lowerBar != null)
    {
      FlxTween.cancelTweensOf(lowerBar);
      if (PlayState.instance != null) PlayState.instance.remove(lowerBar, true);
      lowerBar.destroy();
      lowerBar = null;
    }
  }

  public override function handleEvent(data:SongEventData):Void
  {
    if (upperBar == null || lowerBar == null) return;

    var upY:Float = data.getFloat('upY') ?? 0;
    var upTime:Float = data.getFloat('upTime') ?? 0;
    var upEase:String = data.getString('upEase') ?? SongEvent.DEFAULT_EASE;
    var upEaseDir:String = data.getString('easeDirup') ?? SongEvent.DEFAULT_EASE_DIR;

    var downY:Float = data.getFloat('downY') ?? 0;
    var downTime:Float = data.getFloat('downTime') ?? 0;
    var downEase:String = data.getString('downEase') ?? SongEvent.DEFAULT_EASE;
    var downEaseDir:String = data.getString('easeDirdown') ?? SongEvent.DEFAULT_EASE_DIR;

    FlxTween.cancelTweensOf(upperBar);
    FlxTween.cancelTweensOf(lowerBar);

    var upEaseFn:Float->Float = resolveEase(upEase, upEaseDir);
    var downEaseFn:Float->Float = resolveEase(downEase, downEaseDir);

    FlxTween.tween(upperBar, {y: baseUpperY + upY}, Math.max(upTime, 0), {ease: upEaseFn});

    FlxTween.tween(lowerBar, {y: baseLowerY - downY}, Math.max(downTime, 0), {ease: downEaseFn});
  }

  /**
   * Resuelve el string de ease/easeDir del chart (mismo formato que ZoomCamera)
   * a la funcion real de FlxEase, sin explotar si el nombre no existe: si el
   * combo es invalido cae a linear en vez de tirar error en el tween.
   */
  function resolveEase(ease:String, easeDir:String):Float->Float
  {
    if (ease == null || ease == '') ease = SongEvent.DEFAULT_EASE;
    if (easeDir == null) easeDir = '';

    if (SongEvent.EASE_TYPE_DIR_REGEX.match(ease) || ease == 'linear') easeDir = '';

    var fnName:String = '$ease$easeDir';
    var fn:Null<Float->Float> = Reflect.field(FlxEase, fnName);

    if (fn == null)
    {
      trace('[CinematicBars] Funcion de ease invalida: $fnName, se usa linear.');
      return FlxEase.linear;
    }

    return fn;
  }

  public override function getTitle():String
  {
    return 'Cinematic Bars';
  }

  public override function getEventSchema():SongEventSchema
  {
    var easeKeys = [
      'Linear' => 'linear',
      'Sine' => 'sine',
      'Quad' => 'quad',
      'Cube' => 'cube',
      'Quart' => 'quart',
      'Quint' => 'quint',
      'Expo' => 'expo',
      'Smooth Step' => 'smoothStep',
      'Smoother Step' => 'smootherStep',
      'Elastic' => 'elastic',
      'Back' => 'back',
      'Bounce' => 'bounce',
      'Circ' => 'circ',
    ];

    var dirKeys = ['In' => 'In', 'Out' => 'Out', 'In/Out' => 'InOut'];

    return new SongEventSchema([
      {
        name: 'upper',
        title: 'Barra superior',
        type: 'frame',
        children: [
          {
            name: 'upY',
            title: 'Distancia (px)',
            defaultValue: 0.0,
            step: 5.0,
            type: 'float'
          },
          {
            name: 'upTime',
            title: 'Duracion (segundos)',
            defaultValue: 1.0,
            min: 0,
            step: 0.05,
            type: 'float'
          },
          {
            name: 'upEase',
            title: 'Easing',
            defaultValue: SongEvent.DEFAULT_EASE,
            type: 'enum',
            keys: easeKeys
          },
          {
            name: 'easeDirup',
            title: 'Direccion',
            defaultValue: SongEvent.DEFAULT_EASE_DIR,
            type: 'enum',
            keys: dirKeys
          }
        ]
      },
      {
        name: 'lower',
        title: 'Barra inferior',
        type: 'frame',
        children: [
          {
            name: 'downY',
            title: 'Distancia (px)',
            defaultValue: 0.0,
            step: 5.0,
            type: 'float'
          },
          {
            name: 'downTime',
            title: 'Duracion (segundos)',
            defaultValue: 1.0,
            min: 0,
            step: 0.05,
            type: 'float'
          },
          {
            name: 'downEase',
            title: 'Easing',
            defaultValue: SongEvent.DEFAULT_EASE,
            type: 'enum',
            keys: easeKeys
          },
          {
            name: 'easeDirdown',
            title: 'Direccion',
            defaultValue: SongEvent.DEFAULT_EASE_DIR,
            type: 'enum',
            keys: dirKeys
          }
        ]
      }
    ]);
  }
}

class AddCameraZoomSongEvent extends SongEvent
{
  static final DECAY_RATE:Float = 0.95;
  static final EPSILON:Float = 0.0005;

  var active:Bool = false;
  var savedCameraZoomRate:Float = 0;

  public function new()
  {
    super('AddCameraZoom');
  }

  public override function onCountdownStart(event:ScriptEvent):Void
  {
    active = false;
  }

  public override function onDestroy(event:ScriptEvent):Void
  {
    restoreBopIfNeeded();
  }

  public override function onSongEnd(event:ScriptEvent):Void
  {
    restoreBopIfNeeded();
  }

  public override function onGameOver(event:ScriptEvent):Void
  {
    restoreBopIfNeeded();
  }

  public override function handleEvent(data:SongEventData):Void
  {
    var ps:PlayState = PlayState.instance;
    if (ps == null) return;

    var gameZoom:Float = data.getFloat('gameZoom') ?? 0;
    var hudZoom:Float = data.getFloat('hudZoom') ?? 0;

    if (!active)
    {
      savedCameraZoomRate = ps.cameraZoomRate;
      ps.cameraZoomRate = 0;
      active = true;
    }

    ps.cameraBopMultiplier += gameZoom;
    ps.camHUD.zoom += hudZoom;
  }

  public override function onUpdate(event:UpdateScriptEvent):Void
  {
    if (!active) return;

    var ps:PlayState = PlayState.instance;
    if (ps == null)
    {
      active = false;
      return;
    }

    var dt:Float = event.elapsed * 60;
    var decay:Float = Math.pow(DECAY_RATE, dt);

    ps.cameraBopMultiplier = FlxMath.lerp(1.0, ps.cameraBopMultiplier, decay);
    ps.camHUD.zoom = FlxMath.lerp(ps.defaultHUDCameraZoom, ps.camHUD.zoom, decay);

    if (ps.subState == null && !ps.debugUnbindCameraZoom)
    {
      FlxG.camera.zoom = ps.currentCameraZoom * ps.cameraBopMultiplier;
    }

    if (Math.abs(ps.cameraBopMultiplier - 1.0) < EPSILON && Math.abs(ps.camHUD.zoom - ps.defaultHUDCameraZoom) < EPSILON)
    {
      ps.cameraBopMultiplier = 1.0;
      ps.camHUD.zoom = ps.defaultHUDCameraZoom;
      ps.cameraZoomRate = savedCameraZoomRate;
      active = false;
    }
  }

  function restoreBopIfNeeded():Void
  {
    if (!active) return;

    var ps:PlayState = PlayState.instance;
    if (ps != null) ps.cameraZoomRate = savedCameraZoomRate;

    active = false;
  }

  public override function getTitle():String
  {
    return 'Add Camera Zoom';
  }

  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'gameZoom',
        title: 'Game Zoom',
        defaultValue: 0.0,
        step: 0.005,
        type: 'float',
        units: 'x'
      },
      {
        name: 'hudZoom',
        title: 'HUD Zoom',
        defaultValue: 0.0,
        step: 0.005,
        type: 'float',
        units: 'x'
      }
    ]);
  }
}

class SetPropertySongEvent extends SongEvent
{
  var cameraSpeedMult:Float = 1.0;

  public function new()
  {
    super('SetProperty', {processOldEvents: true});
  }

  override public function handleEvent(data:SongEventData):Void
  {
    var pf = PlayState.instance;
    if (pf == null) return;

    var target = data.getString('target');
    var rawValue = data.getString('value');
    if (target == null || target == '') return;
    if (rawValue == null) rawValue = '';

    var value = parseValue(rawValue);

    if (target == 'currentCameraSpeed' || target == 'cameraSpeed')
    {
      if (isNumeric(StringTools.trim(rawValue)))
      {
        cameraSpeedMult = value;
        FlxG.camera.followLerp = Constants.DEFAULT_CAMERA_FOLLOW_RATE * cameraSpeedMult;
      }
      return;
    }

    var parts = target.split('.');
    var obj = resolveRoot(parts[0]);
    var i = 0;
    if (obj != null) i = 1;
    else
      obj = pf;

    if (i >= parts.length)
    {
      trace('[SetProperty] Target invalido: ' + target);
      return;
    }

    try
    {
      while (i < parts.length - 1)
      {
        obj = Reflect.getProperty(obj, parts[i]);
        if (obj == null)
        {
          trace('[SetProperty] "' + parts[i] + '" es null en la ruta ' + target);
          return;
        }
        i = i + 1;
      }
      Reflect.setProperty(obj, parts[parts.length - 1], value);
    }
    catch (e:Dynamic)
    {
      trace('[SetProperty] Error al asignar ' + target + ': ' + Std.string(e));
    }
  }

  function resolveRoot(name:String)
  {
    var pf = PlayState.instance;
    if (pf.currentStage == null) return null;
    if (name == 'boyfriend' || name == 'bf' || name == 'player') return pf.currentStage.getBoyfriend();
    if (name == 'dad' || name == 'opponent') return pf.currentStage.getDad();
    if (name == 'girlfriend' || name == 'gf') return pf.currentStage.getGirlfriend();
    return null;
  }

  function isNumeric(s:String):Bool
  {
    if (s == null || s.length == 0) return false;
    var chars = '0123456789.-+eE';
    var i = 0;
    while (i < s.length)
    {
      if (chars.indexOf(s.charAt(i)) == -1) return false;
      i = i + 1;
    }
    return !Math.isNaN(Std.parseFloat(s));
  }

  function parseValue(raw:String)
  {
    var v = StringTools.trim(raw);
    var lower = v.toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
    if (lower == 'null') return null;
    if (isNumeric(v)) return Std.parseFloat(v);
    return raw;
  }

  override public function onUpdate(event:UpdateScriptEvent):Void
  {
    if (cameraSpeedMult == 1.0) return;
    if (FlxG.camera.followLerp > 0) FlxG.camera.followLerp = Constants.DEFAULT_CAMERA_FOLLOW_RATE * cameraSpeedMult;
  }

  override public function onSongRetry(event:SongRetryEvent):Void
  {
    cameraSpeedMult = 1.0;
  }

  override public function onSongEnd(event:ScriptEvent):Void
  {
    cameraSpeedMult = 1.0;
  }

  override public function getTitle():String
  {
    return 'Set Property';
  }

  override public function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'target',
        title: 'Property',
        defaultValue: 'currentCameraSpeed',
        type: 'string'
      },
      {
        name: 'value',
        title: 'Value',
        defaultValue: '1',
        type: 'string'
      }
    ]);
  }
}

class PlaySoundSongEvent extends SongEvent
{
  public function new()
  {
    super('PlaySound');
  }

  override public function handleEvent(data:SongEventData):Void
  {
    var snd = data.getString('snd');
    if (snd == null || snd == '') return;

    var lib = data.getString('lib');
    var vol = data.getFloat('vol');
    var pitch = data.getFloat('pitch');
    if (vol == null) vol = 1.0;
    if (pitch == null) pitch = 1.0;

    var path = null;
    if (lib == null || lib == '') path = Paths.sound(snd);
    else
      path = Paths.sound(snd, lib);

    try
    {
      var sound = FunkinSound.playOnce(path, vol, null, null, true);
      if (sound != null) sound.pitch = pitch;
    }
    catch (e:Dynamic)
    {
      trace('[PlaySound] No se pudo reproducir "' + path + '": ' + Std.string(e));
    }
  }

  override public function getTitle():String
  {
    return 'Play Sound';
  }

  override public function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'snd',
        title: 'Sound',
        defaultValue: '',
        type: SongEventFieldType.STRING
      },
      {
        name: 'lib',
        title: 'Library',
        defaultValue: 'shared',
        type: SongEventFieldType.STRING
      },
      {
        name: 'vol',
        title: 'Volume',
        defaultValue: 1.0,
        min: 0,
        step: 0.1,
        type: SongEventFieldType.FLOAT
      },
      {
        name: 'pitch',
        title: 'Pitch',
        defaultValue: 1.0,
        min: 0.1,
        step: 0.05,
        type: SongEventFieldType.FLOAT
      }
    ]);
  }
}

class ScreenShakeSongEvent extends SongEvent
{
  public function new()
  {
    super('ScreenShake');
  }

  override public function handleEvent(data:SongEventData):Void
  {
    var pf = PlayState.instance;
    if (pf == null) return;

    var gameTime = data.getFloat('gameTime');
    var gameIntensity = data.getFloat('gameIntensity');
    var hudTime = data.getFloat('hudTime');
    var hudIntensity = data.getFloat('hudIntensity');
    if (gameTime == null) gameTime = 0.03;
    if (gameIntensity == null) gameIntensity = 0.015;
    if (hudTime == null) hudTime = 0.03;
    if (hudIntensity == null) hudIntensity = 0.015;

    if (gameIntensity > 0 && gameTime > 0) pf.camGame.shake(gameIntensity, gameTime);
    if (hudIntensity > 0 && hudTime > 0) pf.camHUD.shake(hudIntensity, hudTime);
  }

  override public function getTitle():String
  {
    return 'Screen Shake';
  }

  override public function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'gameTime',
        title: 'Game Duration',
        defaultValue: 0.03,
        min: 0,
        step: 0.01,
        type: 'float',
        units: 'sec'
      },
      {
        name: 'gameIntensity',
        title: 'Game Intensity',
        defaultValue: 0.015,
        min: 0,
        step: 0.005,
        type: 'float'
      },
      {
        name: 'hudTime',
        title: 'HUD Duration',
        defaultValue: 0.03,
        min: 0,
        step: 0.01,
        type: 'float',
        units: 'sec'
      },
      {
        name: 'hudIntensity',
        title: 'HUD Intensity',
        defaultValue: 0.015,
        min: 0,
        step: 0.005,
        type: 'float'
      }
    ]);
  }
}

class AnimaniaModule extends Module
{
	var BANNED_NOTEKINDS = ["noAnimation", "noanim", "parents-miss", "solotime"];
	var ONLY_HUD_SONGS = ["phone-call"];

	var camX:Float = 25.0;
	var camY:Float = 25.0;

	var ICON_BASE_SIZE:Float = 125;
	var ICON_BOP_SCALE:Float = 0.2;
	var POSITION_OFFSET:Int = 20;

	var BAR_MODULE_ID:String = "CurvedHealthBarModule";

	var usingAmTakeUI:Bool = false;
	var curFocus:String = null;
	var curFocusOld:String = null;

	var bopP1:Float = 0;
	var bopP2:Float = 0;

	var barDadColor:Int = Constants.COLOR_HEALTH_BAR_RED;
	var barBfColor:Int = Constants.COLOR_HEALTH_BAR_GREEN;
	var barNeedsPaint:Bool = true;

	public function new()
	{
		super("AnimaniaModule", 15);
	}

	function baseFNFSong():Bool
	{
		if (PlayState.instance == null)
			return false;
		return listBaseGameSongIds().contains((PlayState.instance.currentSong?.id.toLowerCase() ?? ''));
	}

	function allowedHUD():Bool
	{
		if (PlayState.instance == null)
			return false;
		var id = PlayState.instance.currentSong?.id.toLowerCase() ?? '';
		return baseFNFSong() || ONLY_HUD_SONGS.contains(id);
	}

	function isPixelNoteStyle():Bool
	{
		try
		{
			var style = PlayState.instance.playerStrumline.noteStyle;
			return style != null && style.id.indexOf("pixel") != -1;
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}

	function updateCurFocus(player:Int):Void
	{
		curFocus = switch (player)
		{
			case 0: "bf";
			case 1: "dad";
			case 2: "gf";
			default: null;
		}
	}

	override function onSongEvent(event)
	{
		super.onSongEvent(event);
		if (PlayState.instance == null)
			return;

		var data = event.eventData;
		if (data.eventKind == "FocusCamera")
		{
			var focusChar = data.getInt('char');
			if (focusChar == null && Std.isOfType(data.value, Int))
				focusChar = data.value;
			updateCurFocus(focusChar ?? 0);
		}

		if (curFocusOld != curFocus)
			doDiffFocus();
	}

	function doDiffFocus():Void
	{
		FlxG.camera.targetOffset.set(0, 0);
		curFocusOld = curFocus;
	}

	override function onCountdownStart(event)
	{
		super.onCountdownStart(event);
		camX = 50.0;
		camY = 50.0;
	}

	override function onSongRetry(event)
	{
		super.onSongRetry(event);
		curFocus = null;
		curFocusOld = null;
		bopP1 = 0;
		bopP2 = 0;
	}

	function triggerCameraMovement(dir:Int):Void
	{
		var play = PlayState.instance;
		if (play == null)
			return;

		var off = FlxG.camera.targetOffset;
		off.set(0, 0);

		var mult = 1 / play.camGame.zoom * (play.stageZoom / 2);
		switch (dir)
		{
			case 0:
				off.x = -camX * mult;
			case 1:
				off.y = camY * mult;
			case 2:
				off.y = -camY * mult;
			case 3:
				off.x = camX * mult;
		}
	}

	override function onStateChangeEnd(event)
	{
		super.onStateChangeEnd(event);
		usingAmTakeUI = false;
		curFocus = null;
		curFocusOld = null;
		bopP1 = 0;
		bopP2 = 0;

		if (Std.isOfType(event.targetState, PlayState))
			loadAmTakeUI();
	}

	override function onSubStateOpenEnd(event)
	{
		super.onSubStateOpenEnd(event);
		if (Std.isOfType(event.targetState, PlayState))
			loadAmTakeUI();
	}

	override function onDestroy(event)
	{
		usingAmTakeUI = false;
		super.onDestroy(event);
	}

	function loadAmTakeUI():Void
	{
		var play = PlayState.instance;
		if (play == null || isPixelNoteStyle() || !allowedHUD())
			return;

		usingAmTakeUI = true;
		bopP1 = 0;
		bopP2 = 0;
		barNeedsPaint = true;

		for (icon in [play.iconP1, play.iconP2])
		{
			if (icon == null)
				continue;
			icon.bopEvery = 0;
			if (icon.bopTween != null)
				icon.bopTween.cancel();
		}
	}

	function getBarModule()
	{
		return ModuleHandler.getModule(BAR_MODULE_ID);
	}

	public function setBarColors(dadColor:Int, bfColor:Int):Void
	{
		barDadColor = dadColor;
		barBfColor = bfColor;
		barNeedsPaint = true;
		tryPaintBar();
	}

	function tryPaintBar():Void
	{
		if (!barNeedsPaint)
			return;

		var mod = getBarModule();
		if (mod == null || mod.redBar == null || mod.greenBar == null)
			return;

		mod.redBar.color = barDadColor;
		mod.greenBar.color = barBfColor;
		barNeedsPaint = false;
	}

	override function onUpdate(event)
	{
		super.onUpdate(event);

		var play = PlayState.instance;
		if (play == null || play.isGamePaused)
			return;

		if (!play.isSongEnd && !play.isPlayerDying)
		{
			var off = FlxG.camera.targetOffset;
			off.x = MathUtil.smoothLerpPrecision(off.x, 0, event.elapsed, 1);
			off.y = MathUtil.smoothLerpPrecision(off.y, 0, event.elapsed, 1);
		}

		if (!usingAmTakeUI)
			return;

		if (FlxG.keys.justPressed.F1)
			play.camHUD.visible = !play.camHUD.visible;

		tryPaintBar();

		updateHealthIcons(event.elapsed);
	}

	function updateHealthIcons(elapsed:Float):Void
	{
		var play = PlayState.instance;
		var bar = play.healthBar;
		var downscroll:Bool = AmScroll.isDown();

		var edgeX:Float;
		var centerY:Float;
		var mod = getBarModule();
		if (mod != null && mod.built == true && mod.bg != null && mod.redBar != null)
		{
			var pct = FlxMath.bound(bar.percent, 0, 100);
			edgeX = mod.redBar.x + mod.fillWidth * (1 - pct / 100);
			centerY = mod.bg.y + mod.bg.height / 2;
		}
		else
		{
			edgeX = bar.x + bar.width * (FlxMath.remapToRange(bar.value, 0, 2, 100, 0) * 0.01);
			centerY = bar.y + bar.height / 2;
		}
		var wave = FlxMath.fastCos((play.health - 1) * 2) * 15;
		var lerpHealth = bar.value;
		var bopDuration:Float = Math.max(Math.min(Conductor.instance.stepLengthMs * 0.002, 0.175), 0.01);

		for (i in 0...2)
		{
			var icon = (i == 0) ? play.iconP1 : play.iconP2;
			if (icon == null || !icon.autoUpdate)
				continue;

			var bop:Float = (i == 0) ? bopP1 : bopP2;
			if (bop > 0)
				bop = Math.max(bop - elapsed / bopDuration, 0);
			if (i == 0)
				bopP1 = bop;
			else
				bopP2 = bop;

			var fw:Float = Math.max(icon.frameWidth, 1);
			var fh:Float = Math.max(icon.frameHeight, 1);
			var mult:Float = 1 + ICON_BOP_SCALE * bop;
			var s:Float = (fw > fh) ? (ICON_BASE_SIZE * icon.size.x * mult) / fw : (ICON_BASE_SIZE * icon.size.y * mult) / fh;
			icon.scale.set(s, s);
			icon.updateHitbox();

			var targetAngle:Float = 0;
			if (i == 0)
			{
				icon.x = edgeX - POSITION_OFFSET;
				if (lerpHealth < .25)
					targetAngle = 50 * (.25 - lerpHealth);
			}
			else
			{
				icon.x = edgeX - (icon.width - POSITION_OFFSET);
				if (lerpHealth > 1.75)
					targetAngle = -30 * (lerpHealth - 1.75);
			}

			if (downscroll)
				icon.y = centerY - (icon.height / 2) + 20 - wave;
			else
				icon.y = centerY - (icon.height / 2) - 10 + wave;

			if (targetAngle != 0)
				icon.angle = targetAngle;
			else
				icon.angle = MathUtil.smoothLerpPrecision(icon.angle, 0, elapsed, Constants.HEALTH_ICON_ANGLE_HALF_LIFE);
		}
	}

	override function onBeatHit(event)
	{
		super.onBeatHit(event);
		if (!usingAmTakeUI)
			return;

		var play = PlayState.instance;
		if (play == null)
			return;

		for (i in 0...2)
		{
			var icon = (i == 0) ? play.iconP1 : play.iconP2;
			if (icon == null || !icon.autoUpdate)
				continue;
			if (Reflect.field(icon, "shouldBop") == false)
				continue;

			if (i == 0)
				bopP1 = 1;
			else
				bopP2 = 1;
		}
	}

	override function onNoteHit(event)
	{
		super.onNoteHit(event);

		var play = PlayState.instance;
		if (play == null || play.isMinimalMode)
			return;

		#if FEATURE_CHART_EDITOR
		if (Std.isOfType(FlxG.state, ChartEditorState) && !Std.isOfType(FlxG.state.subState, PlayState))
			return;
		#end

		var note = event.note;
		if (BANNED_NOTEKINDS.contains(note.kind))
			return;

		var mustHit = note.noteData.getMustHitNote();

		if ((curFocus == "bf" && mustHit) || (curFocus == "dad" && !mustHit) || curFocus == "gf")
			triggerCameraMovement(note.noteData.getDirection());

		if (!mustHit && FlxG.random.bool(60) && !event.eventCanceled)
			spawnOpponentSplash(note);
	}

	function spawnOpponentSplash(note):Void
	{
		var play = PlayState.instance;
		if (play == null || BANNED_NOTEKINDS.contains(note.kind))
			return;

		if (play.health > Constants.HEALTH_MAX * .2)
			play.health -= .85 / 100.0 * Constants.HEALTH_MAX;

		play.opponentStrumline.playNoteSplash(note.noteData.getDirection());
	}

	public function listBaseGameSongIds():Array<String>
	{
		return [
			"tutorial",
			"bopeebo",
			"fresh",
			"dadbattle",
			"spookeez",
			"south",
			"monster",
			"pico",
			"philly-nice",
			"blammed",
			"satin-panties",
			"high",
			"milf",
			"cocoa",
			"eggnog",
			"winter-horrorland",
			"senpai",
			"roses",
			"thorns",
			"ugh",
			"guns",
			"stress",
			"darnell",
			"lit-up",
			"2hot",
			"blazin",
			"test"
		];
	}
}

class AnimaniaStuff extends Module
{
	var DEATH_THRESHOLD:Float = 0.125 * 2;
	var LOSING_THRESHOLD:Float = 0.25 * 2;
	var WINING_THRESHOLD:Float = 0.8 * 2;

	var ICON_POSITION_OFFSET:Float = 26;

	var oldSpr:FunkinSprite = null;

	var BANNED_NOTEKINDS:Array<String> = [];

	var amTakeIcons:Array<Dynamic> = [];

	function new()
	{
		super("AnimaniaStuff", 14);
		registerNoteKinds();
	}

	function registerNoteKinds():Void
	{
		var kinds:Array<Array<String>> = [
			["gf", "Girlfriend Note"],
			["both", "Parents (Both) Sings (Week 5)"],
			["parents-miss", "Parents Miss (Week 5)"],
			["cheer", "Cool Custom HEY Note wows"],
			["beatbox", "BeatBox Note (Fresh)"],
			["fresh", "Fresh Note (Fresh)"],
			["blush", "Blush Note (Fresh)"]
		];

		for (kind in kinds)
		{
			var id:String = kind[0];
			if (NoteKindManager.getNoteKind(id) == null)
			{
				NoteKindManager.noteKinds.set(id, new NoteKind(id, kind[1]));
			}
		}
	}

	function isBannedNoteKind(kind:String):Bool
	{
		return kind != null && BANNED_NOTEKINDS.indexOf(kind) != -1;
	}

	function onCountdownStart(event:CountdownScriptEvent):Void
	{
		if (oldSpr != null && oldSpr.exists)
		{
			PlayState.instance.remove(oldSpr, true);
			oldSpr.destroy();
		}
		oldSpr = null;
	}

	function onCountdownStep(event:CountdownScriptEvent):Void
	{
		hideNativeCountdownSprite(event.step);
		showCountdownGraphic(event.step);
	}

	function onCountdownEnd(event:CountdownScriptEvent):Void
	{
		showCountdownGraphic(event.step);
	}

	function getCountdownNoteStyle():Dynamic
	{
		var chart = PlayState.instance.currentChart;
		var styleId:String = null;
		if (chart != null) styleId = chart.noteStyle;

		var noteStyle = null;
		if (styleId != null) noteStyle = NoteStyleRegistry.instance.fetchEntry(styleId);
		if (noteStyle == null) noteStyle = NoteStyleRegistry.instance.fetchDefault();
		return noteStyle;
	}

	function hideNativeCountdownSprite(index:Dynamic):Void
	{
		var state = PlayState.instance;
		var path:String = getCountdownNoteStyle().buildCountdownSpritePath(index);
		if (path == null) return;

		var key:String = Paths.image(path);
		var i:Int = state.members.length - 1;
		while (i >= 0)
		{
			var member = state.members[i];
			i--;

			if (member == null || member == oldSpr || !Std.isOfType(member, FunkinSprite)) continue;
			if (member.graphic == null || member.graphic.key != key) continue;
			if (member.cameras == null || member.cameras.length == 0 || member.cameras[0] != state.camHUD) continue;

			member.visible = false;
			return;
		}
	}

	function showCountdownGraphic(index:Dynamic):Void
	{
		var state = PlayState.instance;
		var stepName:String = Std.string(index);

		var noteStyle = getCountdownNoteStyle();

		var isPixelStyle:Bool = noteStyle.isCountdownSpritePixel(index);

		if (isPixelStyle)
		{
			showPixelCountdownGraphic(index, noteStyle);
			return;
		}

		if (stepName == "AFTER")
		{
			fadeOutOldSprite();
			return;
		}

		var prefix:String = null;
		switch (stepName)
		{
			case "THREE":
				prefix = "count3";
			case "TWO":
				prefix = "count2";
			case "ONE":
				prefix = "count1";
			case "GO":
				prefix = "countgo";
		}
		if (prefix == null) return;

		if (oldSpr != null)
		{
			state.remove(oldSpr, true);
			oldSpr.destroy();
			oldSpr = null;
		}

		var countdownSprite:FunkinSprite = FunkinSprite.createSparrow(0, 0, "ui/countdown/COUNTDOWN");
		countdownSprite.scrollFactor.set();
		countdownSprite.antialiasing = true;
		countdownSprite.cameras = [state.camHUD];

		countdownSprite.animation.addByPrefix("count", prefix, 24, false);
		countdownSprite.animation.play("count");
		countdownSprite.scale.set(.75, .75);
		countdownSprite.screenCenter();
		countdownSprite.centerOffsets();
		countdownSprite.centerOrigin();

		if (stepName == "THREE" || stepName == "ONE")
			countdownSprite.x += 30;

		if (state.currentStage != null && StringTools.startsWith(state.currentStage.id, "xMasCityMallAmTake"))
		{
			countdownSprite.x -= 280;
		}

		oldSpr = countdownSprite;
		state.add(countdownSprite);
	}

	function showPixelCountdownGraphic(index:Dynamic, noteStyle:Dynamic):Void
	{
		var state = PlayState.instance;

		var spritePath:String = noteStyle.buildCountdownSpritePath(index);
		if (spritePath == null) return;

		var countdownSprite:FunkinSprite = FunkinSprite.create(0, 0, spritePath);
		countdownSprite.scrollFactor.set();
		countdownSprite.antialiasing = false;
		countdownSprite.cameras = [state.camHUD];

		countdownSprite.setGraphicSize(Std.int(countdownSprite.width * Constants.PIXEL_ART_SCALE));
		countdownSprite.updateHitbox();
		countdownSprite.screenCenter();

		state.add(countdownSprite);

		FlxTween.tween(countdownSprite, {y: (countdownSprite.y -= 15) + 30, alpha: 0}, Conductor.instance.beatLengthMs / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween):Void
			{
				if (PlayState.instance != null) PlayState.instance.remove(countdownSprite, true);
				countdownSprite.destroy();
			}
		});
	}

	function fadeOutOldSprite():Void
	{
		if (oldSpr == null) return;

		var fading:FunkinSprite = oldSpr;
		oldSpr = null;

		FlxTween.tween(fading, {alpha: 0, angle: FlxG.random.sign() * 30}, Conductor.instance.beatLengthMs / 2000, {
			ease: FlxEase.backIn,
			onComplete: function(twn:FlxTween):Void
			{
				if (PlayState.instance != null) PlayState.instance.remove(fading, true);
				fading.destroy();
			}
		});
		FlxTween.tween(fading.scale, {x: 0, y: 0}, Conductor.instance.beatLengthMs / 1800, {
			ease: FlxEase.backIn
		});
	}

	function makeAmTakeIcon(ic:HealthIcon):HealthIcon
	{
		var icon = ic;
		icon.autoUpdate = false;

		icon.animation.add("idle", [0], 0, false, false);
		icon.animation.add("losing", [1], 0, false, false);
		icon.animation.add("death", [2], 0, false, false);
		icon.animation.remove("winning");

		registerAmTakeIcon(icon, false, isPlayerIcon(icon), null);
		return icon;
	}

	function makeAmTakeAnimatedIcon(ic:HealthIcon, ?isPlayer:Bool = false, ?customOffsets:Dynamic = null):HealthIcon
	{
		var icon = ic;
		icon.autoUpdate = false;

		if (isPlayer == null)
			isPlayer = isPlayerIcon(icon);

		if (icon.anim.hasAnimateAtlas)
		{
			icon.animation.addByFrameLabel("winning", "win", 24, true);
			icon.animation.addByFrameLabel("idle", "basic", 24, true);
			icon.animation.addByFrameLabel("losing", "lose", 24, true);
			icon.animation.addByFrameLabel("death", "predeath", 24, true);

			icon.animation.addByFrameLabel("toWinning", "basic-to-win", 24, false);
			icon.animation.addByFrameLabel("fromWinning", "win-to-basic", 24, false);
			icon.animation.addByFrameLabel("toLosing", "basic-to-lose", 24, false);
			icon.animation.addByFrameLabel("fromLosing", "lose-to-basic", 24, false);
			icon.animation.addByFrameLabel("toDeath", "lose-to-predeath", 24, false);
			icon.animation.addByFrameLabel("fromDeath", "predeath-to-lose", 24, false);
		}
		else
		{
			icon.animation.addByPrefix("winning", "win0", 1, true);
			icon.animation.addByPrefix("idle", "basic0", 1, true);
			icon.animation.addByPrefix("losing", "lose0", 1, true);
			icon.animation.addByPrefix("death", "predeath0", 1, true);

			icon.animation.addByPrefix("toWinning", "basic-to-win0", 24, false);
			icon.animation.addByPrefix("fromWinning", "win-to-basic0", 24, false);
			icon.animation.addByPrefix("toLosing", "basic-to-lose0", 24, false);
			icon.animation.addByPrefix("fromLosing", "lose-to-basic0", 24, false);
			icon.animation.addByPrefix("toDeath", "lose-to-predeath0", 24, false);
			icon.animation.addByPrefix("fromDeath", "predeath-to-lose0", 24, false);
		}

		var offsets:Dynamic = null;
		if (customOffsets == null)
		{
			offsets = ["default" => [0.0, 0.0]];
		}
		else if (Std.isOfType(customOffsets, Array))
		{
			offsets = ["default" => customOffsets];
		}
		else
		{
			offsets = customOffsets;
		}

		registerAmTakeIcon(icon, true, isPlayer, offsets);
		return icon;
	}

	function isPlayerIcon(icon:HealthIcon):Bool
	{
		return PlayState.instance != null && icon == PlayState.instance.iconP1;
	}

	function registerAmTakeIcon(icon:HealthIcon, animated:Bool, isPlayer:Bool, offsets:Dynamic):Void
	{
		for (entry in amTakeIcons.copy())
		{
			if (entry.icon == icon) amTakeIcons.remove(entry);
		}

		amTakeIcons.push({
			icon: icon,
			animated: animated,
			isPlayer: isPlayer,
			offsets: offsets,
			baseX: icon.iconOffset.x,
			baseY: icon.iconOffset.y,
			lastAnim: null
		});
	}

	function onUpdate(event:UpdateScriptEvent):Void
	{
		if (amTakeIcons.length == 0) return;

		var state = PlayState.instance;
		if (state == null || state.healthBar == null) return;

		for (entry in amTakeIcons.copy())
		{
			var icon = entry.icon;
			if (icon == null || !icon.exists)
			{
				amTakeIcons.remove(entry);
				continue;
			}

			var health:Float = entry.isPlayer ? state.health : Constants.HEALTH_MAX - state.health;

			if (entry.animated) updateAnimatedIconState(icon, health);
			else updateStaticIconState(icon, health);

			if (entry.animated) applyAnimatedIconOffsets(entry);
			updateAmTakeIconPosition(icon, entry.isPlayer);
		}
	}

	function updateAmTakeIconPosition(icon:HealthIcon, isPlayer:Bool):Void
	{
		var bar = PlayState.instance.healthBar;
		var barPercent:Float = FlxMath.remapToRange(bar.value, 0, 2, 100, 0) * 0.01;

		if (isPlayer)
			icon.x = bar.x + (bar.width * barPercent - ICON_POSITION_OFFSET);
		else
			icon.x = bar.x + (bar.width * barPercent) - (icon.width - ICON_POSITION_OFFSET);

		icon.y = bar.y - (icon.height / 2);
	}

	function applyAnimatedIconOffsets(entry:Dynamic):Void
	{
		var icon = entry.icon;
		var anim:String = icon.getCurrentAnimation();
		if (anim == entry.lastAnim) return;
		entry.lastAnim = anim;

		var offs:Array<Float> = null;
		if (entry.offsets != null)
		{
			offs = entry.offsets.get(anim);
			if (offs == null) offs = entry.offsets.get("default");
		}
		if (offs == null) offs = [0.0, 0.0];

		icon.iconOffset.set(entry.baseX + offs[0], entry.baseY + offs[1]);
		icon.updateHitbox();
	}

	function updateStaticIconState(icon:HealthIcon, health:Float):Void
	{
		switch (icon.getCurrentAnimation())
		{
			case "idle":
				if (health < LOSING_THRESHOLD) icon.playAnimation("losing");
				else if (health < DEATH_THRESHOLD) icon.playAnimation("death");
				else icon.playAnimation("idle");

			case "losing":
				if (health < DEATH_THRESHOLD) icon.playAnimation("death");
				else if (health > LOSING_THRESHOLD) icon.playAnimation("idle");
				else icon.playAnimation("losing");

			case "death":
				if (health > DEATH_THRESHOLD && health < LOSING_THRESHOLD) icon.playAnimation("losing");
				else if (health > LOSING_THRESHOLD) icon.playAnimation("idle");
				else icon.playAnimation("death");

			default:
				icon.playAnimation("idle", null, false);
		}
	}

	function updateAnimatedIconState(icon:HealthIcon, health:Float):Void
	{
		switch (icon.getCurrentAnimation())
		{
			case "winning":
				if (health < WINING_THRESHOLD) icon.playAnimation("fromWinning", "idle");
				else icon.playAnimation("winning", "idle");

			case "idle":
				if (health > WINING_THRESHOLD) icon.playAnimation("toWinning");
				else if (health < LOSING_THRESHOLD) icon.playAnimation("toLosing");
				else icon.playAnimation("idle");

			case "losing":
				if (health < DEATH_THRESHOLD) icon.playAnimation("toDeath");
				else if (health > LOSING_THRESHOLD) icon.playAnimation("fromLosing");
				else icon.playAnimation("losing");

			case "death":
				if (health > DEATH_THRESHOLD && health < LOSING_THRESHOLD) icon.playAnimation("fromDeath");
				else if (health > LOSING_THRESHOLD) icon.playAnimation("idle");
				else icon.playAnimation("death");

			case "toWinning":
				if (icon.isAnimationFinished()) icon.playAnimation("winning", "idle");
			case "fromWinning":
				if (icon.isAnimationFinished()) icon.playAnimation("idle");

			case "toLosing":
				if (icon.isAnimationFinished()) icon.playAnimation("losing", "idle");
			case "fromLosing":
				if (icon.isAnimationFinished()) icon.playAnimation("idle");

			case "toDeath":
				if (icon.isAnimationFinished()) icon.playAnimation("death", "idle");
			case "fromDeath":
				if (icon.isAnimationFinished()) icon.playAnimation("losing");

			default:
				icon.playAnimation("idle", null, false);
		}
	}
}

class CurvedHealthBarModule extends Module implements IPlayStateScriptedClass
{
	static inline var BG_ASSET:String = "ui/healthbar/HEALTHBAR";
	static inline var FILL_ASSET:String = "ui/healthbar/WHITEBAR";

	static inline var COLOR_GREEN:FlxColor = 0xFF66FF33;
	static inline var COLOR_RED:FlxColor = 0xFFFF0000;

	static inline var BAR_INSET_X:Float = 0;
	static inline var BAR_INSET_Y:Float = 0;

	static inline var FC_ATLAS_ASSET:String = "ui/ratings/GAMEPLAY_UI_ASSETS";
	static inline var FC_ATLAS_LIBRARY:String = "shared";
	static inline var FC_ANIM_PREFIX:String = "full combo";

	static var FC_BANNED_NOTEKINDS = ["noAnimation", "noanim", "parents-miss", "solotime"];

	function new()
	{
		super("CurvedHealthBarModule", 20);
	}

	static var MEGA_ALLOWED_STAGES:Array<String> = [
		"mainStageAmTake",
		"serviceEnterance",
		"xMasCityMallAmTake",
		"xMasCityMallAmTakeDark",
		"xMasCityMallNastyAmTake",
		"phoneCallStreet"
	];

	function isAllowedStage():Bool
	{
		var play = PlayState.instance;
		if (play == null || play.currentStage == null) return false;
		return MEGA_ALLOWED_STAGES.indexOf(play.currentStage.id) != -1;
	}

	public var bg:FlxSprite;
	public var greenBar:FlxSprite;
	public var redBar:FlxSprite;

	var fillX:Float = 0;
	var fillY:Float = 0;
	var fillWidth:Float = 0;
	var fillHeight:Float = 0;

	var built:Bool = false;

	override function onStateChangeEnd(event:StateChangeScriptEvent):Void
	{
		super.onStateChangeEnd(event);
		if (Std.isOfType(event.targetState, PlayState))
		{
			built = false;
			if (isAllowedStage())
			{
				setupHealthBar();
			}
			else
			{
				var play = PlayState.instance;
				if (play != null)
				{
					play.healthBarBG.visible = true;
					play.healthBar.visible = true;
				}
			}
		}
	}

	override function onSubStateOpenEnd(event:SubStateScriptEvent):Void
	{
		super.onSubStateOpenEnd(event);
		if (PlayState.instance != null && isAllowedStage())
			setupHealthBar();
	}

	function setupHealthBar():Void
	{
		var play = PlayState.instance;
		if (play == null) return;

		play.healthBarBG.visible = false;
		play.healthBar.visible = false;

		if (built)
		{
			repositionBar();
			return;
		}

		bg = new FlxSprite();
		bg.loadGraphic(Paths.image(BG_ASSET));
		bg.scrollFactor.set(0, 0);
		bg.cameras = [play.camHUD];

		redBar = new FlxSprite();
		redBar.loadGraphic(Paths.image(FILL_ASSET));
		redBar.color = COLOR_RED;
		redBar.scrollFactor.set(0, 0);
		redBar.cameras = [play.camHUD];

		greenBar = new FlxSprite();
		greenBar.loadGraphic(Paths.image(FILL_ASSET));
		greenBar.color = COLOR_GREEN;
		greenBar.scrollFactor.set(0, 0);
		greenBar.cameras = [play.camHUD];

		computeGeometry();

		var newBar:FlxBar = new FlxBar(fillX - 20, fillY + (fillHeight / 2) - 15, FlxBarFillDirection.RIGHT_TO_LEFT, Std.int(fillWidth), Std.int(fillHeight), play, "healthLerp",
			Constants.HEALTH_MIN, Constants.HEALTH_MAX);
		newBar.visible = false;
		newBar.scrollFactor.set(0, 0);
		play.healthBar = newBar;

		play.add(bg);
		play.add(redBar);
		play.add(greenBar);
		play.add(newBar);

		bg.zIndex = 804;
		redBar.zIndex = 801;
		greenBar.zIndex = 802;
		newBar.zIndex = 803;
		play.refresh();

		built = true;
		applyGeometry();
		updateBarClip();
	}

	function computeGeometry():Void
	{
		var isDownscroll:Bool = AmScroll.isDown();

		bg.y = isDownscroll ? (FlxG.height * 0.1 - 15) : (FlxG.height * 0.9 - 15);
		bg.screenCenter(0x01);

		fillX = bg.x + BAR_INSET_X;
		fillY = bg.y + BAR_INSET_Y;
		fillWidth = bg.width - (BAR_INSET_X * 2);
		fillHeight = bg.height - (BAR_INSET_Y * 2);
	}

	function applyGeometry():Void
	{
		var play = PlayState.instance;
		if (play == null || bg == null) return;

		var isDownscroll:Bool = AmScroll.isDown();

		for (bar in [redBar, greenBar])
		{
			bar.setPosition(fillX + 25, fillY + 3);
			bar.clipRect = null;
		}

		bg.flipY = redBar.flipY = greenBar.flipY = isDownscroll;

		play.healthBar.x = fillX - 20;
		play.healthBar.y = fillY + (fillHeight / 2) - 15;
	}

	function repositionBar():Void
	{
		if (bg == null) return;
		computeGeometry();
		applyGeometry();
		updateBarClip();
	}

	override function onUpdate(event:UpdateScriptEvent):Void
	{
		super.onUpdate(event);
		if (!built || PlayState.instance == null) return;
		updateBarClip();
	}

	function updateBarClip():Void
	{
		var play = PlayState.instance;
		if (play == null || play.healthBar == null) return;

		var percent:Float = FlxMath.bound(play.healthBar.percent, 0, 100);

		var greenWidth:Float = fillWidth * (percent / 100);
		var redWidth:Float = fillWidth - greenWidth;

		if (redWidth <= 0.5)
		{
			redBar.visible = false;
		}
		else
		{
			redBar.visible = true;
			redBar.clipRect = new FlxRect(0, 0, redWidth, fillHeight);
		}

		if (greenWidth <= 0.5)
		{
			greenBar.visible = false;
		}
		else
		{
			greenBar.visible = true;
			greenBar.clipRect = new FlxRect(fillWidth - greenWidth, 0, greenWidth, fillHeight);
		}
	}

	override function onDestroy(event:ScriptEvent):Void
	{
		super.onDestroy(event);
		built = false;
	}
}

class AnimaniaScoreModule extends Module
{
  static var ATLAS_KEY:String = 'ui/ratings/GAMEPLAY_UI_ASSETS';
  static var ATLAS_LIBRARY:String = 'shared';
  static var NUMBERS:Array<String> = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'];
  static var MAX_DIGITS:Int = 9;

  static var WOBBLE_START_SCORE:Float = 10000;
  static var WOBBLE_SATURATE_SCORE:Float = 100000;

  public var scoreLabel:FunkinSprite = null;
  public var scoreDigits:Array<FunkinSprite>;
  public var scoreDigitBaseScale:Array<Float>;

  public var lastShownScore:Int = -1;
  public var usingScoreUI:Bool = false;

  static var MEGA_ALLOWED_STAGES:Array<String> = [
    "mainStageAmTake",
    "serviceEnterance",
    "xMasCityMallAmTake",
    "xMasCityMallAmTakeDark",
    "xMasCityMallNastyAmTake",
	"phoneCallStreet"
  ];

  function isAllowedStage():Bool
  {
    var play = PlayState.instance;
    if (play == null || play.currentStage == null) return false;
    return MEGA_ALLOWED_STAGES.indexOf(play.currentStage.id) != -1;
  }

  public function new()
  {
    super('AnimaniaScoreModule', 200);
    scoreDigits = [];
    scoreDigitBaseScale = [];
  }

  public override function onCreate(event:ScriptEvent):Void
  {
    usingScoreUI = false;
  }

  public override function onStateChangeEnd(event:StateChangeScriptEvent):Void
  {
    usingScoreUI = false;

    if (Std.isOfType(event.targetState, PlayState))
    {
      if (isAllowedStage()) setupScoreUI();
      else disableScoreUI();
    }
  }

  public override function onSongRetry(event:SongRetryEvent):Void
  {
    if (isAllowedStage()) setupScoreUI();
    else disableScoreUI();
  }

  function disableScoreUI():Void
  {
    destroyScoreUI();

    var game:PlayState = PlayState.instance;
    if (game != null && game.scoreText != null) game.scoreText.alpha = 1;

    usingScoreUI = false;
  }

  function setupScoreUI():Void
  {
    var game:PlayState = PlayState.instance;
    if (game == null)
    {
      usingScoreUI = false;
      return;
    }

    destroyScoreUI();

    if (game.scoreText != null) game.scoreText.alpha = 0;

    var isDownscroll:Bool = AmScroll.isPref();
    var prefix:String = isDownscroll ? 'downscroll ' : '';
	var pauseButton:PlayState = game.pauseButton;

    var atlas = Paths.getSparrowAtlas(ATLAS_KEY, ATLAS_LIBRARY);

	scoreLabel = new FunkinSprite();
    scoreLabel.frames = atlas;
    scoreLabel.animation.addByPrefix('idle', prefix + 'score', 1, false);
    scoreLabel.animation.play('idle', true);
    scoreLabel.scale.set(0.55, 0.55);
    scoreLabel.updateHitbox();
    scoreLabel.x = FlxG.width - scoreLabel.width - 5;
    scoreLabel.y = isDownscroll ? 64 : (FlxG.height - scoreLabel.height - 62);
    scoreLabel.angle = isDownscroll ? -3.25 : 0;
    scoreLabel.scrollFactor.set();
    scoreLabel.cameras = [game.camHUD];
    scoreLabel.zIndex = 900;
    game.add(scoreLabel);

    scoreDigits = [];
    scoreDigitBaseScale = [];

    var prevDigit:FunkinSprite = null;

    for (i in 0...MAX_DIGITS)
    {
      var digit:FunkinSprite = new FunkinSprite();
      digit.frames = atlas;

      for (n in 0...NUMBERS.length)
      {
        digit.animation.addByPrefix(Std.string(n), prefix + NUMBERS[n], 1, false);
      }
      digit.animation.play('0', true);

      var scale:Float = (prevDigit == null) ? 0.75 : (scoreDigitBaseScale[i - 1] * 0.8825);
      digit.scale.set(scale, scale);
      digit.updateHitbox();

      if (prevDigit == null)
      {
        digit.x = FlxG.width - digit.width - 5;
      }
      else
      {
        digit.x = prevDigit.x - digit.width + 10;
      }
      digit.y = isDownscroll ? 5 : (FlxG.height - digit.height - 5);
      digit.angle = isDownscroll ? -3 : 0;
      digit.scrollFactor.set();
      digit.cameras = [game.camHUD];
      digit.zIndex = 899 - i;

      digit.visible = (i == 0);

      game.add(digit);
      scoreDigits.push(digit);
      scoreDigitBaseScale.push(scale);
      prevDigit = digit;
    }

    game.refresh();

    lastShownScore = -1;
    usingScoreUI = true;
    updateScoreDisplay(true);
  }

  function updateScoreDisplay(force:Bool = false):Void
  {
    var game:PlayState = PlayState.instance;
    if (game == null || scoreDigits.length == 0) return;

    var scoreInt:Int = Std.int(Math.max(0, game.songScore));
    if (!force && scoreInt == lastShownScore) return;
    lastShownScore = scoreInt;

    var chars:Array<String> = Std.string(scoreInt).split('');
    chars.reverse();

    for (i in 0...scoreDigits.length)
    {
      if (i < chars.length)
      {
        scoreDigits[i].visible = true;
        scoreDigits[i].animation.play(chars[i], true);
      }
      else
      {
        scoreDigits[i].visible = false;
      }
    }
  }

  public override function onUpdate(event:UpdateScriptEvent):Void
  {
    if (!usingScoreUI) return;

    var game:PlayState = PlayState.instance;
    if (game == null) return;

    updateScoreDisplay();

    var mdTime:Float = Conductor.instance.songPosition * 0.001;
    var scoreValue:Float = Math.max(0, lastShownScore - WOBBLE_START_SCORE);
    var t:Float = scoreValue / (WOBBLE_SATURATE_SCORE - WOBBLE_START_SCORE);
    var intensity:Float = Math.min(1.5, t);

    if (intensity <= 0) return;

    var isDownscroll:Bool = AmScroll.isPref();

	/*
    for (i in 0...scoreDigits.length)
    {
      var spr:FunkinSprite = scoreDigits[i];
      if (spr == null || !spr.visible) continue;

      var phase:Float = i * 0.55;

	  spr.offset.x = -Math.cos(mdTime * 2.0 + phase) * (0.12 + intensity * 0.55) + 40;
      spr.offset.y = -Math.sin(mdTime * 2.6 + phase) * (0.25 + intensity * 1.2) + 20;

      var scale:Float = scoreDigitBaseScale[i] + Math.sin(mdTime * 3.2 + phase) * (0.002 + intensity * 0.010);
      spr.scale.set(scale, scale);

      spr.angle = (isDownscroll ? -3 : 0) + Math.sin(mdTime * 1.8 + phase) * (0.2 + intensity * 0.8);
    }
	*/

	/*
    if (scoreLabel != null)
    {
      scoreLabel.offset.x = -Math.cos(mdTime * 1.7) * (0.08 + intensity * 0.35) + 75;
      scoreLabel.offset.y = Math.sin(mdTime * 2.0) * (0.15 + intensity * 0.65) + 45;
      scoreLabel.angle = (isDownscroll ? -3.25 : 0) + Math.sin(mdTime * 1.4) * (0.15 + intensity * 0.5);
    }
	*/
  }

  function destroyScoreUI():Void
  {
    var game:PlayState = PlayState.instance;

    if (scoreLabel != null)
    {
      if (game != null) game.remove(scoreLabel, true);
      scoreLabel.destroy();
      scoreLabel = null;
    }

    for (digit in scoreDigits)
    {
      if (digit == null) continue;
      if (game != null) game.remove(digit, true);
      digit.destroy();
    }
    scoreDigits = [];
    scoreDigitBaseScale = [];
  }

  public override function onDestroy(event:ScriptEvent):Void
  {
    usingScoreUI = false;

    if (PlayState.instance != null && PlayState.instance.scoreText != null)
    {
      PlayState.instance.scoreText.alpha = 1;
    }

    destroyScoreUI();
  }
}

class RatingComboModule extends Module implements IPlayStateScriptedClass
{
  public function new()
  {
    super("RatingComboModule", 200);
  }

  static var MEGA_ALLOWED_STAGES:Array<String> = [
    "mainStageAmTake",
    "serviceEnterance",
    "xMasCityMallAmTake",
    "xMasCityMallAmTakeDark",
    "xMasCityMallNastyAmTake",
	"phoneCallStreet"
  ];

  function isAllowedStage():Bool
  {
    var play = PlayState.instance;
    if (play == null || play.currentStage == null) return false;
    return MEGA_ALLOWED_STAGES.indexOf(play.currentStage.id) != -1;
  }

  var NUMBERS:Array<String> = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"];
  var SHOW_COMBO_VALUE:Int = 25;
  var SHOW_COMBONUMS_VALUE:Int = 15;
  var comboBlotColors:Array<Int> = [0xFF6666FF, 0xFFFF66CC, 0xFFFFCC99, 0xFF66FF99, 0xFF66FF99];
  var comboBlotColorsMax:Array<Int> = [50, 100, 200, 300];

  public var offsets:Array<Int> = [0, 0];

  public var stageOffsets:Array<Int> = [0, 0];

  public var variation:Bool = true;
  public var previousComboStuff:Array<Array<Dynamic>> = [];

  public var ratingPopUps:FunkinGroup = null;

  public var blot:FunkinSprite = null;

  var popupsInStage:Bool = false;

  /**
   * Emulates the Codename Engine sprite `zoomFactor` (the fork used 0.5 on every popup):
   * 1 = the popup scales with the camera zoom like any other object, 0 = it keeps its original size no matter the zoom.
   */
  public var popupZoomFactor:Float = 0.5;

  var popupStates:Array<Array<Dynamic>> = [];

  var popupPostUpdate:Dynamic = null;

  /**
   * Offset [x, y] applied to the popups on each stage. (was `ratingsOffset`)
   */
  function getStageRatingOffset(stageId:String):Array<Int>
  {
    return switch (stageId)
    {
      case "mainStageAmTake": [-35, 100];
      case "xMasCityMallAmTake": [-450, -150];
	  case "xMasCityMallAmTakeDark": [-450, -150];
      case "xMasCityMallNastyAmTake": [-730, -725];
	  case "phoneCallStreet": [180, 500];
      default: [0, 0];
    }
  }

  /**
   * zIndex of the popups inside the stage. (was `popupZIndex`)
   * `null` = not inside the stage, they're drawn on top of it like before.
   */
  function getStagePopupZIndex(stageId:String):Dynamic
  {
    return switch (stageId)
    {
      case "xMasCityMallNastyAmTake": 118;
      default: null;
    }
  }

  override function onStateChangeEnd(event:StateChangeScriptEvent):Void
  {
    super.onStateChangeEnd(event);
    if (Std.isOfType(event.targetState, PlayState))
    {
      if (isAllowedStage()) setup();
      else teardown();
    }
  }

  override function onSubStateOpenEnd(event:SubStateScriptEvent):Void
  {
    super.onSubStateOpenEnd(event);
    if (Std.isOfType(event.targetState, PlayState))
    {
      if (isAllowedStage()) setup();
      else teardown();
    }
  }

  override function onDestroy(event:ScriptEvent):Void
  {
    super.onDestroy(event);
    teardown();
  }

  function setup():Void
  {
    var play = PlayState.instance;
    if (play == null)
      return;

    previousComboStuff = [];
    popupStates = [];
    variation = true;

    destroyPopupGroup();

    var stageId:String = (play.currentStage != null) ? play.currentStage.id : "";
    stageOffsets = getStageRatingOffset(stageId);
    var popupZ:Dynamic = getStagePopupZIndex(stageId);

    ratingPopUps = new FunkinGroup();
    ratingPopUps.customChildUpdate = true;

    if (popupZ != null && play.currentStage != null)
    {
      ratingPopUps.zIndex = popupZ;
      play.currentStage.add(ratingPopUps);
      play.currentStage.refresh();
      popupsInStage = true;
    }
    else
    {
      play.add(ratingPopUps);
      popupsInStage = false;
    }

    ratingPopUps.cameras = [play.camGame];

    if (play.comboPopUps != null)
      play.comboPopUps.visible = false;

    removePostUpdateHook();
    popupPostUpdate = applyPopupTransforms;
    FlxG.signals.postUpdate.add(popupPostUpdate);
  }

  function removePostUpdateHook():Void
  {
    if (popupPostUpdate != null)
    {
      FlxG.signals.postUpdate.remove(popupPostUpdate);
      popupPostUpdate = null;
    }
  }

  function teardown():Void
  {
    removePostUpdateHook();
    clearRatingStuff();
    destroyPopupGroup();

    var play = PlayState.instance;
    if (play != null && play.comboPopUps != null)
      play.comboPopUps.visible = true;
  }

  /**
   * True while the group can still be used. Stage.onDestroy() destroys everything inside the stage,
   * and FunkinGroup.destroy() sets `children` to null, so touching it afterwards would crash.
   */
  function isPopupGroupAlive():Bool
  {
    return ratingPopUps != null && ratingPopUps.children != null;
  }

  function destroyPopupGroup():Void
  {
    if (ratingPopUps == null)
      return;

    if (isPopupGroupAlive())
    {
      var play = PlayState.instance;
      if (play != null)
      {
        if (popupsInStage && play.currentStage != null)
          play.currentStage.remove(ratingPopUps);
        else
          play.remove(ratingPopUps);
      }
      ratingPopUps.destroy();
    }

    ratingPopUps = null;
    popupsInStage = false;
  }

  function clearRatingStuff():Void
  {
    if (!isPopupGroupAlive())
    {
      previousComboStuff = [];
      popupStates = [];
      return;
    }

    for (shit in previousComboStuff)
    {
      if (shit == null)
        continue;

      var spr:FunkinSprite = shit[0];
      if (spr == null)
        continue;

      FlxTween.cancelTweensOf(spr);
      ratingPopUps.remove(spr);
      spr.destroy();
    }

    previousComboStuff = [];
    popupStates = [];
  }

  function getRatingOffset(curRating:String):Array<Int>
  {
    return switch (curRating)
    {
      case "good": [-10, -10];
      default: [0, 0];
    }
  }

  function constructComboSprite(rating:FunkinSprite, frames):FunkinSprite
  {
    var comboSpr:FunkinSprite = new FunkinSprite();
    comboSpr.frames = frames;
    comboSpr.animation.addByPrefix("combo", "combo", 24, false);
    comboSpr.animation.play("combo");
    comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.55));
    comboSpr.updateHitbox();
    if (rating != null)
      comboSpr.setPosition((rating.x + rating.width) - comboSpr.width / 1.5, rating.y + rating.height);
    return comboSpr;
  }

  function constructComboNumberSprite(currentNumber:String, frames):FunkinSprite
  {
    var num:FunkinSprite = new FunkinSprite();
    num.frames = frames;
    num.animation.addByPrefix(currentNumber, currentNumber, 24, false);
    num.animation.play(currentNumber);
    return num;
  }

  function createRatingImg(rat:String):Void
  {
    var play = PlayState.instance;
    if (play == null || !isPopupGroupAlive())
      return;

    if (rat == null)
      rat = "good";

    var ratingsFrames = Paths.getSparrowAtlas("ui/ratings/GAMEPLAY_UI_ASSETS", "shared");
    var daRating:String = rat;
    var combo:Int = Highscore.tallies.combo;
    var dissapearTimeMult:Float = 1;

    if (daRating == "fuck up")
      dissapearTimeMult = 1.25;

    clearRatingStuff();

    blot = new FunkinSprite();
    blot.frames = ratingsFrames;
    blot.animation.addByPrefix('blot1', "blot0", 24, false);
    blot.animation.addByPrefix('blot2', "blot 2", 24, false);
    blot.x = (FlxG.width * 0.474) + offsets[0] + stageOffsets[0];
    blot.y = (FlxG.camera.height * 0.45 - 60) + offsets[1] + stageOffsets[1];
    blot.setGraphicSize(Std.int(blot.width * 0.6));
    blot.updateHitbox();
    blot.offset.x += 15;
    previousComboStuff.push([blot, true]);
    variation = !variation;
    blot.animation.play("blot" + (variation ? 1 : 2));
    if (blot.animation.curAnim.name == "blot2")
      blot.offset.y += 15;
    blot.origin.set(blot.frameWidth * .4, blot.frameHeight * .4);
    blot.angle = FlxG.random.float(-15, 15);

    if (daRating != "fuck up")
    {
      var currentColorPoint:Int = 0;
      for (i in 0...comboBlotColorsMax.length - 1)
      {
        currentColorPoint = i;
        if (combo < comboBlotColorsMax[i])
          break;
      }

      var prevMax:Int = currentColorPoint > 0 ? comboBlotColorsMax[currentColorPoint - 1] : comboBlotColorsMax[currentColorPoint];
      var cfv:Int = comboBlotColorsMax[currentColorPoint] - prevMax;
      blot.color = FlxColor.interpolate(comboBlotColors[currentColorPoint], comboBlotColors[currentColorPoint + 1],
        (combo - cfv) / (comboBlotColorsMax[currentColorPoint] - cfv));
    }
    else
      blot.color = FlxColor.GRAY;

	ModuleHandler.getModule('TimeBarModule').bar.color = blot.color;

    var rating:FunkinSprite = new FunkinSprite();
    rating.frames = ratingsFrames;
    rating.animation.addByPrefix(daRating, daRating, 24, false);
    rating.setPosition(blot.x - 100, blot.y + 35);
    rating.setGraphicSize(Std.int(rating.width * 0.55));
    rating.updateHitbox();
    previousComboStuff.push([rating, true]);
    rating.animation.play(daRating);
    var offss:Array<Int> = getRatingOffset(daRating);
    rating.offset.set(offss[0], offss[1]);

    var comboSpr:FunkinSprite = null;
    if (combo >= SHOW_COMBO_VALUE)
    {
      comboSpr = constructComboSprite(rating, ratingsFrames);
      if (daRating == "fuck up")
        comboSpr.color = FlxColor.GRAY;
      previousComboStuff.push([comboSpr, true]);
    }

    if (combo >= SHOW_COMBONUMS_VALUE)
    {
      var seperatedScore:Array<Int> = [];
      var tempCombo:Int = combo;

      while (tempCombo != 0)
      {
        seperatedScore.push(tempCombo % 10);
        tempCombo = Std.int(tempCombo / 10);
      }
      while (seperatedScore.length < 3)
        seperatedScore.push(0);

      seperatedScore.reverse();

      var daLoop:Int = 0;
      var previousNumber:FunkinSprite = null;
      for (i in seperatedScore)
      {
        var cnumber:FunkinSprite = constructComboNumberSprite(NUMBERS[i], ratingsFrames);
        var currentScale:Float = .45 + (daLoop * .1);
        cnumber.scale.set(currentScale, currentScale);
        cnumber.updateHitbox();
        cnumber.setPosition(blot.x + blot.width * .65, blot.y + blot.height * 1.25 - cnumber.height / 2 * cnumber.scale.y);
        if (previousNumber != null)
        {
          cnumber.x = previousNumber.x + previousNumber.frameWidth * .75 * previousNumber.scale.x;
          cnumber.y = previousNumber.y + (previousNumber.height / 2 * previousNumber.scale.y) - (cnumber.height / 1.725 * cnumber.scale.y);
        }

        cnumber.angularVelocity = FlxG.random.int(-15, 15);

        previousNumber = cnumber;
        if (daRating == "fuck up")
          cnumber.color = FlxColor.GRAY;
        previousComboStuff.push([cnumber, true]);
        daLoop++;
      }
    }
    else
    {
      rating.x += 50;
      rating.y += 50 - blot.offset.y / 2;
    }

    var comboColors:Array<Int> = null;
    if (Highscore.tallies.sick == Highscore.tallies.totalNotesHit && Highscore.tallies.missed == 0)
      comboColors = FlxColor.gradient(blot.color, FlxColor.WHITE, 5, FlxEase.linear);

    for (shit in previousComboStuff)
    {
      var baseShit:FunkinSprite = shit[0];
      if (baseShit == null)
        continue;

      if (shit[1])
      {
        baseShit.scrollFactor.set(.85, .85);
        baseShit.antialiasing = true;
        baseShit.angle = FlxG.random.int(-5, 5);
        baseShit.angularVelocity += FlxG.random.int(-5, 5);

        popupStates.push([
          baseShit,
          baseShit.x,
          baseShit.y,
          -FlxG.random.int(0, 10),
          -FlxG.random.int(160, 175),
          650,
          baseShit.scale.x,
          baseShit.scale.y,
          0.0
        ]);

        if (comboColors != null && baseShit != blot)
        {
          baseShit.color = comboColors[3];
          FlxTween.color(baseShit, Conductor.instance.beatLengthMs * 0.001 * dissapearTimeMult, comboColors[3], comboColors[1], {ease: FlxEase.sineOut});
        }
      }

      baseShit.cameras = [play.camGame];
      ratingPopUps.add(baseShit);

      startFade(baseShit, dissapearTimeMult);
    }

    applyPopupTransforms();
  }

  override function onUpdate(event:UpdateScriptEvent):Void
  {
    super.onUpdate(event);

    for (st in popupStates)
      st[8] = st[8] + event.elapsed;
  }

  /**
   * Moves/scales every popup for the current frame, emulating Codename's `zoomFactor`.
   *
   * Codename scales what it draws around the center of the camera by lerp(1 / zoom, 1, zoomFactor), which makes the
   * effective zoom of the sprite lerp(1, zoom, zoomFactor). Vanilla has no such thing, so the same is done here:
   * the sprite scale gets multiplied by that value and its origin point is moved around the camera center.
   */
  function applyPopupTransforms():Void
  {
    var play = PlayState.instance;
    if (play == null || play.camGame == null || popupStates.length == 0)
      return;

    try
    {
      var cam = play.camGame;
      var zoom:Float = cam.zoom;
      if (zoom <= 0)
        zoom = 1;

      var ratio:Float = 1 / zoom + (1 - 1 / zoom) * popupZoomFactor;
      var cx:Float = cam.width * 0.5;
      var cy:Float = cam.height * 0.5;

      for (st in popupStates)
      {
        var spr:FunkinSprite = st[0];
        if (spr == null || !spr.exists)
          continue;

        var t:Float = st[8];
        var lx:Float = st[1] + st[3] * t;
        var ly:Float = st[2] + st[4] * t + 0.5 * st[5] * t * t;

        var sfx:Float = spr.scrollFactor.x;
        var sfy:Float = spr.scrollFactor.y;

        var ox:Float = lx - cam.scroll.x * sfx - spr.offset.x + spr.origin.x;
        var oy:Float = ly - cam.scroll.y * sfy - spr.offset.y + spr.origin.y;

        ox = cx + (ox - cx) * ratio;
        oy = cy + (oy - cy) * ratio;

        spr.x = ox + cam.scroll.x * sfx + spr.offset.x - spr.origin.x;
        spr.y = oy + cam.scroll.y * sfy + spr.offset.y - spr.origin.y;
        spr.scale.set(st[6] * ratio, st[7] * ratio);
      }
    }
    catch (e:Dynamic)
    {
      trace("[RatingComboModule] applyPopupTransforms failed: " + e);
      popupStates = [];
    }
  }

  /**
   * Fades the sprite out after one beat and kills it when done (stops updating its physics).
   */
  function startFade(spr:FunkinSprite, delayMult:Float):Void
  {
    var beat:Float = Conductor.instance.beatLengthMs * 0.001;

    FlxTween.tween(spr, {
      alpha: 0,
      angle: spr.angle + FlxG.random.float(-16, 16)
    }, beat / 1.5, {
      ease: FlxEase.cubeOut,
      startDelay: beat * delayMult,
      onComplete: function(_:FlxTween):Void
      {
        spr.kill();
      }
    });
  }

  override function onNoteHit(event:HitNoteScriptEvent):Void
  {
    super.onNoteHit(event);
    if (PlayState.instance == null || !isPopupGroupAlive())
      return;
    if (!event.note.noteData.getMustHitNote())
      return;

    if (event.isComboBreak)
    {
      if (event.comboCount > 1)
        createRatingImg("fuck up");
      return;
    }

    createRatingImg(event.judgement);
  }

  override function onNoteMiss(event:NoteScriptEvent):Void
  {
    super.onNoteMiss(event);
    if (PlayState.instance == null || !isPopupGroupAlive())
      return;
    if (!event.note.noteData.getMustHitNote())
      return;

    if (event.comboCount > 1)
      createRatingImg("fuck up");
  }
}


class FullComboModule extends Module implements IPlayStateScriptedClass
{
	public function new()
	{
		super("FullComboModule", 200);
	}

	static var MEGA_ALLOWED_STAGES:Array<String> = [
		"mainStageAmTake",
		"serviceEnterance",
		"xMasCityMallAmTake",
		"xMasCityMallAmTakeDark",
		"xMasCityMallNastyAmTake",
		"phoneCallStreet"
	];

	function isAllowedStage():Bool
	{
		var play = PlayState.instance;
		if (play == null || play.currentStage == null) return false;
		return MEGA_ALLOWED_STAGES.indexOf(play.currentStage.id) != -1;
	}

	public var fcSprite:FullComboSpr = null;

	/** Notas seguidas acertadas desde el último corte de combo (para el bonus de score). */
	public var curNoteCombo:Int = 0;

	/** Score acumulado de esas notas (para calcular el bonus). */
	public var scoreCombo:Float = 0;

	/** true mientras la UI de FC ya fue construida para el PlayState actual. */
	public var uiReady:Bool = false;

	override public function onStateChangeEnd(event:StateChangeScriptEvent):Void
	{
		uiReady = false;
		if (Std.isOfType(event.targetState, PlayState) && isAllowedStage())
			buildFCSprite();
		super.onStateChangeEnd(event);
	}

	override public function onSubStateOpenEnd(event:SubStateScriptEvent):Void
	{
		if (Std.isOfType(event.targetState, PlayState) && isAllowedStage())
			buildFCSprite();
		super.onSubStateOpenEnd(event);
	}

	function buildFCSprite():Void
	{
		var play = PlayState.instance;
		if (play == null)
			return;

		uiReady = true;
		curNoteCombo = 0;
		scoreCombo = 0;

		fcSprite = new FullComboSpr(20);
		fcSprite.frames = Paths.getSparrowAtlas("ui/ratings/GAMEPLAY_UI_ASSETS", "shared");
		fcSprite.animation.addByPrefix("y", "full combo", 1, false);
		fcSprite.animation.play("y", true);
		fcSprite.camera = play.camHUD;
		fcSprite.zIndex = 1550;
		fcSprite.updateHitbox();
		fcSprite.y = AmScroll.isPref() ? 20 : FlxG.height - fcSprite.height;
		fcSprite.alpha = 0.0001;
		fcSprite.comboStatus = "PFC";

		play.add(fcSprite);
	}

	override public function onDestroy(event:ScriptEvent):Void
	{
		uiReady = false;
		if (fcSprite != null)
		{
			FlxTween.cancelTweensOf(fcSprite);
			fcSprite.destroy();
			fcSprite = null;
		}
		super.onDestroy(event);
	}

	override public function onSongStart(event:ScriptEvent):Void
	{
		super.onSongStart(event);
		if (fcSprite == null)
			return;

		fcSprite.revive();
		fcSprite.active = true;
		fcSprite.comboStatus = "PFC";
		fcSprite.x = 20;
		fcSprite.y = AmScroll.isPref() ? 20 : FlxG.height - fcSprite.height;
		fcSprite.alpha = 0.0001;
		curNoteCombo = 0;
		scoreCombo = 0;
	}

	override public function onNoteHit(event:HitNoteScriptEvent):Void
	{
		if (uiReady && event.note.noteData.getMustHitNote())
			onComboNoteHit(event);
		super.onNoteHit(event);
	}

	override public function onNoteMiss(event:NoteScriptEvent):Void
	{
		if (uiReady && event.note.noteData.getMustHitNote())
			onComboBreak();
		super.onNoteMiss(event);
	}

	/**
	 * Nota acertada sin romper combo: hace aparecer/actualizar el sprite de FC
	 * y decide si sigue siendo PFC o pasa a "Normal" (FC común).
	 */
	function onComboNoteHit(event:HitNoteScriptEvent):Void
	{
		if (event.isComboBreak)
		{
			onComboBreak();
			return;
		}

		curNoteCombo++;
		scoreCombo += event.score;

		if (fcSprite == null)
			return;

		if (fcSprite.active && fcSprite.alpha < .1)
		{
			fcSprite.scale.set(.55, .55);
			fcSprite.angle = -45;
			FlxTween.tween(fcSprite.scale, {x: 0.8, y: 0.8}, .25);
			FlxTween.tween(fcSprite, {angle: 0, alpha: 1}, .25);
		}

		fcSprite.comboStatus = (Highscore.tallies.sick == Highscore.tallies.totalNotesHit) ? "PFC" : "Normal";
	}

	/**
	 * Miss o corte de combo: anima el sprite saliendo de pantalla, otorga el bonus
	 * de score acumulado (igual que `spawnCombo` en el módulo original) y resetea.
	 */
	function onComboBreak():Void
	{
		if (fcSprite != null && fcSprite.active)
		{
			fcSprite.comboStatus = "Break";
			fcSprite.active = false;
			FlxTween.tween(fcSprite, {x: fcSprite.x - 150, angle: -95, alpha: 0}, .2, {
				onComplete: (_) -> fcSprite.kill()
			});
		}

		grantComboBonus();
	}

	/** Bonus de score al cortar la racha, calcado del `spawnCombo` original. */
	function grantComboBonus():Void
	{
		var play = PlayState.instance;
		if (play == null || curNoteCombo <= 7)
		{
			curNoteCombo = 0;
			scoreCombo = 0;
			return;
		}

		final bonusScore:Int = Math.round(curNoteCombo * (scoreCombo / 150));
		play.songScore += Math.round(bonusScore - (scoreCombo / 150));

		curNoteCombo = 0;
		scoreCombo = 0;
	}

	override public function onBeatHit(event:SongTimeScriptEvent):Void
	{
		super.onBeatHit(event);
		if (!uiReady || fcSprite == null || !fcSprite.active || fcSprite.alpha != 1)
			return;

		fcSprite.scale.set(0.825, 0.825);
		FlxTween.tween(fcSprite.scale, {x: 0.9, y: 0.9}, Conductor.instance.beatLengthMs / 2000);
	}
}


class FullComboSpr extends FunkinSprite
{
	public var comboStatus:String = "PFC";

	var outOff:Float = 5;

	public function new(x)
	{
		super(x, 0);
	}

	override function draw()
	{
		if (comboStatus != "Break")
		{
			offset.set(outOff, outOff);
			origin.x += outOff;
			origin.y += outOff;
			var oldAlpha = alpha;
			var oldColor = color;

			setComboColorTransform();

			super.draw();
			alpha = oldAlpha;
			color = oldColor;
			origin.x -= outOff;
			origin.y -= outOff;
			offset.set();
		}
		setColorTransform(1, 1, 1, alpha, 0, 0, 0, 0);
		super.draw();
	}

	function setComboColorTransform()
	{
		switch (comboStatus)
		{
			case "PFC":
				setColorTransform(1, 1, 0, alpha * .9, 255, 255, 0, 0);

			default:
				setColorTransform(1, 0, 1, alpha * .9, 255, 0, 255, 0);
		}
	}
}

class AlphabetPsych extends FlxTypedSpriteGroup
{
	var AlphaCharacterPsych = ScriptedFlxSprite.init('AlphaCharacterPsych');

	public var delay:Float = 0.05;
	public var paused:Bool = false;

	public var forceX:Float = Math.NEGATIVE_INFINITY;
	public var targetY:Float = 0;
	public var yMult:Float = 120;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var isMenuItem:Bool = false;
	public var textSize:Float = 1.0;

	public var text:String = "";

	var _finalText:String = "";
	var yMulti:Float = 1;

	var lastSprite:AlphaCharacterPsych;
	var xPosResetted:Bool = false;

	var splitWords:Array<String> = [];

	var isBold:Bool = false;

	public var lettersArray:Array<AlphaCharacterPsych> = [];

	public var finishedText:Bool = false;
	public var typed:Bool = false;

	public var typingSpeed:Float = 0.05;

	public function new(X, Y, _text:String = "", bold:Bool = false, isTyped:Bool = false, typedSpeed:Float = 0.01, size:Float = 1)
	{
		super(X, Y);
		forceX = Math.NEGATIVE_INFINITY;
		this.textSize = size;

		_finalText = _text;
		this.text = _text;
		this.typed = isTyped;
		isBold = bold;

		if (text != "")
			typed ? startTypedText(typedSpeed) : addText();
		else
			finishedText = true;
		trace(finishedText);
	}

	public function changeText(newText:String, newTypingSpeed:Float = -1)
	{
		for (i in 0...lettersArray.length)
		{
			var letter = lettersArray[0];
			remove(letter, true);
			lettersArray.remove(letter);
		}
		lettersArray = [];
		splitWords = [];
		loopNum = 0;
		xPos = 0;
		curRow = 0;
		consecutiveSpaces = 0;
		xPosResetted = false;
		finishedText = false;
		lastSprite = null;

		var lastX = x;
		x = 0;
		_finalText = newText;
		text = newText;
		if (newTypingSpeed != -1)
			typingSpeed = newTypingSpeed;

		if (text != "")
			typed ? startTypedText(typingSpeed) : addText();
		else
			finishedText = true;

		x = lastX;
	}

	public function addText()
	{
		doSplitWords();

		var xPos:Float = 0;
		for (character in splitWords)
		{
			var spaceChar:Bool = (character == " " || (isBold && character == "_"));
			if (spaceChar)
				consecutiveSpaces++;

			var isNumber:Bool = numbers.indexOf(character) != -1;
			var isSymbol:Bool = symbols.indexOf(character) != -1;
			var isAlphabet:Bool = alphabet.indexOf(character.toLowerCase()) != -1;
			if ((isAlphabet || isSymbol || isNumber) && (!isBold || !spaceChar))
			{
				if (lastSprite != null)
					xPos = lastSprite.x + lastSprite.width * .5;

				if (consecutiveSpaces > 0)
					xPos += 20 * consecutiveSpaces * textSize;

				consecutiveSpaces = 0;

				var letter = ScriptedFlxSprite.scriptInit('AlphaCharacterPsych', xPos, 0, textSize);

				if (isBold)
				{
					if (isNumber)
						letter.scriptCall('createBoldNumber', [character]);
					else if (isSymbol)
						letter.scriptCall('createBoldSymbol', [character]);
					else
						letter.scriptCall('createBoldLetter', [character]);
				}
				else
				{
					if (isNumber)
						letter.scriptCall('createNumber', [character]);
					else if (isSymbol)
						letter.scriptCall('createSymbol', [character]);
					else
						letter.scriptCall('createLetter', [character]);
				}

				add(letter);
				lettersArray.push(letter);

				lastSprite = letter;
			}

			loopNum += 1;
		}
	}

	function doSplitWords():Void
	{
		splitWords = _finalText.split("");
	}

	var loopNum:Int = 0;
	var xPos:Float = 0;

	public var curRow:Int = 0;

	var dialogueSound:FlxSound = null;
	var consecutiveSpaces:Int = 0;

	var typeTimer:FlxTimer = null;

	public function startTypedText(speed:Float):Void
	{
		_finalText = text;
		doSplitWords();

		speed2 = speed;

		if (speed <= 0)
		{
			while (!finishedText)
			{
				timerCheck();
			}
			if (dialogueSound != null)
				dialogueSound.stop();
			dialogueSound = FlxG.sound.play(Paths.sound('dialogue'));
		}
		else
		{
			typeTimer = new FlxTimer().start(0.1, function(tmr:FlxTimer)
			{
				typeTimer = new FlxTimer().start(speed2, function(tmr:FlxTimer)
				{
					timerCheck(tmr);
				}, 0);
			});
		}
	}

	public static var alphabet:String = "abcdefghijklmnopqrstuvwxyz";

	public static var numbers:String = "1234567890";

	public static var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!?";

	var LONG_TEXT_ADD:Float = -24;

	public function timerCheck(?tmr:FlxTimer = null)
	{
		var autoBreak:Bool = false;
		if ((loopNum <= splitWords.length - 2 && splitWords[loopNum] == "\\" && splitWords[loopNum + 1] == "n")
			|| ((autoBreak = true) && xPos >= FlxG.width * 0.65 && splitWords[loopNum] == ' '))
		{
			final toBrake = autoBreak ? 1 : 2;
			if (tmr != null)
				tmr.loops -= toBrake;
			loopNum += toBrake;

			yMulti += 1;
			xPosResetted = true;
			xPos = 0;
			curRow += 1;
			if (curRow == 2)
				y += LONG_TEXT_ADD;
		}

		if (loopNum <= splitWords.length && splitWords[loopNum] != null)
		{
			var spaceChar:Bool = (splitWords[loopNum] == " " || (isBold && splitWords[loopNum] == "_"));
			if (spaceChar)
				consecutiveSpaces++;

			var isNumber:Bool = numbers.indexOf(splitWords[loopNum]) != -1;
			var isSymbol:Bool = symbols.indexOf(splitWords[loopNum]) != -1;
			var isAlphabet:Bool = alphabet.indexOf(splitWords[loopNum].toLowerCase()) != -1;

			if ((isAlphabet || isSymbol || isNumber) && (!isBold || !spaceChar))
			{
				if (lastSprite != null && !xPosResetted)
				{
					lastSprite.updateHitbox();
					xPos += lastSprite.width * lastSprite.scale.x;

				}
				else
					xPosResetted = false;

				xPos += 10 * consecutiveSpaces * textSize;

				consecutiveSpaces = 0;

				var letter = ScriptedFlxSprite.scriptInit('AlphaCharacterPsych', xPos, 55 * yMulti, textSize);
				letter.scriptSet('row', curRow);
				var boldSuffix = isBold ? "Bold" : "";
				if (isNumber)
				{
					letter.scriptCall('create' + boldSuffix + 'Number', [splitWords[loopNum]]);
				}
				else if (isSymbol)
				{
					letter.scriptCall('create' + boldSuffix + 'Symbol', [splitWords[loopNum]]);
				}
				else
				{
					letter.scriptCall('create' + boldSuffix + 'Letter', [splitWords[loopNum]]);
				}
				letter.x += 10;

				if (tmr != null)
				{
					if (dialogueSound != null)
						dialogueSound.stop();
					dialogueSound = FlxG.sound.play(Paths.sound('dialogue'));
				}

				add(letter);

				lastSprite = letter;
			}
		}

		loopNum++;
		if (loopNum >= splitWords.length)
		{
			if (tmr != null)
			{
				typeTimer = null;
				tmr.cancel();
				tmr.destroy();
			}
			finishedText = true;
		}
	}

	override function update(elapsed:Float)
	{
		if (isMenuItem)
		{
			var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);

			var lerpVal:Float = CoolUtil.boundTo(elapsed * 9.6, 0, 1);
			y = FlxMath.lerp(y, (scaledY * yMult) + (FlxG.height * 0.48) + yAdd, lerpVal);
			x = (forceX != Math.NEGATIVE_INFINITY) ? forceX : FlxMath.lerp(x, (targetY * 20) + 90 + xAdd, lerpVal);
		}

		super.update(elapsed);
	}

	public function killTheTimer()
	{
		if (typeTimer != null)
		{
			typeTimer.cancel();
			typeTimer.destroy();
		}
		typeTimer = null;
	}
}

class AlphaCharacterPsych extends FlxSprite
{
	public var row:Int = 0;

	private var textSize:Float = 1;

	public function new(x:Float, y:Float, textSize:Float)
	{
		super(x, y);
		var tex = Paths.getSparrowAtlas('fonts/alphabet-white');
		frames = tex;

		setGraphicSize(Std.int(width * textSize));
		updateHitbox();
		this.textSize = textSize;
		antialiasing = true;
	}

	public function createBoldLetter(letter:String)
	{
		animation.addByPrefix(letter, letter.toUpperCase() + " bold", 24);
		animation.play(letter);
		updateHitbox();
	}

	public function createBoldNumber(letter:String):Void
	{
		animation.addByPrefix(letter, "bold" + letter, 24);
		animation.play(letter);
		updateHitbox();
	}

	public function createBoldSymbol(letter:String)
	{
		switch (letter)
		{
			case '.':
				animation.addByPrefix(letter, 'PERIOD bold', 24);
			case "'":
				animation.addByPrefix(letter, 'APOSTRAPHIE bold', 24);
			case "?":
				animation.addByPrefix(letter, 'QUESTION MARK bold', 24);
			case "!":
				animation.addByPrefix(letter, 'EXCLAMATION POINT bold', 24);
			case "(":
				animation.addByPrefix(letter, 'bold (', 24);
			case ")":
				animation.addByPrefix(letter, 'bold )', 24);
			default:
				animation.addByPrefix(letter, 'bold ' + letter, 24);
		}
		animation.play(letter);
		updateHitbox();
		switch (letter)
		{
			case "'":
				y -= 20 * textSize;
			case '-':
				y += 20 * textSize;
			case '(':
				x -= 65 * textSize;
				y -= 5 * textSize;
				offset.x = -58 * textSize;
			case ')':
				x -= 20 / textSize;
				y -= 5 * textSize;
				offset.x = 12 * textSize;
			case '.':
				y += 45 * textSize;
				x += 5 * textSize;
				offset.x += 3 * textSize;
		}
	}

	public function createLetter(letter:String):Void
	{
		animation.addByPrefix(letter, letter, 24);
		animation.play(letter);
		updateHitbox();

		y = (110 - height);
		y += row * 60;
	}

	public function createNumber(letter:String):Void
	{
		animation.addByPrefix(letter, letter, 24);
		animation.play(letter);

		updateHitbox();

		y = (110 - height);
		y += row * 60;
	}

	public function createSymbol(letter:String)
	{
		switch (letter)
		{
			case '#':
				animation.addByPrefix(letter, 'hashtag', 24);
			case '.':
				animation.addByPrefix(letter, '.', 24);
			case "'":
				animation.addByPrefix(letter, 'apostraphie', 24);
				y -= 50;
			case "?":
				animation.addByPrefix(letter, 'question mark', 24);
			case "!":
				animation.addByPrefix(letter, 'exclamation point', 24);
			case ",":
				animation.addByPrefix(letter, 'comma', 24);
			default:
				animation.addByPrefix(letter, letter, 24);
		}
		animation.play(letter);

		updateHitbox();

		y = (110 - height);
		y += row * 60;
		switch (letter)
		{
			case "'":
				y -= 20;
			case '-':
				y -= 16;
		}
	}
}

class BfWHGameOver extends Module implements IPlayStateScriptedClass
{
	function new()
	{
		super('BfWHGameOver', 0);
	}

	final gameoverSuffix = "-wh";
	var activeGameover:Bool = false;
	public override function onGameOver(event:ScriptEvent)
	{
		var play = PlayState.instance;
		if (play != null && !play.isMinimalMode)
			activeGameover = (play.currentStage?.getBoyfriend()?.characterId == "bf-christmas" && play.currentStage?.getOpponent()?.characterId == "monster-plant");
		else
			activeGameover = false;

		if (activeGameover)
		{
			GameOverSubState.musicSuffix += gameoverSuffix;
			GameOverSubState.blueBallSuffix += gameoverSuffix;
			GameOverSubState.animationSuffix += gameoverSuffix;
		}
	}

	override function onSubStateOpenEnd(event)
	{
		if (event.targetState is GameOverSubState && activeGameover)
		{
			var play = PlayState.instance;
			if (play == null) return;

			GameOverSubState.instance.cameraFollowPoint.x -= 250;
			GameOverSubState.instance.cameraFollowPoint.y -= 375;
		}
	}
	override function onSubStateCloseBegin(event)
	{
		if (event.targetState is GameOverSubState && activeGameover)
		{
			GameOverSubState.musicSuffix = StringTools.stripSuffix(GameOverSubState.musicSuffix, gameoverSuffix);
			GameOverSubState.blueBallSuffix = StringTools.stripSuffix(GameOverSubState.blueBallSuffix, gameoverSuffix);
			GameOverSubState.animationSuffix = StringTools.stripSuffix(GameOverSubState.animationSuffix, gameoverSuffix);
			activeGameover = false;
		}
	}
}

class AmtakeXmas extends NoteStyle
{
  var HOLD_COVER_ZINDEX:Int = 5;

  public function new()
  {
    super('amtake-xmas');
  }

  override function buildHoldCoverSprite(target:NoteHoldCover):Void
  {
    super.buildHoldCoverSprite(target);

    sendHoldCoversBelowStrum();
  }

  function sendHoldCoversBelowStrum()
  {
    var ps = PlayState.instance;
    if (ps == null || ps.playerStrumline == null || ps.opponentStrumline == null) return;

    var covers = ps.playerStrumline.noteHoldCovers;
    if (covers == null || covers.zIndex == HOLD_COVER_ZINDEX) return;
    var coversOpp = ps.opponentStrumline.noteHoldCovers;
    if (coversOpp == null || coversOpp.zIndex == HOLD_COVER_ZINDEX) return;

    covers.zIndex = HOLD_COVER_ZINDEX;
    coversOpp.zIndex = HOLD_COVER_ZINDEX;
    ps.playerStrumline.refresh();
    ps.opponentStrumline.refresh();
  }
}

class AmTakeBase extends NoteStyle implements IScriptedClass
{
  var HOLD_COVER_ZINDEX:Int = 5;

  public function new()
  {
    super('amtake-base');
  }

  override function buildHoldCoverSprite(target:NoteHoldCover):Void
  {
    super.buildHoldCoverSprite(target);

    sendHoldCoversBelowStrum();
  }

  function sendHoldCoversBelowStrum()
  {
    var ps = PlayState.instance;
    if (ps == null || ps.playerStrumline == null || ps.opponentStrumline == null) return;

    var covers = ps.playerStrumline.noteHoldCovers;
    if (covers == null || covers.zIndex == HOLD_COVER_ZINDEX) return;
    var coversOpp = ps.opponentStrumline.noteHoldCovers;
    if (coversOpp == null || coversOpp.zIndex == HOLD_COVER_ZINDEX) return;

	covers.zIndex = HOLD_COVER_ZINDEX;
    coversOpp.zIndex = HOLD_COVER_ZINDEX;
    ps.playerStrumline.refresh();
    ps.opponentStrumline.refresh();
  }
}

class ZoomCameraClassicLerpModule extends Module
{
  static final DEFAULT_ZOOM:Float = 1.0;
  static final DEFAULT_WIDESCREEN_SCALE:Float = 0.0;
  static final DEFAULT_DURATION:Float = 4.0;
  static final DEFAULT_MODE:String = 'direct';

  static final SNAP_THRESHOLD:Float = 0.0015;

  var lerping:Bool = false;
  var lerpTargetZoom:Float = FlxCamera.defaultZoom;
  var lerpDuration:Float = 0.5;

  public function new()
  {
    super('ZoomCameraClassicLerpModule', 200);
  }

  override public function onSongEvent(event:SongEventScriptEvent):Void
  {
    super.onSongEvent(event);

    if (event.eventData == null || event.eventData.eventKind != 'ZoomCamera') return;

    var ease:String = event.eventData.getString('ease');
    if (ease != 'classicLerp')
    {
      lerping = false;
      return;
    }

    if (PlayState.instance == null || PlayState.instance.currentStage == null) return;
    if (PlayState.instance.isMinimalMode) return;

    var zoom:Float = event.eventData.getFloat('zoom');
    if (zoom == null) zoom = DEFAULT_ZOOM;

    var widescreenScaleX:Float = event.eventData.getFloat('widescreenScaleX');
    if (widescreenScaleX == null) widescreenScaleX = DEFAULT_WIDESCREEN_SCALE;
    var widescreenScaleY:Float = event.eventData.getFloat('widescreenScaleY');
    if (widescreenScaleY == null) widescreenScaleY = DEFAULT_WIDESCREEN_SCALE;

    var scaledZoom:Float = zoom + (zoom * calculateScale(FullScreenScaleMode.wideScale, FlxPoint.get(widescreenScaleX, widescreenScaleY)));

    var duration:Float = event.eventData.getFloat('duration');
    if (duration == null) duration = DEFAULT_DURATION;

    var mode:String = event.eventData.getString('mode');
    if (mode == null) mode = DEFAULT_MODE;
    var isDirectMode:Bool = mode == 'direct';

    event.cancelEvent();

    PlayState.instance.cancelCameraZoomTween();

    lerpTargetZoom = scaledZoom * (isDirectMode ? FlxCamera.defaultZoom : PlayState.instance.stageZoom);

    var durSeconds:Float = Conductor.instance.stepLengthMs * duration / Constants.MS_PER_SEC;
    lerpDuration = durSeconds > 0 ? durSeconds : 0.5;

    if (durSeconds <= 0)
    {
      PlayState.instance.currentCameraZoom = lerpTargetZoom;
      lerping = false;
    }
    else
    {
      lerping = true;
    }
  }

  override public function onUpdate(event:UpdateScriptEvent):Void
  {
    super.onUpdate(event);

    if (!lerping) return;
    if (PlayState.instance == null || PlayState.instance.shouldSubstatePause) return;

    var current:Float = PlayState.instance.currentCameraZoom;
    var next:Float = MathUtil.smoothLerpPrecision(current, lerpTargetZoom, FlxG.elapsed, lerpDuration, 0.01);
    next = MathUtil.snap(next, lerpTargetZoom, SNAP_THRESHOLD);

    PlayState.instance.currentCameraZoom = next;

    if (next == lerpTargetZoom) lerping = false;
  }

  override public function onSongRetry(event:SongRetryEvent):Void
  {
    super.onSongRetry(event);
    lerping = false;
  }

  override public function onStateChangeBegin(event:StateChangeScriptEvent):Void
  {
    super.onStateChangeBegin(event);
    lerping = false;
  }

  function calculateScale(wideScale:FlxPoint, scale:FlxPoint):Float
  {
    return (wideScale.x - 1) * scale.x + (wideScale.y - 1) * scale.y;
  }
}

class FocusCameraStagePointModule extends Module
{
	function new()
	{
		super("FocusCameraStagePoint", 10);
	}

	function hasCameraPoint(data:Dynamic):Bool
	{
		var point:String = data.getString("stagePoint");
		if (point == null || point == "" || point == "NONE")
			point = data.getString("cameraPoint");
		return point != null && point != "" && point != "NONE";
	}

	function easeHasDirection(ease:String):Bool
	{
		var low:String = ease.toLowerCase();
		return low.substr(low.length - 5) == "inout" || low.substr(low.length - 3) == "out" || low.substr(low.length - 2) == "in";
	}

	override function onSongEvent(event:SongEventScriptEvent):Void
	{
		var data = event.eventData;
		if (data.eventKind != "FocusCamera")
			return;

		if (!hasCameraPoint(data))
			return;

		var state = PlayState.instance;
		if (state == null || state.currentStage == null || state.isMinimalMode)
			return;

		var targetX:Null<Float> = data.getFloat("x");
		if (targetX == null)
			targetX = 0.0;
		var targetY:Null<Float> = data.getFloat("y");
		if (targetY == null)
			targetY = 0.0;

		var duration:Null<Float> = data.getFloat("duration");
		if (duration == null)
			duration = 4.0;

		var ease:String = data.getString("ease");
		if (ease == null)
			ease = "CLASSIC";

		var easeDir:String = data.getString("easeDir");
		if (easeDir == null)
			easeDir = "In";
		if (easeHasDirection(ease) || ease == "linear")
			easeDir = "";

		var easeFunction = null;
		if (ease != "CLASSIC" && ease != "INSTANT")
		{
			easeFunction = Reflect.field(FlxEase, ease + easeDir);
			if (easeFunction == null)
			{
				trace("[FocusCameraStagePoint] Ease invalido: " + ease + easeDir);
				return;
			}
		}

		event.cancelEvent();
		data.activated = true;

		switch (ease)
		{
			case "CLASSIC":
				state.resetCamera(false, false, false);
				state.cancelCameraFollowTween();
				state.cameraFollowPoint.setPosition(targetX, targetY);

			case "INSTANT":
				state.tweenCameraToPosition(targetX, targetY, 0);

			default:
				var durSeconds:Float = Conductor.instance.stepLengthMs * duration / Constants.MS_PER_SEC;
				state.tweenCameraToPosition(targetX, targetY, durSeconds, easeFunction);
		}
	}
}

class Week1AmTakeLevel extends Level
{
  var chromaShader:FlxRuntimeShader = null;

  public function new()
  {
    super('week1Animania');
  }

  /**
   * Crea (una sola vez) el shader y actualiza `bg_col` con el color de fondo del nivel.
   */
  function getChromaShader():FlxRuntimeShader
  {
    if (chromaShader == null)
    {
      chromaShader = new FlxRuntimeShader(Assets.getText(Paths.frag('chromaKey')));
    }

    var r:Float = 0.5;
    var g:Float = 0.5;
    var b:Float = 0.5;

    if (isBackgroundSimple())
    {
      var c:Int = getBackgroundColor();
      r = ((c >> 16) & 0xFF) / 255;
      g = ((c >> 8) & 0xFF) / 255;
      b = (c & 0xFF) / 255;
    }

    chromaShader.setFloatArray('bg_col', [r, g, b]);
    return chromaShader;
  }

  /**
   * Construye los props con el comportamiento vanilla y les asigna el shader.
   * Se vuelve a llamar cada vez que se selecciona este nivel en el menu.
   */
  public override function buildProps(?existingProps:Array<LevelProp>):Array<LevelProp>
  {
    var props:Array<LevelProp> = super.buildProps(existingProps);
    var shader:FlxRuntimeShader = getChromaShader();

    for (prop in props)
    {
      if (prop == null) continue;
      prop.shader = shader;
    }

    return props;
  }
}

class Week1AnimaniaPropCleanup extends Module
{
  static final TARGET_LEVEL:String = 'week1Animania';
  static final WEEK5LEVEL:String = 'week5Animania';

  var lastLevelId:String = null;

  public function new()
  {
    super('week1AnimaniaPropCleanup', 1000);
  }

  public override function onUpdate(event:UpdateScriptEvent):Void
  {
    super.onUpdate(event);

    var state = FlxG.state;
    if (state == null || !Std.isOfType(state, StoryMenuState))
    {
      lastLevelId = null;
      return;
    }

    var levelId:String = Reflect.getProperty(state, 'currentLevelId');
    if (levelId == lastLevelId) return;
    lastLevelId = levelId;

    if (levelId == TARGET_LEVEL) return;
	if (levelId == WEEK5LEVEL) return;

    var levelProps = Reflect.getProperty(state, 'levelProps');
    if (levelProps == null) return;

    for (prop in levelProps.members)
    {
      if (prop == null || prop.shader == null) continue;

      var src:String = prop.shader.glFragmentSource;
      if (src != null && src.indexOf('bg_col') != -1) prop.shader = null;
    }
  }
}

class Week5AmTakeLevel extends Level
{
  var chromaShader:FlxRuntimeShader = null;

  public function new()
  {
    super('week5Animania');
  }

  function getChromaShader():FlxRuntimeShader
  {
    if (chromaShader == null)
    {
      chromaShader = new FlxRuntimeShader(Assets.getText(Paths.frag('chromaKey')));
    }

    var r:Float = 0.5;
    var g:Float = 0.5;
    var b:Float = 0.5;

    if (isBackgroundSimple())
    {
      var c:Int = getBackgroundColor();
      r = ((c >> 16) & 0xFF) / 255;
      g = ((c >> 8) & 0xFF) / 255;
      b = (c & 0xFF) / 255;
    }

    chromaShader.setFloatArray('bg_col', [r, g, b]);
    return chromaShader;
  }

  public override function buildProps(?existingProps:Array<LevelProp>):Array<LevelProp>
  {
    var props:Array<LevelProp> = super.buildProps(existingProps);
    var shader:FlxRuntimeShader = getChromaShader();

    for (prop in props)
    {
      if (prop == null) continue;
      prop.shader = shader;
    }

    return props;
  }
}

class KomiCantCommunicateLevel extends Level
{
	function new()
	{
		super('KomiCantCommunicate');
	}

	override function isVisible():Bool
	{
		return false;
	}
}

class HoldNoteAlphaModule extends Module
{
  var HOLD_ALPHA:Float = 0.7;

  function new()
  {
    super('HoldNoteAlphaModule', 1000);
  }

  function isTargetStyle():Bool
  {
    var play:PlayState = PlayState.instance;
    if (play == null) return false;
    if (play.currentChart == null) return false;

    var id:String = play.currentChart.noteStyle;
    return id == 'amtake-base' || id == 'amtake-xmas';
  }

  function applyAlpha(strumline:Dynamic):Void
  {
    if (strumline == null) return;

    applyToGroup(strumline.holdNotes);

    applyToGroup(Reflect.field(strumline, 'holdNotesVwoosh'));
  }

  function applyToGroup(group:Dynamic):Void
  {
    if (group == null) return;

    for (hold in group.members)
    {
      if (hold == null || !hold.alive) continue;

      if (hold.alpha <= 0) continue;

      if (hold.alpha != HOLD_ALPHA) hold.alpha = HOLD_ALPHA;
    }
  }

  override function onUpdate(event:UpdateScriptEvent):Void
  {
    super.onUpdate(event);

    if (!isTargetStyle()) return;

    var play:PlayState = PlayState.instance;
    applyAlpha(play.playerStrumline);
    applyAlpha(play.opponentStrumline);
  }
}