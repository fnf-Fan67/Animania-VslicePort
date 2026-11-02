package animania.characters.komi;

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
