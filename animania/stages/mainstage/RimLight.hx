package animania.stages.mainstage;

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
