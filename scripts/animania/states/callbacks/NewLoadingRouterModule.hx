import flixel.FlxG;
import flixel.FlxState;
import flixel.tweens.FlxTween;
import funkin.data.song.SongRegistry;
import funkin.data.story.level.LevelRegistry;
import funkin.modding.module.Module;
import funkin.play.PlayState;
import funkin.play.PlayStatePlaylist;
import funkin.ui.ScriptedMusicBeatState;
import haxe.ds.StringMap;

/**
 * NewLoadingRouterModule
 *
 * Desvía el cambio de estado hacia PlayState por NewLoadingState, para las canciones de la lista `songs`:
 *  - Freeplay:   la solicitud llega con SONG_SELECTED (onSongSelected).
 *  - Story Mode: la 1ª canción de la week la lanza StoryMenuCustom directamente (new NewLoadingState(params)).
 *                Este módulo solo se encarga de las canciones SIGUIENTES (desde PlayState.endSong), deducidas de
 *                PlayStatePlaylist + el Level.
 *  - Story Mode, fresh tras bopeebo: no se desvía (skipAfter), porque comparten todo y ya quedó en caché.
 *
 * NewLoadingState sigue recibiendo sus params con takeLaunch() (API sin cambios).
 */
class NewLoadingRouterModule extends Module
{
  var FADE_IN_TIME:Float = 0.5;       // segundos del fade in al empezar el countdown
  var FADE_FAILSAFE:Float = 8.0;      // si en tantos segundos no hubo countdown, se quita el negro de todos modos
  var FADE_OVERLAY_NAME:String = 'loadingFadeOverlay'; // debe coincidir con NewLoadingState
  var LOADING_STATE_CLASS:String = 'NewLoadingState';
  var DEBUG:Bool = true;              // trazas de por qué se desvía (o no) cada canción

  var songs:StringMap<Bool>;
  var skipAfter:StringMap<String>;    // canción -> canción previa tras la cual NO hace falta pantalla de carga (Story)
  var freeplayRequest:Dynamic = null; // solicitud pendiente de Freeplay (SONG_SELECTED)
  var pendingLaunch:Dynamic = null;   // params que NewLoadingState recoge con takeLaunch()
  var spareStates:Array<Dynamic> = []; // NewLoadingState ya construidos por scripts de estado (construirlos desde el módulo devuelve null)
  var MAX_SPARES:Int = 4;
  var spareBuildFailures:Int = 0;     // intentos fallidos de armar un repuesto desde el propio módulo

  // Control de re-entrada. Se hace por IDENTIDAD de estado y no con banderas de "justo ahora":
  // así no depende de que el startOutro del estado actual sea síncrono.
  var activeLoading:Dynamic = null;   // instancia de NewLoadingState que creamos; mientras sea FlxG.state, su salida no se desvía
  var switchInFlight:Bool = false;    // true entre nuestro FlxG.switchState(NewLoadingState) y su propio STATE_CHANGE_BEGIN

  var overlayAge:Float = 0;
  var fading:Bool = false;

  function new()
  {
    super('NewLoadingRouterModule', 1);

    songs = new StringMap();
    // Week 1 animania
    songs.set('bopeebo-animania', true);
    songs.set('fresh-animania', true);
    songs.set('dadbattle-animania', true);
    // Week 5 animania
    songs.set('cocoa-animania', true);
    songs.set('eggnog-animania', true);
    songs.set('winter-horrorland-animania', true);
    // Phone call
    songs.set('phone-call', true);

    // bopeebo y fresh usan lo mismo: si venimos de bopeebo, todo ya está en caché.
    skipAfter = new StringMap();
    skipAfter.set('fresh-animania', 'bopeebo-animania');
  }

  function log(msg:String):Void
  {
    if (DEBUG) trace('[NewLoadingRouterModule] ' + msg);
  }

  /**
   * Los scripts de ESTADO (StoryMenuCustom, NewLoadingState, el menú principal) dejan aquí instancias de NewLoadingState
   * sin params, construidas desde su propio contexto, donde `new NewLoadingState()` sí funciona (desde el módulo devuelve null).
   * Se usan para Freeplay y para las canciones siguientes de una week. Los params llegan por takeLaunch(). Se acumulan (máx. MAX_SPARES).
   */
  public function addSpareStates(list:Array<Dynamic>):Void
  {
    if (list == null) return;

    var i:Int = 0;
    while (i < list.length)
    {
      if (list[i] != null && spareStates.length < MAX_SPARES) spareStates[spareStates.length] = list[i];
      i = i + 1;
    }
    log('Repuestos de NewLoadingState disponibles: ' + spareStates.length);
  }

