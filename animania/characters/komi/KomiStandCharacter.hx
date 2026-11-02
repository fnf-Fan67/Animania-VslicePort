package animania.characters.komi;

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
