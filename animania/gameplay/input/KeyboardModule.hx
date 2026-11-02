package animania.gameplay.input;

class KeyboardModule extends Module
{
	function new()
	{
		super('KeyboardModule');
	}

	function events():Void
	{
		var key:FlxG = FlxG.keys.justPressed;

		if (key.TWO)
		{
			PlayState.instance.isBotPlayMode = !PlayState.instance.isBotPlayMode;
		}
	}

	override function onCountdownStart(event:CountdownScriptEvent):Void
	{
		super.onCountdownStart(event);

	}

	override function onUpdate(event:UpdateScriptEvent):Void
	{
		super.onUpdate(event);

		events();
	}
}