  public function spareCount():Int
  {
    return spareStates.length;
  }

  /** Lo consulta StoryMenuCustom para saber si la canción lleva pantalla de carga. */
  public function isLoadingSong(id:String):Bool
  {
    return songs.exists(id);
  }

  // ------------------------------------------------- Fuente 1: Freeplay

  override function onSongSelected(event)
  {
    freeplayRequest = null;

    var cap = event.capsule;
    if (cap == null || cap.freeplayData == null) return;

    freeplayRequest = {
      id: cap.freeplayData.data.id,
      difficulty: event.difficultyId,
      variation: event.variationId,
      softVariation: false, // Freeplay ya eligió variación: se respeta tal cual
      cameraFollowPoint: null,
      source: 'Freeplay'
    };
  }

  /** true si el estado actual es PlayState. (Sin Type: en este entorno Type es el alias de ReflectUtil.) */
  function isPlayStateActive():Bool
  {
    var st = FlxG.state;
    if (st == null) return false;
    return Std.isOfType(st, PlayState);
  }

  // ------------------------------------------------- Fuente 2: Story Mode

  /**
   * Deduce la solicitud de la canción que Story Mode está por cargar (o null si no hay que desviar).
   *
   * Vanilla hace playlistSongIds.shift() de la canción que va a cargar ANTES de cambiar de estado
   * (StoryMenuState al iniciar la week, PlayState.endSong entre canciones), así que:
   *   índice de la canción a cargar = total - restantes - 1
   */
  function storyRequest():Dynamic
  {
    if (!PlayStatePlaylist.isStoryMode) return null;

    // Desde el menú (o cualquier otro estado que no sea PlayState) no se desvía: la 1ª canción la lanza StoryMenuCustom.
    if (!isPlayStateActive()) return null;

    if (PlayStatePlaylist.campaignId == null)
    {
      log('Story: campaignId es null, no se desvía.');
      return null;
    }

    var level = LevelRegistry.instance.fetchEntry(PlayStatePlaylist.campaignId);
    if (level == null)
    {
      log('Story: no existe el Level "' + PlayStatePlaylist.campaignId + '", no se desvía.');
      return null;
    }

    var list = level.getSongs();
    if (list == null || list.length == 0)
    {
      log('Story: el Level "' + PlayStatePlaylist.campaignId + '" no tiene canciones, no se desvía.');
      return null;
    }

    var remaining = PlayStatePlaylist.playlistSongIds.length;
    var idx = list.length - remaining - 1;
    if (idx < 0 || idx >= list.length)
    {
      log('Story: índice fuera de rango (idx=' + idx + ', total=' + list.length + ', restantes=' + remaining + '), no se desvía.');
      return null;
    }

    var id = list[idx];

    var play = FlxG.state;

    // Retry / salir al menú / pantalla de resultados de la última canción: el "siguiente" sigue siendo la actual.
    if (play.currentSong != null && play.currentSong.id == id) return null;

    // fresh después de bopeebo: ya se cargó todo, se sigue directo a PlayState.
    if (skipAfter.exists(id) && play.currentSong != null && play.currentSong.id == skipAfter.get(id))
    {
      log('Story: "' + id + '" viene de "' + play.currentSong.id + '" (ya cargado), no se desvía.');
      return null;
    }

    // Igual que vanilla: de una canción a la siguiente se conserva la posición de la cámara.
    var cameraPoint = null;
    if (play.cameraFollowPoint != null) cameraPoint = play.cameraFollowPoint.getPosition();

    // Igual que vanilla: se intenta seguir en la misma variación que la canción anterior.
    var variationHint = play.currentVariation;

    log('Story: próxima canción "' + id + '" (' + (idx + 1) + '/' + list.length + ', desde PlayState).');

    return {
      id: id,
      difficulty: PlayStatePlaylist.campaignDifficulty,
      variation: variationHint,
      softVariation: true, // si la canción no tiene esa dificultad en esa variación, se busca la primera válida (como vanilla)
      cameraFollowPoint: cameraPoint,
      source: 'Story'
    };
  }

  // ------------------------------------------------- Lógica común

