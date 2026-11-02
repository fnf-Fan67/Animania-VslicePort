package animania.hud.healthbar;

class CurvedHealthBarModule extends Module implements IPlayStateScriptedClass
{
	static inline var BG_ASSET:String = "ui/healthbar/HEALTHBAR";
	static inline var FILL_ASSET:String = "ui/healthbar/WHITEBAR";

	static inline var COLOR_GREEN:FlxColor = 0xFF66FF33;
	static inline var COLOR_RED:FlxColor = 0xFFFF0000;

	static inline var BAR_INSET_X:Float = 20;
	static inline var BAR_INSET_Y:Float = 8;

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
	var fillWidth:Float = 774;
	var fillHeight:Float = 51;

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

		var newBar:FlxBar = new FlxBar(fillX, fillY + (fillHeight / 2) - 15, FlxBarFillDirection.RIGHT_TO_LEFT, Std.int(fillWidth), Std.int(fillHeight), play, "healthLerp",
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
			bar.setPosition(fillX, fillY);
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
