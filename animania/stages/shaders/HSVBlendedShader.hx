package animania.stages.shaders;

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
