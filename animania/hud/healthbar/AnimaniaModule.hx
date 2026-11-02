package animania.hud.healthbar;

class AnimaniaModule extends Module
{
	var BANNED_NOTEKINDS = ["noAnimation", "noanim", "parents-miss", "solotime"];

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

	var ICON_Y_OFFSET:Float = 0;

	var ICON_IGNORE_OFFSET_Y:Bool = true;

	var ICON_CENTER_DX:Float = 60;
	var ICON_IGNORE_OFFSET_X:Bool = true;

	var CURVE_CENTER:Array<Float> = [11.3, 11.3, 11.3, 12.3, 13.6, 14.7, 15.8, 16.9, 17.8, 18.7, 19.5, 20.5, 21.4, 21.6, 22.5, 22.6, 23.5, 23.5, 24.1, 24.5, 24.5, 25.0, 25.0, 25.0, 24.9, 24.5, 24.5, 24.1, 23.6, 23.5, 22.9, 22.5, 21.9, 21.5, 20.6, 19.8, 19.1, 18.4, 17.4, 16.4, 15.3, 14.1, 12.9, 11.7, 11.7, 11.7, 11.7];
	var CURVE_STEP:Float = 16;

	var ICON_CURVE_FOLLOW:Float = 1.4;
	var CURVE_MID:Float = 25;
	var CURVE_IMG_W:Float = 728;
	var CURVE_IMG_H:Float = 37;

	var lockedIcons:Array<Dynamic> = [];

	var camX:Float = 25.0;
	var camY:Float = 25.0;

	var ICON_BASE_SIZE:Float = 125;
	var ICON_BOP_SCALE:Float = 0.2;
	var POSITION_OFFSET:Int = -5;

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

	function allowedHUD():Bool
	{
		return isAllowedStage();
	}

	public function lockIcon(icon):Void
	{
		if (icon != null && lockedIcons.indexOf(icon) == -1)
			lockedIcons.push(icon);
	}

	public function unlockIcon(icon):Void
	{
		lockedIcons.remove(icon);
	}

	function isIconLocked(icon):Bool
	{
		return lockedIcons.indexOf(icon) != -1;
	}

	public function applyIconSize(icon, px:Float):Void
	{
		if (icon == null)
			return;
		var fw:Float = icon.frameWidth;
		var fh:Float = icon.frameHeight;
		if (fw <= 1 || fh <= 1)
		{
			fw = 150;
			fh = 150;
		}
		var s:Float = (fw > fh) ? (px * icon.size.x) / fw : (px * icon.size.y) / fh;
		icon.scale.set(s, s);
		icon.updateHitbox();
	}

	function curveCenterOffset(localX:Float, flipped:Bool):Float
	{
		var t:Float = FlxMath.bound(localX, 0, CURVE_IMG_W - 1) / CURVE_STEP;
		var i:Int = Std.int(t);
		if (i > CURVE_CENTER.length - 2)
			i = CURVE_CENTER.length - 2;
		var f:Float = t - i;
		var c:Float = CURVE_CENTER[i] + (CURVE_CENTER[i + 1] - CURVE_CENTER[i]) * f;
		c = CURVE_MID + (c - CURVE_MID) * ICON_CURVE_FOLLOW;
		return flipped ? (CURVE_IMG_H - 1 - c) : c;
	}

	function getBarEdge():Array<Float>
	{
		var bar = PlayState.instance.healthBar;
		var mod = getBarModule();
		if (mod != null && mod.built == true && mod.bg != null && mod.redBar != null)
		{
			var pct = FlxMath.bound(bar.percent, 0, 100);
			var ex:Float = mod.redBar.x + mod.fillWidth * (1 - pct / 100);
			return [ex, mod.redBar.y + curveCenterOffset(ex - mod.redBar.x, mod.redBar.flipY)];
		}
		return [bar.x + bar.width * (FlxMath.remapToRange(bar.value, 0, 2, 100, 0) * 0.01), bar.y + bar.height / 2];
	}

