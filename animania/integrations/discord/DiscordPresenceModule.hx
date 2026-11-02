package animania.integrations.discord;

#if FEATURE_DISCORD_RPC
class DiscordPresenceModule extends Module
{
	static var TITLE_TEXT:String = 'In The AmTake Title';
	static var MENU_TEXT:String = 'In The AmTake Menu';
	static var TITLE_IMAGE:String = 'https://raw.githubusercontent.com/fnf-Fan67/Animania-VslicePort/main/previewImages/discord/animania.png';
	static var SMALL_IMAGE:String = '';
	static var REFRESH_SECONDS:Float = 1.0;
	static var ENGINE_SETTLE_SECONDS:Float = 0.01;

	static var SONGS:Array<Dynamic> = [
		{id: 'cocoa-animania', name: 'Cocoa (AmTake)', image: 'https://raw.githubusercontent.com/fnf-Fan67/Animania-VslicePort/main/previewImages/discord/expansionMini.png'},
		{id: 'bopeebo-animania', name: 'Bopeebo (AmTake)', image: 'https://raw.githubusercontent.com/fnf-Fan67/Animania-VslicePort/main/previewImages/discord/expansionMini.png'},
		{id: 'fresh-animania', name: 'Fresh (AmTake)', image: 'https://raw.githubusercontent.com/fnf-Fan67/Animania-VslicePort/main/previewImages/discord/expansionMini.png'},
		{id: 'dadbattle-animania', name: 'DadBattle (AmTake)', image: 'https://raw.githubusercontent.com/fnf-Fan67/Animania-VslicePort/main/previewImages/discord/expansionMini.png'},
		{id: 'eggnog-animania', name: 'Eggnog (AmTake)', image: 'https://raw.githubusercontent.com/fnf-Fan67/Animania-VslicePort/main/previewImages/discord/animania05.png'},
		{id: 'winter-horrorland-animania', name: 'Winter Horrorland (AmTake)', image: 'https://raw.githubusercontent.com/fnf-Fan67/Animania-VslicePort/main/previewImages/discord/expansionMini.png'},
		{id: 'phone-call', name: 'PhoneCall', image: 'https://raw.githubusercontent.com/fnf-Fan67/Animania-VslicePort/main/previewImages/discord/animania05.png'}
	];

	var paused:Bool = false;
	var loopTimer:FlxTimer = null;

	function new()
	{
		super('DiscordPresenceModule');
	}

	override function onStateChangeEnd(event)
	{
		super.onStateChangeEnd(event);
		paused = false;
		restartLoop();
		applyLater();
	}

	override function onSongStart(event)
	{
		super.onSongStart(event);
		paused = false;
		applyLater();
	}

	override function onPause(event)
	{
		super.onPause(event);
		paused = true;
		applyLater();
	}

	override function onResume(event)
	{
		super.onResume(event);
		paused = false;
		applyLater();
	}

	override function onSongRetry(event)
	{
		super.onSongRetry(event);
		paused = false;
		applyLater();
	}

	override function onGameOver(event)
	{
		super.onGameOver(event);
		applyLater();
	}

	override function onFocusGained(event)
	{
		super.onFocusGained(event);
		applyLater();
	}

	override function onFocusLost(event)
	{
		super.onFocusLost(event);
		applyLater();
	}

	override function onDestroy(event)
	{
		stopLoop();
		paused = false;
		super.onDestroy(event);
	}

	function restartLoop():Void
	{
		stopLoop();
		loopTimer = new FlxTimer().start(REFRESH_SECONDS, function(_) apply(), 0);
	}

	function stopLoop():Void
	{
		if (loopTimer == null) return;
		loopTimer.cancel();
		loopTimer.destroy();
		loopTimer = null;
	}

	function applyLater():Void
	{
		new FlxTimer().start(ENGINE_SETTLE_SECONDS, function(_) apply());
	}

	function findSong(id:String):Dynamic
	{
		if (id == null) return null;
		var lower = id.toLowerCase();
		for (s in SONGS)
		{
			if (s.id == lower) return s;
		}
		return null;
	}

	function titleCase(text:String):String
	{
		var words = text.split('-').join(' ').split(' ');
		var result:Array<String> = [];
		for (w in words)
		{
			if (w == '') continue;
			result.push(w.charAt(0).toUpperCase() + w.substr(1));
		}
		return result.join(' ');
	}

	function setPresence(details:String, state:String, image:String):Void
	{
		DiscordClient.setPresence({
			details: details,
			state: state,
			largeImageKey: (image == null || image == '') ? TITLE_IMAGE : image,
			smallImageKey: SMALL_IMAGE
		});
	}

	function apply():Void
	{
		var current = FlxG.state;
		if (current == null || Std.isOfType(current, InitState)) return;

		if (Std.isOfType(current, PlayState))
		{
			applySong();
			return;
		}

		if (Std.isOfType(current, TitleState))
		{
			setPresence(TITLE_TEXT, '', TITLE_IMAGE);
			return;
		}

		setPresence(MENU_TEXT, '', TITLE_IMAGE);
	}

	function applySong():Void
	{
		var ps = PlayState.instance;
		if (ps == null || ps.currentSong == null) return;

		var entry = findSong(ps.currentSong.id);
		if (entry == null) return;
		if (ps.isChartingMode || ps.currentSong.isDiscordRPCAnonymous()) return;

		var difficulty:String = (ps.currentDifficulty == null) ? '???' : titleCase(Std.string(ps.currentDifficulty));

		var mode:String = 'Freeplay';
		if (PlayStatePlaylist.isStoryMode) mode = 'Story Mode';
		else if (ps.isPracticeMode) mode = 'Practice';
		else if (ps.isBotPlayMode) mode = 'Bot Play';

		var prefix:String = '';
		if (ps.isPlayerDying || ps.isGameOverState) prefix = 'Game Over - ';
		else if (paused) prefix = 'Paused - ';

		setPresence('Playing: ' + entry.name, prefix + mode + ' [' + difficulty + ']', entry.image);
	}
}
#end
