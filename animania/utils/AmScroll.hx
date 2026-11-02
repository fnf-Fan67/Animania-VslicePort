package animania.utils;

class AmScroll
{
	public static function isDown():Bool
	{
		var ps = PlayState.instance;
		if (ps != null && ps.playerStrumline != null) return ps.playerStrumline.isDownscroll == true;
		return Preferences.downscroll;
	}

	public static function isPref():Bool
	{
		return Preferences.downscroll == true;
	}
}
