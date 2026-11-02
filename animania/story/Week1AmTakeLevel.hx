package animania.story;

class Week1AmTakeLevel extends Level
{
  var chromaShader:FlxRuntimeShader = null;

  public function new()
  {
    super('week1Animania');
  }

  /**
   * Crea (una sola vez) el shader y actualiza `bg_col` con el color de fondo del nivel.
   */
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

  /**
   * Construye los props con el comportamiento vanilla y les asigna el shader.
   * Se vuelve a llamar cada vez que se selecciona este nivel en el menu.
   */
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