  /**
   * Valida que la canción esté en la lista y arma los params para NewLoadingState.
   * Devuelve null si no hay que desviar (se deja seguir el cambio normal hacia PlayState).
   */
  function buildLaunch(req:Dynamic):Dynamic
  {
    if (req == null) return null;

    if (!songs.exists(req.id))
    {
      if (req.source == 'Story') log('"' + req.id + '" no está en la lista de canciones del router, carga normal.');
      return null;
    }

    var hint = req.variation;
    if (hint == null) hint = 'default';

    var song = SongRegistry.instance.fetchEntry(req.id, {variation: hint});
    if (song == null && hint != 'default') song = SongRegistry.instance.fetchEntry(req.id, {variation: 'default'});
    if (song == null)
    {
      log('No se encontró la canción "' + req.id + '" en SongRegistry, carga normal.');
      return null;
    }

    var variation = req.variation;
    if (variation != null && req.softVariation == true && !song.hasDifficulty(req.difficulty, variation)) variation = null;
    if (variation == null) variation = song.getFirstValidVariation(req.difficulty);
    if (variation == null) variation = 'default';

    var diff = song.getDifficulty(req.difficulty, variation);
    if (diff == null)
    {
      log('"' + req.id + '" no tiene la dificultad "' + req.difficulty + '" (variación "' + variation + '"), carga normal.');
      return null;
    }

    var instVariation = variation;
    if (diff.variation != null) instVariation = diff.variation;

    return {
      targetSong: song,
      targetDifficulty: req.difficulty,
      targetVariation: variation,
      targetInstrumental: song.getBaseInstrumentalId(req.difficulty, instVariation),
      practiceMode: false,
      minimalMode: false,
      botPlayMode: false,
      cameraFollowPoint: req.cameraFollowPoint
    };
  }

  /**
   * scriptInit() busca la clase por su nombre COMPLETO (con package) en el registro de Polymod. Si NewLoadingState quedó
   * registrada con otro nombre (por ejemplo "states.NewLoadingState"), scriptInit("NewLoadingState") devuelve null.
   * Aquí se busca cómo quedó registrada realmente; si no aparece, se imprime la lista para verlo.
   */
  function resolveLoadingClassName():String
  {
    var list = null;
    try
    {
      list = ScriptedMusicBeatState.listScriptClasses();
    }
    catch (e:Dynamic)
    {
      trace('[NewLoadingRouterModule] listScriptClasses() falló: ' + e);
      return LOADING_STATE_CLASS;
    }
    if (list == null) return LOADING_STATE_CLASS;

    var suffix:String = '.' + LOADING_STATE_CLASS;
    var found:String = null;
    for (name in list)
    {
      if (name == LOADING_STATE_CLASS) return name;
      if (found == null && name.length > suffix.length && name.substr(name.length - suffix.length) == suffix) found = name;
    }

    if (found != null)
    {
      log('"' + LOADING_STATE_CLASS + '" está registrada como "' + found + '".');
      return found;
    }

    trace('[NewLoadingRouterModule] "' + LOADING_STATE_CLASS + '" NO está entre las ' + list.length + ' clases registradas que extienden MusicBeatState: ' + list);
    return LOADING_STATE_CLASS;
  }

  /**
   * Crea la instancia REAL de NewLoadingState (un FlxState).
   *  1) `new NewLoadingState()`: igual que los demás estados scriptados del mod (new NewMainMenuState(), new PlayState(...)).
   *     Si falla, imprime la excepción REAL (scriptInit se la traga y solo devuelve null).
   *  2) ScriptedMusicBeatState.scriptInit(nombre completo) como respaldo.
   * Devuelve null si no se pudo, para dejar pasar el cambio normal a PlayState en vez de quedarse sin pantalla.
   */
  function createLoadingState(params:Dynamic):Dynamic
  {
    var state = null;

    // 0) Instancia de repuesto armada por StoryMenuCustom (la forma que se sabe que funciona).
    if (spareStates != null && spareStates.length > 0)
    {
      var spare = spareStates.shift();
      if (spare != null && Std.isOfType(spare, FlxState))
      {
        log('Usando NewLoadingState de repuesto (' + spareStates.length + ' restantes).');
        return spare;
      }
      trace('[NewLoadingRouterModule] El NewLoadingState de repuesto no es un FlxState: ' + Std.string(spare));
    }

    try
    {
      state = new NewLoadingState(params);
    }
    catch (e:Dynamic)
    {
      trace('[NewLoadingRouterModule] new ' + LOADING_STATE_CLASS + '(params) falló: ' + e);
      state = null;
    }
    if (state != null && Std.isOfType(state, FlxState)) return state;
    if (state == null) trace('[NewLoadingRouterModule] new ' + LOADING_STATE_CLASS + '(params) devolvió null (sin excepción).');
    if (state != null) trace('[NewLoadingRouterModule] new ' + LOADING_STATE_CLASS + '() devolvió algo que no es un FlxState: ' + Std.string(state));

    var clsName:String = resolveLoadingClassName();
    state = null;
    try
    {
      state = ScriptedMusicBeatState.scriptInit(clsName, params);
    }
    catch (e:Dynamic)
    {
      trace('[NewLoadingRouterModule] scriptInit(' + clsName + ') falló: ' + e);
      state = null;
    }
    if (state != null && Std.isOfType(state, FlxState)) return state;
    if (state == null) trace('[NewLoadingRouterModule] scriptInit(' + clsName + ') devolvió null. El motivo exacto lo imprime Polymod justo antes de esta línea ("Could not construct instance of scripted class...").');

    trace('[NewLoadingRouterModule] No pude crear ' + LOADING_STATE_CLASS + '. Se deja cargar PlayState normal.');
    return null;
  }

