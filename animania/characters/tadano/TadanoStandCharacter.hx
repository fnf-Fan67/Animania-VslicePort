package animania.characters.tadano;

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
