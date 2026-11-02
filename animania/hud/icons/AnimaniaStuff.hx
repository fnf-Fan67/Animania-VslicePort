package animania.hud.icons;

class AnimaniaStuff extends Module
{
	var DEATH_THRESHOLD:Float = 0.125 * 2;
	var LOSING_THRESHOLD:Float = 0.25 * 2;
	var WINING_THRESHOLD:Float = 0.8 * 2;

	var ICON_POSITION_OFFSET:Float = 26;

	var oldSpr:FunkinSprite = null;

	var BANNED_NOTEKINDS:Array<String> = [];

	var amTakeIcons:Array<Dynamic> = [];

	public static var MEGA_ALLOWED_STAGES:Array<String> = [
		"mainStageAmTake",
		"serviceEnterance",
		"xMasCityMallAmTake",
		"xMasCityMallAmTakeDark",
		"xMasCityMallNastyAmTake",
		"phoneCallStreet"
	];

	public function isAllowedStage():Bool
	{
		var play = PlayState.instance;
		if (play == null || play.currentStage == null) return false;
		return MEGA_ALLOWED_STAGES.indexOf(play.currentStage.id) != -1;
	}

	// true si AnimaniaModule ya está colocando y dimensionando los iconos (así no se pelean por la posición).
	function amHudActive():Bool
	{
		var am = ModuleHandler.getModule("AnimaniaModule");
		if (am == null)
			return false;
		var active:Bool = false;
		try
		{
			active = am.scriptGet("usingAmTakeUI") == true;
		}
		catch (e:Dynamic)
		{
			active = false;
		}
		return active;
	}

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
		if (!isAllowedStage()) return;
		hideNativeCountdownSprite(event.step);
		showCountdownGraphic(event.step);
	}

	function onCountdownEnd(event:CountdownScriptEvent):Void
	{
		if (!isAllowedStage()) return;
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
		if (!isAllowedStage()) return ic;

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
		if (!isAllowedStage()) return ic;

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
		if (!isAllowedStage()) return;

		var state = PlayState.instance;
		if (state == null || state.healthBar == null) return;

		var amPositions:Bool = amHudActive();

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
			if (!amPositions) updateAmTakeIconPosition(icon, entry.isPlayer);
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
