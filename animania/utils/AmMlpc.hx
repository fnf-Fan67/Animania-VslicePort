package animania.utils;

class AmMlpc
{
	static var MOD_ID:String = 'MobileHitbox';

	public static function isLoaded():Bool
	{
		return ModuleHandler.getModule(MOD_ID) != null;
	}

	static function isArrowsLayout():Bool
	{
		var ps = PlayState.instance;
		if (ps == null || ps.playerStrumline == null) return true;
		if (Std.string(Preferences.controlsScheme) != 'Arrows') return false;
		var pb = ps.playerStrumline.background;
		var ob = (ps.opponentStrumline != null) ? ps.opponentStrumline.background : null;
		if (pb == null || ob == null) return ps.playerStrumline.isDownscroll == true;
		return pb.width > ob.width * 1.6;
	}

	static function middlescroll():String
	{
		var ms = Save.instance.modOptions['mobileMiddlescroll'];
		return (ms == null) ? 'Off' : Std.string(ms);
	}

	public static function pcHud():Bool
	{
		var ok = true;
		#if mobile
		ok = isLoaded() && !isArrowsLayout();
		#end
		return ok;
	}

	public static function playerStrum():Bool
	{
		var ok = true;
		#if mobile
		ok = pcHud() && middlescroll() != 'Widened';
		#end
		return ok;
	}

	public static function oppScale():Bool
	{
		var ok = true;
		#if mobile
		var ms = middlescroll();
		ok = pcHud() && (ms == 'Off' || ms == 'On');
		#end
		return ok;
	}
}
