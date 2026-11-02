package animania.story;

class Week5AmTakeLevel extends Level
{
  var chromaShader:FlxRuntimeShader = null;

  public function new()
  {
    super('week5Animania');
  }

  function getChromaShader():FlxRuntimeShader
  {
    if (chromaShader == null)
    {
      chromaShader = new FlxRuntimeShader(Assets.getText(Paths.frag('chromaKey')));
    }

    var r:Float = 0.5;
    var g:Float = 0.5;
    var b:Float = 0.5;

    if (isBackgroundSimple())
    {
      var c:Int = getBackgroundColor();
      r = ((c >> 16) & 0xFF) / 255;
      g = ((c >> 8) & 0xFF) / 255;
      b = (c & 0xFF) / 255;
    }

    chromaShader.setFloatArray('bg_col', [r, g, b]);
    return chromaShader;
  }

  public override function buildProps(?existingProps:Array<LevelProp>):Array<LevelProp>
  {
    var props:Array<LevelProp> = super.buildProps(existingProps);
    var shader:FlxRuntimeShader = getChromaShader();

    for (prop in props)
    {
      if (prop == null) continue;
      prop.shader = shader;
    }

    return props;
  }
}
