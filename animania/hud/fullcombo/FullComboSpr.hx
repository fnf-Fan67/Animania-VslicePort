package animania.hud.fullcombo;

class FullComboSpr extends FunkinSprite
{
	public var comboStatus:String = "PFC";

	var outOff:Float = 5;

	public function new(x)
	{
		super(x, 0);
	}

	override function draw()
	{
		if (comboStatus != "Break")
		{
			offset.set(outOff, outOff);
			origin.x += outOff;
			origin.y += outOff;
			var oldAlpha = alpha;
			var oldColor = color;

			setComboColorTransform();

			super.draw();
			alpha = oldAlpha;
			color = oldColor;
			origin.x -= outOff;
			origin.y -= outOff;
			offset.set();
		}
		setColorTransform(1, 1, 1, alpha, 0, 0, 0, 0);
		super.draw();
	}

	function setComboColorTransform()
	{
		switch (comboStatus)
		{
			case "PFC":
				setColorTransform(1, 1, 0, alpha * .9, 255, 255, 0, 0);

			default:
				setColorTransform(1, 0, 1, alpha * .9, 255, 0, 255, 0);
		}
	}
}