  override function onStateChangeBegin(event)
  {
    // 1) Salida de NewLoadingState (su propio switchState hacia PlayState): sigue normal.
    if (activeLoading != null && FlxG.state == activeLoading)
    {
      activeLoading = null;
      freeplayRequest = null;
      return;
    }

    // 2) El switchState a NewLoadingState que provocamos nosotros: este es su STATE_CHANGE_BEGIN, sigue normal.
    if (switchInFlight)
    {
      switchInFlight = false;
      return;
    }

    // 3) Freeplay aportó su solicitud con SONG_SELECTED; si no, se intenta deducir la de Story Mode.
    var remainingIds = -1;
    if (PlayStatePlaylist.playlistSongIds != null) remainingIds = PlayStatePlaylist.playlistSongIds.length;
    log('STATE_CHANGE_BEGIN desde ' + Std.string(FlxG.state) + ' | story=' + PlayStatePlaylist.isStoryMode + ' | campaña=' + PlayStatePlaylist.campaignId + ' | restantes=' + remainingIds + ' | freeplay=' + (freeplayRequest != null));

    var req = freeplayRequest;
    freeplayRequest = null;
    var params = null;
    try
    {
      if (req == null) req = storyRequest();
      params = buildLaunch(req);
    }
    catch (e:Dynamic)
    {
      // Polymod se traga las excepciones del handler; así se ven.
      trace('[NewLoadingRouterModule] ERROR deduciendo la solicitud: ' + e);
      return;
    }
    if (params == null) return;

    divert(event, req, params);
  }

  /**
   * Cancela el cambio hacia PlayState y entra a NewLoadingState. Sirve tanto para un switchState como para
   * un openSubState (el motor puede cargar la siguiente canción de la week de cualquiera de las dos formas).
   */
  function divert(event, req:Dynamic, params:Dynamic):Void
  {
    // Se construye ANTES de cancelar: si falla, el juego sigue hacia PlayState como siempre.
    var loading = createLoadingState(params);
    if (loading == null) return;

    log('Desviando \"' + req.id + '\" (' + req.source + ') por ' + LOADING_STATE_CLASS + '.');

    // Cancela la carga de PlayState y entra a la pantalla de carga.
    // Los params viajan por takeLaunch(): los argumentos del constructor se perdían y PlayState recibía null.
    event.cancelEvent();
    pendingLaunch = params;
    activeLoading = loading;
    switchInFlight = true;

    // switchState recibe una FUNCIÓN que devuelve el estado (como hace el motor), no la instancia.
    FlxG.switchState(function() {
      return loading;
    });
  }

