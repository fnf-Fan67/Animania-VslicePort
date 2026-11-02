package animania.gameplay.vocals;

class VocalDifficultySuffixModule extends Module
{
	static var DIFFICULTIES:Array<String> = ['normal', 'easy'];

	var lastVocals:Dynamic = null;
	var anyFound:Bool = false;

	function new()
	{
		super('VocalDifficultySuffixModule', {state: PlayState});
	}

	override function onSongLoaded(event)
	{
		super.onSongLoaded(event);
		applyDifficultyVocals();
	}

	override function onDestroy(event)
	{
		lastVocals = null;
		super.onDestroy(event);
	}

	function applyDifficultyVocals():Void
	{
		var ps = PlayState.instance;
		if (ps == null || ps.vocals == null || ps.vocals == lastVocals) return;

		var old = ps.vocals;
		lastVocals = old;

		var chart = ps.currentChart;
		if (chart == null) return;

		var diff:String = (ps.currentDifficulty == null) ? '' : Std.string(ps.currentDifficulty).toLowerCase();
		if (DIFFICULTIES.indexOf(diff) == -1) return;

		anyFound = false;
		var playerPaths = withDifficulty(chart.buildPlayerVoiceList(), diff);
		var opponentPaths = chart.buildOpponentVoiceList();

		var legacyPath:String = null;
		if (playerPaths.length == 0 && opponentPaths.length == 0)
		{
			var variation = ps.currentVariation;
			var suffix:String = (variation != null && variation != '' && variation != 'default') ? '-' + variation : '';
			var candidate = insertDifficulty(Paths.voices(ps.currentSong.id, suffix), diff);
			if (Assets.exists(candidate))
			{
				legacyPath = candidate;
				anyFound = true;
			}
		}

		if (!anyFound) return;

		var group = new VoicesGroup();
		for (p in playerPaths)
			group.addPlayerVoice(FunkinSound.load(p, 1.0, false, false, false, false, null, null, true));
		for (p in opponentPaths)
			group.addOpponentVoice(FunkinSound.load(p, 1.0, false, false, false, false, null, null, true));
		if (legacyPath != null)
			group.addPlayerVoice(FunkinSound.load(legacyPath, 1.0, false, false, false, false, null, null, true));

		if (group.members.length == 1)
		{
			group.legacyVoiceSystem = true;
			group.legacyVoiceUsesPlayer = group.getPlayerVoice(0) != null;
		}

		group.forEach(function(snd) { snd.important = true; });

		group.playerVoicesOffset = old.playerVoicesOffset;
		group.opponentVoicesOffset = old.opponentVoicesOffset;
		group.playerVolume = old.playerVolume;
		group.opponentVolume = old.opponentVolume;

		old.stop();
		ps.vocals = group;
		lastVocals = group;
	}

	function withDifficulty(paths:Array<String>, diff:String):Array<String>
	{
		var result:Array<String> = [];
		for (p in paths)
		{
			var candidate = insertDifficulty(p, diff);
			if (candidate != p && Assets.exists(candidate))
			{
				result.push(candidate);
				anyFound = true;
			}
			else
			{
				result.push(p);
			}
		}
		return result;
	}

	function insertDifficulty(path:String, diff:String):String
	{
		var dot = path.lastIndexOf('.');
		if (dot < 0) return path;
		return path.substr(0, dot) + '-' + diff + path.substr(dot);
	}
}
