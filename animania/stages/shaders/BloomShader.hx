package animania.stages.shaders;

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
