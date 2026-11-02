package animania.stages.shaders;

class HighShader extends FlxRuntimeShader
{
	var currentTime(default, set):Float = 0.0;
	var effectiveness(default, set):Float = 0.0;

	public function new()
	{
		var fragText:String = Assets.getText(Paths.frag('high'));
		super(fragText);
		reset();
	}

	function set_currentTime(nt:Float):Float
	{
		this.setFloat('iTime', nt);
		return currentTime = nt;
	}

	function set_effectiveness(nt:Float):Float
	{
		this.setFloat('effectiveness', nt);
		return effectiveness = nt;
	}

	public function update(elapsed:Float):Void
	{
		currentTime += elapsed;
	}

	public function reset()
	{
		currentTime = 0;
		effectiveness = 0;
	}
}
