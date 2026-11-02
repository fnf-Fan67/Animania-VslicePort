package animania.characters.tadano;

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