	public function getIconHome(icon, isPlayer:Bool):Array<Float>
	{
		var play = PlayState.instance;
		if (play == null || play.healthBar == null || icon == null)
			return [0.0, 0.0];
		var edge = getBarEdge();
		var cx:Float = isPlayer ? (edge[0] + ICON_CENTER_DX) : (edge[0] - ICON_CENTER_DX);
		var x:Float = cx - (icon.width / 2);
		if (ICON_IGNORE_OFFSET_X)
			x += icon.iconOffset.x;
		var offY:Float = AmScroll.isDown() ? -ICON_Y_OFFSET : ICON_Y_OFFSET;
		var y:Float = edge[1] + offY - (icon.height / 2);
		if (ICON_IGNORE_OFFSET_Y)
			y += icon.iconOffset.y;
		return [x, y];
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
		if (PlayState.instance == null || !isAllowedStage())
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
		unlockAllIcons();
	}

	override function onSongRetry(event)
	{
		super.onSongRetry(event);
		unlockAllIcons();
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
		lockedIcons = [];
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
		lockedIcons = [];
		dropIconPost();
		super.onDestroy(event);
	}

	var iconPostFn:Dynamic = null;

	function ensureIconPost():Void
	{
		if (iconPostFn != null)
			return;
		iconPostFn = function()
		{
			placeIconsNow();
		};
		FlxG.signals.postUpdate.add(iconPostFn);
	}

	function dropIconPost():Void
	{
		if (iconPostFn == null)
			return;
		FlxG.signals.postUpdate.remove(iconPostFn);
		iconPostFn = null;
	}

	function placeIconsNow():Void
	{
		if (!usingAmTakeUI)
			return;

		var play = PlayState.instance;
		if (play == null || play.healthBar == null)
			return;

		for (i in 0...2)
		{
			var icon = (i == 0) ? play.iconP1 : play.iconP2;
			if (icon == null || !icon.exists || isIconLocked(icon))
				continue;

			var home = getIconHome(icon, i == 0);
			icon.x = home[0];
			icon.y = home[1];
		}
	}

	public function unlockAllIcons():Void
	{
		lockedIcons = [];
	}