  /**
   * Story Mode: si la siguiente canción se abre como SUBSTATE (un PlayState nuevo encima del actual, sin cambiar de estado),
   * onStateChangeBegin nunca se dispara. Aquí los datos de la canción se leen del PlayState que está por abrirse.
   */
  override function onSubStateOpenBegin(event)
  {
    if (!PlayStatePlaylist.isStoryMode) return;

    var target = event.targetState;
    if (target == null || !Std.isOfType(target, PlayState)) return;
    if (!isPlayStateActive()) return;

    var play = FlxG.state;
    if (target.currentSong == null || play.currentSong == null) return;

    var id = target.currentSong.id;
    log('SUBSTATE_OPEN_BEGIN de PlayState: \"' + play.currentSong.id + '\" -> \"' + id + '\"');

    // Retry de la misma canción: no se desvía.
    if (id == play.currentSong.id) return;

    if (skipAfter.exists(id) && skipAfter.get(id) == play.currentSong.id)
    {
      log('Story: \"' + id + '\" viene de \"' + play.currentSong.id + '\" (ya cargado), no se desvía.');
      return;
    }

    var cameraPoint = null;
    if (play.cameraFollowPoint != null) cameraPoint = play.cameraFollowPoint.getPosition();

    var req = {
      id: id,
      difficulty: target.currentDifficulty,
      variation: target.currentVariation,
      softVariation: false,
      cameraFollowPoint: cameraPoint,
      source: 'Story (substate)'
    };

    var params = null;
    try
    {
      params = buildLaunch(req);
    }
    catch (e:Dynamic)
    {
      trace('[NewLoadingRouterModule] ERROR deduciendo la solicitud (substate): ' + e);
      return;
    }
    if (params == null) return;

    divert(event, req, params);
  }

  /** Traza: si aparece al cambiar de canción SIN un STATE_CHANGE_BEGIN / SUBSTATE_OPEN_BEGIN antes, el motor recarga la canción dentro del mismo PlayState. */
  override function onSongLoaded(event)
  {
    log('SONG_LOADED: \"' + event.id + '\"');
  }

  override function onStateChangeEnd(event)
  {
    // Ya llegó un estado nuevo: cualquier solicitud o bandera pendiente quedó vieja.
    freeplayRequest = null;
    switchInFlight = false;

    // Si no hay repuestos, se intenta armar uno desde aquí (máx. 3 intentos fallidos para no llenar el log).
    if (spareStates.length == 0 && spareBuildFailures < 3)
    {
      var built = null;
      try
      {
        built = new NewLoadingState(null);
      }
      catch (e:Dynamic)
      {
        trace('[NewLoadingRouterModule] No pude armar un repuesto desde el módulo: ' + e);
      }

      if (built != null && Std.isOfType(built, FlxState))
      {
        spareStates[spareStates.length] = built;
        log('Repuesto armado desde el propio módulo.');
      }
      else
      {
        spareBuildFailures = spareBuildFailures + 1;
        trace('[NewLoadingRouterModule] El módulo no puede construir NewLoadingState (intento ' + spareBuildFailures + '/3). Los repuestos tienen que venir de un script de estado.');
      }
    }

    // Si ya no estamos en NewLoadingState (salió por una vía que no pasó por aquí), se limpia.
    if (activeLoading != null && FlxG.state != activeLoading)
    {
      activeLoading = null;
      pendingLaunch = null;
    }
  }

  /** NewLoadingState llama a esto en create() para recibir los params (y se limpia). */
  public function takeLaunch()
  {
    var params = pendingLaunch;
    pendingLaunch = null;
    return params;
  }

  // -------------------------------------------------------------- Fade in

  function getOverlay()
  {
    return FlxG.stage.getChildByName(FADE_OVERLAY_NAME);
  }

  function removeOverlay():Void
  {
    var overlay = getOverlay();
    if (overlay != null)
    {
      FlxTween.cancelTweensOf(overlay);
      if (overlay.parent != null) overlay.parent.removeChild(overlay);
    }
    fading = false;
    overlayAge = 0;
  }

  /** Desvanece el negro que dejó NewLoadingState (alpha 1 -> 0) y lo quita al terminar. */
  function fadeInOverlay():Void
  {
    var overlay = getOverlay();
    if (overlay == null || fading) return;

    fading = true;
    FlxTween.tween(overlay, {alpha: 0}, FADE_IN_TIME, {
      onComplete: function(twn) {
        removeOverlay();
      }
    });
  }

  override function onCountdownStart(event)
  {
    fadeInOverlay();
  }

  override function onUpdate(event)
  {
    // Solo hay overlay entre el ENTER de la pantalla de carga y el countdown; mientras no exista, esto no hace nada.
    var overlay = getOverlay();
    if (overlay == null) return;

    // No cuenta el tiempo mientras NewLoadingState todavía está haciendo su propio fade a negro.
    if (overlay.alpha < 1 && !fading) return;

    overlayAge = overlayAge + event.elapsed;
    if (overlayAge >= FADE_FAILSAFE) fadeInOverlay();
  }

  override function onDestroy(event)
  {
    removeOverlay();
  }
}
