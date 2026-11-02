package animania.gameplay.pause;

class AmTweenPauseModule extends Module
{
	function new()
	{
		super('AmTweenPauseModule', {state: PlayState});
	}

	var keepCams = [];
	var keepFilters = [];
	var keepFn = null;

	override function onPause(event:PauseScriptEvent):Void
	{
		super.onPause(event);
		if (event.eventCanceled) return;
		AmTweenPause.pauseAll();

		var ps = PlayState.instance;
		if (ps == null) return;

		keepCams = [ps.camGame, ps.camHUD];
		keepFilters = [];
		var i = 0;
		while (i < keepCams.length)
		{
			var f = (keepCams[i] != null) ? keepCams[i].filters : null;
			keepFilters[i] = (f != null && f.length > 0) ? f : null;
			i = i + 1;
		}

		if (keepFn == null)
		{
			keepFn = function() {
				var cur = PlayState.instance;
				if (cur == null || cur.camGame != keepCams[0])
				{
					FlxG.signals.postUpdate.remove(keepFn);
					keepFn = null;
					return;
				}
				restoreCamFilters();
			};
			FlxG.signals.postUpdate.add(keepFn);
		}
	}

	function restoreCamFilters():Void
	{
		var i = 0;
		while (i < keepCams.length)
		{
			var cam = keepCams[i];
			var saved = keepFilters[i];
			if (cam != null && saved != null && (cam.filters == null || cam.filters.length != saved.length)) cam.filters = saved;
			i = i + 1;
		}
	}

	override function onResume(event:ScriptEvent):Void
	{
		super.onResume(event);
		if (event.eventCanceled) return;
		AmTweenPause.resumeAll();

		restoreCamFilters();
		if (keepFn != null)
		{
			FlxG.signals.postUpdate.remove(keepFn);
			keepFn = null;
		}
		keepCams = [];
		keepFilters = [];
	}
}
