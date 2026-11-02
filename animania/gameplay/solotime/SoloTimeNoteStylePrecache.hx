package animania.gameplay.solotime;

class SoloTimeNoteStylePrecache extends Module
{
	function new()
	{
		super('SoloTimeNoteStylePrecache');
	}

	static var ALLOWED_SONGS:Array<String> = [
		'bopeebo-animania',
		'cocoa-animania',
		'dadbattle-animania',
		'eggnog-animania',
		'fresh-animania',
	];

	function songAllowed():Bool
	{
		var playState:PlayState = PlayState.instance;
		if (playState == null || playState.currentSong == null) return false;
		return ALLOWED_SONGS.indexOf(playState.currentSong.id) != -1;
	}

	function precacheAll():Void
	{
		FunkinMemory.cacheTexture(Paths.image("ui/times/solo_time"));
		FunkinMemory.cacheTexture(Paths.image("ui/times/solo_time-xmas"));
		FunkinMemory.cacheSound(Paths.sound("gameplay/solo_time/solotime" , "shared"));
		FunkinMemory.cacheSound(Paths.sound("gameplay/solo_time/solotime-xmas", "shared"));
		FunkinMemory.cacheNoteStyle(NoteStyleRegistry.instance.fetchEntry('solotime'));
	}

	// Con el countdown saltado la cancion arranca en el frame siguiente a onCountdownStart: si el precache se hiciera
	// recien ahi, cargar texturas/sonidos coincidiria con el inicio de la musica (el tiron del primer segundo = "lag").
	// Por eso se hace ya al terminar de crear el PlayState; en onCountdownStart queda solo como respaldo (cacheTexture
	// y compania ignoran lo que ya esta en cache).
	override function onStateChangeEnd(event)
	{
		super.onStateChangeEnd(event);
		if (!Std.isOfType(event.targetState, PlayState)) return;
		if (!songAllowed()) return;

		precacheAll();
	}

	override function onCountdownStart(event)
	{
		if (!songAllowed()) return;
		super.onCountdownStart(event);

		precacheAll();
	}
}
