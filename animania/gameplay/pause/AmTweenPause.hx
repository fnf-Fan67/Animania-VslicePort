package animania.gameplay.pause;

class AmTweenPause
{
	static var held:Array<Dynamic> = [];

	public static function pauseAll():Void
	{
		var list = held;
		FlxTween.globalManager.forEach(function(t)
		{
			if (t == null || !t.active || t.finished) return;
			FlxTweenUtil.pauseTween(t);
			list.push(t);
		});
	}

	public static function resumeAll():Void
	{
		var list = held;
		held = [];
		var i = 0;
		while (i < list.length)
		{
			FlxTweenUtil.resumeTween(list[i]);
			i += 1;
		}
	}
}
