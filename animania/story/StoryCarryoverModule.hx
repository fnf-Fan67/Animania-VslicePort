package animania.story;

class StoryCarryoverModule extends Module
{
  // ---------------- Configuración ----------------

  // Cuántos beats dura la transición (empieza en el "3" del countdown y termina en el "Go!" si vale 3).
  var BLEND_BEATS:Float = 3.0;

  // ---------------- Datos guardados al terminar la canción ----------------

  var hasCarry:Bool = false;
  var carryHealth:Float = 1.0;
  var carryCamX:Float = 0.0;
  var carryCamY:Float = 0.0;
  var carryStageId:String = '';
  var carryNextSongId:String = '';

  // ---------------- Estado de la transición ----------------

  var blendPending:Bool = false; // carry aplicado, esperando a que arranque el countdown
  var blendActive:Bool = false; // transición corriendo
  var blendStartPos:Float = 0.0;
  var blendFromHealth:Float = 1.0;

  public function new()
  {
    super('storyCarryoverModule', 1000);
  }

  function clearCarry():Void
  {
    hasCarry = false;
    blendPending = false;
    blendActive = false;
  }

  // ------------------------------------------------------------------
  // 1) Al terminar una canción: guardar vida y cámara
  // ------------------------------------------------------------------
  override public function onSongEnd(event:ScriptEvent):Void
  {
    super.onSongEnd(event);

    var ps:PlayState = PlayState.instance;
    if (ps == null || !PlayStatePlaylist.isStoryMode || PlayStatePlaylist.playlistSongIds.length == 0)
    {
      // Última canción de la week (o no es story): no hay nada que mantener.
      clearCarry();
      return;
    }

    hasCarry = true;
    carryHealth = ps.health;

    // Centro REAL de la cámara en este momento (no el follow point, que puede ir por delante si hay un tween).
    carryCamX = FlxG.camera.scroll.x + FlxG.camera.width * 0.5;
    carryCamY = FlxG.camera.scroll.y + FlxG.camera.height * 0.5;

    carryStageId = ps.currentStageId;
    // SONG_END se despacha antes del shift() de la playlist, así que [0] es la siguiente canción.
    carryNextSongId = PlayStatePlaylist.playlistSongIds[0];
  }

  // ------------------------------------------------------------------
  // 2) Al cargar la siguiente canción: aplicar vida y cámara (solo si el stage es el mismo)
  //    SONG_LOADED ocurre después de initStage/initCharacters y justo antes del resetCamera() de create().
  // ------------------------------------------------------------------
  override public function onSongLoaded(event:SongLoadScriptEvent):Void
  {
    super.onSongLoaded(event);

    var ps:PlayState = PlayState.instance;
    var hadCarry:Bool = hasCarry;

    // El carry se consume siempre, se aplique o no.
    clearCarry();

    if (!hadCarry || ps == null) return;
    if (!PlayStatePlaylist.isStoryMode) return;
    if (ps.currentStage == null) return;
    if (ps.currentSong.id != carryNextSongId) return;
    if (ps.currentStageId != carryStageId) return;

    // Cámara: arranca donde terminó la canción anterior (el resetCamera() de create() hace el snap).
    ps.cameraFollowPoint.setPosition(carryCamX, carryCamY);

    // Vida: mantener la anterior.
    blendFromHealth = carryHealth;
    ps.health = blendFromHealth;
    try
    {
      // healthLerp es privado; si no se puede escribir, la barra igual alcanza el valor en ~0.3s.
      ps.healthLerp = blendFromHealth;
    }
    catch (e:Dynamic) {}

    blendPending = true;
  }

  // ------------------------------------------------------------------
  // 3) El countdown arranca de verdad (primer paso "3"): empezar la transición.
  //    Se usa onCountdownStep y no onCountdownStart porque algunos song scripts cancelan
  //    COUNTDOWN_START (cutscenes) DESPUÉS de los módulos; un STEP solo ocurre si el countdown corre.
  // ------------------------------------------------------------------
  override public function onCountdownStep(event:CountdownScriptEvent):Void
  {
    super.onCountdownStep(event);

    if (!blendPending) return;

    blendPending = false;
    blendActive = true;
    blendStartPos = Conductor.instance.songPosition;
  }

  // ------------------------------------------------------------------
  // 4) Transición. Se maneja con Conductor.songPosition para que respete pausa y BPM.
  // ------------------------------------------------------------------
  override public function onUpdate(event:UpdateScriptEvent):Void
  {
    super.onUpdate(event);

    if (!blendActive) return;

    var ps:PlayState = PlayState.instance;
    if (ps == null)
    {
      blendActive = false;
      return;
    }

    var duration:Float = Conductor.instance.beatLengthMs * BLEND_BEATS;
    var t:Float = (Conductor.instance.songPosition - blendStartPos) / duration;

    if (t >= 1.0)
    {
      finishBlend();
      return;
    }
    if (t < 0.0) t = 0.0;

    // sineInOut
    var e:Float = -(Math.cos(Math.PI * t) - 1.0) * 0.5;

    ps.health = blendFromHealth + (Constants.HEALTH_STARTING - blendFromHealth) * e;
  }

  function finishBlend():Void
  {
    blendActive = false;

    var ps:PlayState = PlayState.instance;
    if (ps == null) return;

    ps.health = Constants.HEALTH_STARTING;
  }

  // Por si la canción arranca antes de que termine el blend (BLEND_BEATS > 3).
  override public function onCountdownEnd(event:CountdownScriptEvent):Void
  {
    super.onCountdownEnd(event);
    if (blendActive) finishBlend();
  }

  // Reset / muerte: el reinicio normal manda, se cancela cualquier transición.
  override public function onSongRetry(event:SongRetryEvent):Void
  {
    super.onSongRetry(event);
    blendPending = false;
    blendActive = false;
  }
}