	function loadAmTakeUI():Void
	{
		var play = PlayState.instance;
		if (play == null || isPixelNoteStyle() || !allowedHUD())
			return;

		usingAmTakeUI = true;
		ensureIconPost();
		bopP1 = 0;
		bopP2 = 0;
		barDadId = null;
		barBfId = null;
		barColorMap = null;
		barNeedsPaint = true;

		for (icon in [play.iconP1, play.iconP2])
		{
			if (icon == null)
				continue;
			icon.bopEvery = 0;
			if (icon.bopTween != null)
				icon.bopTween.cancel();
			applyIconSize(icon, ICON_BASE_SIZE);
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
		barDadId = null;
		barBfId = null;
		refreshBarColors();
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

		mod.redBar.color = barDadApplied;
		mod.greenBar.color = barBfApplied;
		barNeedsPaint = false;
	}

	static var BAR_COLOR_FILE:String = "healthbarColors/colorData";

	var barDadApplied:Int = Constants.COLOR_HEALTH_BAR_RED;
	var barBfApplied:Int = Constants.COLOR_HEALTH_BAR_GREEN;
	var barDadId:String = null;
	var barBfId:String = null;
	var barColorMap:StringMap = null;

	function parseBarColor(v:Dynamic):Dynamic
	{
		if (v == null)
			return null;

		var r:Dynamic = null;
		var g:Dynamic = null;
		var b:Dynamic = null;

		if (Std.isOfType(v, String))
		{
			var hex:String = StringTools.replace(StringTools.trim(v), "#", "");
			if (hex.length != 6)
				return null;
			var n:Dynamic = Std.parseInt("0x" + hex);
			if (n == null)
				return null;
			r = (n >> 16) & 0xFF;
			g = (n >> 8) & 0xFF;
			b = n & 0xFF;
		}
		else if (Std.isOfType(v, Array))
		{
			if (v.length < 3)
				return null;
			r = v[0];
			g = v[1];
			b = v[2];
		}
		else
		{
			r = Reflect.field(v, "r");
			g = Reflect.field(v, "g");
			b = Reflect.field(v, "b");
		}

		if (r == null || g == null || b == null)
			return null;

		return {
			color: FlxColor.fromRGB(Std.int(FlxMath.bound(r, 0, 255)), Std.int(FlxMath.bound(g, 0, 255)), Std.int(FlxMath.bound(b, 0, 255)))
		};
	}

	function loadBarColorMap():Void
	{
		barColorMap = new StringMap();

		try
		{
			var path:String = Paths.json(BAR_COLOR_FILE);
			if (!Assets.exists(path))
				return;

			var d:Dynamic = Json.parse(Assets.getText(path));
			var chars:Dynamic = Reflect.field(d, "characters");
			var colors:Dynamic = Reflect.field(d, "colors");
			if (chars == null || colors == null)
			{
				trace("[healthbarColors] colorData.json necesita 'characters' y 'colors'");
				return;
			}

			for (key in Reflect.fields(chars))
			{
				var parsed:Dynamic = parseBarColor(Reflect.field(colors, key));
				if (parsed == null)
				{
					trace("[healthbarColors] la clave '" + key + "' no tiene un color valido en 'colors'");
					continue;
				}

				var ids:Dynamic = Reflect.field(chars, key);
				var list:Array<Dynamic> = Std.isOfType(ids, Array) ? ids : [ids];
				for (id in list)
				{
					if (id != null && Std.isOfType(id, String))
						barColorMap.set(id, parsed.color);
				}
			}
		}
		catch (e:Dynamic)
		{
			trace("[healthbarColors] no se pudo leer colorData.json: " + e);
		}
	}

	function readBarColor(id:String):Dynamic
	{
		if (id == null || id == "")
			return null;
		if (barColorMap == null)
			loadBarColorMap();
		return barColorMap.exists(id) ? {color: barColorMap.get(id)} : null;
	}

	function refreshBarColors():Void
	{
		var play = PlayState.instance;
		if (play == null || play.currentStage == null)
			return;

		var bf = play.currentStage.getBoyfriend();
		var dad = play.currentStage.getDad();
		var bfId:String = (bf != null) ? bf.characterId : null;
		var dadId:String = (dad != null) ? dad.characterId : null;

		if (bfId == barBfId && dadId == barDadId)
			return;

		barBfId = bfId;
		barDadId = dadId;

		var dadJson:Dynamic = readBarColor(dadId);
		var bfJson:Dynamic = readBarColor(bfId);
		barDadApplied = (dadJson != null) ? dadJson.color : barDadColor;
		barBfApplied = (bfJson != null) ? bfJson.color : barBfColor;
		barNeedsPaint = true;
	}

	override function onUpdate(event)
	{
		super.onUpdate(event);

		var play = PlayState.instance;
		if (play == null || play.isGamePaused || !isAllowedStage())
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

		refreshBarColors();
		tryPaintBar();

		updateHealthIcons(event.elapsed);
	}

	function updateHealthIcons(elapsed:Float):Void
	{
		var play = PlayState.instance;
		var bar = play.healthBar;

		var lerpHealth = bar.value;
		var bopDuration:Float = Math.max(Math.min(Conductor.instance.stepLengthMs * 0.002, 0.175), 0.01);

		for (i in 0...2)
		{
			var icon = (i == 0) ? play.iconP1 : play.iconP2;
			if (icon == null || isIconLocked(icon))
				continue;

			var bop:Float = (i == 0) ? bopP1 : bopP2;
			if (bop > 0)
				bop = Math.max(bop - elapsed / bopDuration, 0);
			if (i == 0)
				bopP1 = bop;
			else
				bopP2 = bop;

			applyIconSize(icon, ICON_BASE_SIZE * (1 + ICON_BOP_SCALE * bop));

			var home = getIconHome(icon, i == 0);
			icon.x = home[0];
			icon.y = home[1];

			var targetAngle:Float = 0;
			if (i == 0)
			{
				if (lerpHealth < .25)
					targetAngle = 50 * (.25 - lerpHealth);
			}
			else
			{
				if (lerpHealth > 1.75)
					targetAngle = -30 * (lerpHealth - 1.75);
			}

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
			if (icon == null || isIconLocked(icon))
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
		if (play == null || play.isMinimalMode || !isAllowedStage())
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
