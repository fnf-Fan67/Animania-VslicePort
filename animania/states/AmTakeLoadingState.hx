import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.FunkinMemory;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.input.Controls;
import funkin.PlayerSettings;
import funkin.modding.module.ModuleHandler;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.stage.StageRegistry;
import funkin.play.PlayState;
import funkin.vis.dsp.SpectralAnalyzer;
import haxe.ds.StringMap;
import funkin.ui.MusicBeatState;
import funkin.util.TouchUtil;
import openfl.display.Sprite;
import openfl.utils.Assets;
import Reflect;

class NewLoadingState extends MusicBeatState
{
  var BG_IMAGE:String = 'loadingScreen/funkin-week1';
  var BF_ATLAS:String = 'loadingScreen/bf';
  var BOX_IMAGE:String = 'loadingScreen/boxOfNoodles';
  var NOODLE_IMAGE:String = 'loadingScreen/longNoodle';
  var PRESS_ATLAS:String = 'loadingScreen/pressEnter';

  // Variantes de pantalla (portadas de loadingScreen.script). El fondo es 'loadingScreen/funkin' + sufijo; si no existe, se usa BG_IMAGE.
  var BG_PREFIX:String = 'loadingScreen/funkin';

  var MUSIC_DEFAULT:Array<String> = ['loadingThemeLol/loadingThemeLol', 'loadingThemeLol'];
  var MUSIC_DADBATTLE:Array<String> = ['loadingThemeLol/loadingThemeLol-dadbattle'];
  var MUSIC_FADE_IN:Float = 0.5;
  var MUSIC_FADE_IN_DADBATTLE:Float = 4.0;

  var WH_PITCH:Float = 0.1;
  var WH_PITCH_TIME:Float = 2.5;
  var WH_PRESS_SCALE:Float = 0.7;
  var BLACK_FADE_TIME:Float = 2.0;

  var VIZ_ATLAS:String = 'loadingScreen/dadbattleviz';
  var VIZ_COUNT:Int = 11;
  var VIZ_OFFSET_X:Float = 5;
  var VIZ_OFFSET_Y:Float = 3;
  // Calibración del analizador (mismos valores que ABotVis). value va de 0 a 1 y se mapea a los frames 0..13 de cada barra.
  //  - VIZ_MAX_DELTA: cuánto puede subir/bajar cada barra por actualización. Más alto = golpes de ritmo más marcados.
  //  - VIZ_MIN_DB / VIZ_MAX_DB: rango de volumen que se considera. Si las barras se quedan pegadas arriba, baja VIZ_MAX_DB
  //    más hacia 0 (ej. -15); si casi no se mueven, súbelo hacia -35.
  //  - VIZ_GAIN: multiplicador final (13 = value 1.0 llega al último frame).
  var VIZ_MAX_DELTA:Float = 0.5;
  var VIZ_MIN_DB:Float = -65;
  var VIZ_MAX_DB:Float = -25;
  var VIZ_GAIN:Float = 13;
  var VIZ_MAX_FRAME:Float = 13;
  var VIZ_FOLLOW:Float = 50;

  var COUNTDOWN_IMAGES:Array<String> = ['countdown/COUNTDOWN', 'ui/countdown/COUNTDOWN'];
  var NOTESTYLE_WEIGHT:Float = 3;

  var TRANS_IN_TIME:Float = 0.5;

  var NOTESTYLE_BASE:String = 'amtake-base';
  var NOTESTYLE_BASE_SONGS:Array<String> = ['bopeebo-animania', 'fresh-animania', 'dadbattle-animania', 'phone-call'];
  var NOTESTYLE_XMAS:String = 'amtake-xmas';
  var NOTESTYLE_XMAS_SONGS:Array<String> = ['cocoa-animania', 'eggnog-animania', 'winter-horrorland-animania'];

  var FADE_OUT_TIME:Float = 0.5;
  var BOP_SCALE:Float = 1.05;
  var BOP_TIME:Float = 0.4;
  var FADE_OVERLAY_NAME:String = 'loadingFadeOverlay';
  var LOAD_PER_FRAME:Int = 1;
  var LOAD_START_DELAY:Float = 0.65;
  var BF_SPEED:Float = 260;

  var BOX_X:Float = 37;
  var BOX_Y:Float = 593;
  var BOX_SCALE:Float = 0.79;

  var NOODLE_LEFT_X:Float = 165;
  var NOODLE_CY:Float = 678;
  var NOODLE_SCALE:Float = 0.79;
  var BF_SCALE:Float = 0.85;
  var BF_MOUTH_DX:Float = 45;
  var BF_MOUTH_DY:Float = 25;
  var BF_BOB:Float = 2;

  var PRESS_CX:Float = 652;
  var PRESS_CY:Float = 672;
  var PRESS_SCALE:Float = 0.95;
  var PRESS_FPS:Float = 12;

  var ATE_FPS:Float = 24;
  var COMPLETE_FPS:Float = 24;

  var bg:FlxSprite;
  var noodle:FlxSprite;
  var box:FlxSprite;
  var bf:FlxSprite;
  var pressEnter:FlxSprite;

  var launch:Dynamic = null;
  var loadItems:Array<Dynamic> = [];
  var loadIndex:Int = 0;
  var loadedWeight:Float = 0;
  var totalWeight:Float = 0;
  var timeAlive:Float = 0;
  var chewTime:Float = 0;

  var noodleLeft:Float = 0;
  var noodleFullW:Float = 0;
  var bfStartCX:Float = 0;
  var bfEndCX:Float = 0;
  var bfCX:Float = 0;
  var bfCY:Float = 0;

  var phase:Int = 0;

  var bgSuffix:String = '';
  var hideMudbang:Bool = false;
  var analyzer:Dynamic = null;
  var vizLevels:Dynamic = null;
  var dadbattleViz:Array<Dynamic> = [];
  var vizBaseScale:Array<Dynamic> = [];
  var bgBaseScaleX:Float = 1;
  var bgBaseScaleY:Float = 1;

  var sceneK:Float = 1.0;
  var sceneOffX:Float = 0;

  /**
   * @param params Params de la canción (targetSong, targetDifficulty, targetVariation, targetInstrumental, ...).
   *               StoryMenuCustom los pasa directo; si vienen null (Freeplay / canciones siguientes), se piden
   *               a NewLoadingRouterModule con takeLaunch().
   */
  public function new(?params:Dynamic = null)
  {
    super();
    launch = params;
  }

  override function create():Void
  {
    FlxG.cameras.reset(new FunkinCamera('newLoading'));

    if (launch == null)
    {
      var router = ModuleHandler.getModule('NewLoadingRouterModule');
      if (router == null) trace('[NewLoadingState] ModuleHandler.getModule(NewLoadingRouterModule) es null: el módulo no se instanció (revisa errores de import en su script).');
      else launch = router.takeLaunch();
    }
    if (launch == null)
    {
      trace('[NewLoadingState] No hay params de canción (ni por constructor ni por NewLoadingRouterModule). Volviendo al menú.');
      FlxG.switchState(function() {
        return new NewMainMenuState();
      });
      return;
    }

    replenishSpare();

    computeWideLayout();
    bgSuffix = resolveBgSuffix(launch);

    this.persistentUpdate = true;
    this.persistentDraw = true;

    buildBackground();
    buildNoodleAndBox();
    buildBf();
    buildPressEnter();
    setupVariant();

    FlxG.camera.fade(0xFF000000, TRANS_IN_TIME, true);
    buildLoadList();

    super.create();
  }

  /**
   * El módulo no puede construir NewLoadingState (devuelve null), pero un estado sí. Cada pantalla de carga deja lista
   * una instancia para la siguiente (Freeplay / siguiente canción de la week).
   */
  function replenishSpare():Void
  {
    try
    {
      var router = ModuleHandler.getModule('NewLoadingRouterModule');
      if (router != null && router.spareCount() < 2)
      {
        var spare = new NewLoadingState(null);
        if (spare != null) router.addSpareStates([spare]);
      }
    }
    catch (e:Dynamic)
    {
      trace('[NewLoadingState] No pude dejar un repuesto para la siguiente carga: ' + e);
    }
  }

  function computeWideLayout():Void
  {
    var baseW:Float = FlxG.initialWidth;
    var baseH:Float = FlxG.initialHeight;

    sceneK = Math.max(1.0, Math.max(FlxG.width / baseW, FlxG.height / baseH));
    sceneOffX = Math.max((FlxG.width - baseW * sceneK) / 2, 0);
  }

  function sx(x:Float):Float
  {
    return sceneOffX + x * sceneK;
  }

  function sy(y:Float):Float
  {
    return FlxG.height - (FlxG.initialHeight - y) * sceneK;
  }

  function buildBackground():Void
  {
    var bgKey:String = BG_IMAGE;
    if (Assets.exists(Paths.image(BG_PREFIX + bgSuffix))) bgKey = BG_PREFIX + bgSuffix;
    bg = new FlxSprite().loadGraphic(Paths.image(bgKey));
    bg.scale.set(FlxG.width / bg.width, FlxG.height / bg.height);
    bg.updateHitbox();
    bgBaseScaleX = bg.scale.x;
    bgBaseScaleY = bg.scale.y;
    bg.x = (FlxG.width - bg.width) / 2;
    bg.y = FlxG.height - bg.height;
    bg.antialiasing = true;
    add(bg);
  }

  function buildNoodleAndBox():Void
  {
    noodle = new FlxSprite().loadGraphic(Paths.image(NOODLE_IMAGE));
    noodle.antialiasing = true;
    noodle.origin.set(0, 0);
    noodle.scale.set(NOODLE_SCALE * sceneK, NOODLE_SCALE * sceneK);
    noodleFullW = noodle.frameWidth * NOODLE_SCALE;
    noodleLeft = NOODLE_LEFT_X;
    noodle.x = sx(noodleLeft);
    noodle.y = sy(NOODLE_CY) - noodle.frameHeight * NOODLE_SCALE * sceneK / 2;
    add(noodle);

    box = new FlxSprite().loadGraphic(Paths.image(BOX_IMAGE));
    box.antialiasing = true;
    box.scale.set(BOX_SCALE * sceneK, BOX_SCALE * sceneK);
    box.updateHitbox();
    box.x = sx(BOX_X);
    box.y = sy(BOX_Y);
    add(box);
  }

  function buildBf():Void
  {
    bf = new FlxSprite();
    bf.frames = Paths.getSparrowAtlas(BF_ATLAS);
    bf.animation.addByPrefix('ate', 'bf ate', ATE_FPS, true);
    bf.animation.addByPrefix('complete', 'load complete', COMPLETE_FPS, false);
    bf.antialiasing = true;
    bf.scale.set(BF_SCALE * sceneK, BF_SCALE * sceneK);

    bfStartCX = noodleLeft + noodleFullW + BF_MOUTH_DX;
    bfEndCX = noodleLeft + BF_MOUTH_DX;
    bfCX = bfStartCX;
    bfCY = NOODLE_CY - BF_MOUTH_DY;
    playBf('ate');
    add(bf);
  }

  function buildPressEnter():Void
  {
    pressEnter = new FlxSprite();
    pressEnter.frames = Paths.getSparrowAtlas(PRESS_ATLAS);
    pressEnter.animation.addByIndices('idle', 'press to start образец 1', [0, 1, 2, 3, 4, 5], '', PRESS_FPS, false);
    pressEnter.animation.play('idle');
    pressEnter.antialiasing = true;
    applyPressScale(PRESS_SCALE);
    pressEnter.visible = false;
    add(pressEnter);
  }

  function applyPressScale(s:Float):Void
  {
    pressEnter.scale.set(s * sceneK, s * sceneK);
    pressEnter.updateHitbox();
    pressEnter.x = sx(PRESS_CX) - pressEnter.width / 2;
    pressEnter.y = sy(PRESS_CY) - pressEnter.height / 2;
  }

  function addItem(kind:String, key:Dynamic, stage:String, weight:Float):Void
  {
    loadItems[loadItems.length] = {kind: kind, key: key, stage: stage, w: weight};
    totalWeight = totalWeight + weight;
  }

  function buildLoadList():Void
  {
    loadItems = [];
    totalWeight = 0;

    if (launch != null) buildSongLoadList();
  }

  function buildSongLoadList():Void
  {
    var song = launch.targetSong;
    var diff = null;
    if (song != null) diff = song.getDifficulty(launch.targetDifficulty, launch.targetVariation);

    // PlayState usa SIEMPRE el noteStyle del chart (currentChart.noteStyle, y el default si no existe). Ese es el que hay que
    // precargar sí o sí; el estilo "forzado" por lista de canciones se precarga además (sin duplicar si coinciden).
    var styleIds:Array<String> = [];
    var chartStyleId = '';
    if (diff != null && diff.noteStyle != null) chartStyleId = diff.noteStyle;
    styleIds.push(chartStyleId);

    var forcedId = '';
    if (song != null)
    {
      if (NOTESTYLE_BASE_SONGS.indexOf(song.id) != -1) forcedId = NOTESTYLE_BASE;
      else if (NOTESTYLE_XMAS_SONGS.indexOf(song.id) != -1) forcedId = NOTESTYLE_XMAS;
    }
    if (forcedId != '' && styleIds.indexOf(forcedId) == -1) styleIds.push(forcedId);

    var seenStyles = new StringMap();
    for (styleId in styleIds)
    {
      var noteStyle = null;
      if (styleId != '') noteStyle = NoteStyleRegistry.instance.fetchEntry(styleId);
      if (noteStyle == null) noteStyle = NoteStyleRegistry.instance.fetchDefault();
      if (noteStyle == null || seenStyles.exists(noteStyle.id)) continue;

      seenStyles.set(noteStyle.id, true);
      addItem('notestyle', noteStyle, 'notestyle', NOTESTYLE_WEIGHT);
      trace('[NewLoadingState] Precargando notestyle: ' + noteStyle.id + ' (chart: "' + chartStyleId + '", forzado: "' + forcedId + '")');
    }

    var cd = firstExistingImage(COUNTDOWN_IMAGES);
    if (cd != null) addItem('path', cd, 'countdown', 1);
    else trace('[NewLoadingState] No encontré el sprite del countdown (' + COUNTDOWN_IMAGES + ').');

    if (diff != null && diff.stage != null)
    {
      var stage = StageRegistry.instance.fetchEntry(diff.stage);
      if (stage != null)
      {
        var dir = 'shared';
        if (stage._data != null && stage._data.directory != null) dir = stage._data.directory;
        Paths.setCurrentLevel(dir);

        var seen = new StringMap();
        var paths = stage.fetchAssetPaths();
        var i = 0;
        while (i < paths.length)
        {
          var p = paths[i];
          if (p != null && p.indexOf('/#') == -1 && !seen.exists(p))
          {
            seen.set(p, true);
            addItem('path', p, 'stage', 1);
          }
          i = i + 1;
        }
      }
    }
  }

  function firstExistingImage(keys:Array<String>):Dynamic
  {
    var i = 0;
    while (i < keys.length)
    {
      var path = Paths.image(keys[i]);
      if (Assets.exists(path)) return path;
      i = i + 1;
    }
    return null;
  }

  function loadItem(item:Dynamic):Void
  {
    if (item.kind == 'path') FunkinMemory.cacheTexture(item.key);
    else if (item.kind == 'notestyle') cacheNoteStyleFull(item.key);
  }

  /**
   * FunkinMemory.cacheNoteStyle cachea note/strumline/splash/holdcover con Paths.image(ruta) SIN librería, pero NoteStyle los
   * carga con Paths.getSparrowAtlas(ruta, librería). Si el estilo declara 'libreria:ruta' la llave cacheada no coincide con la
   * que pide PlayState y la textura se vuelve a cargar al entrar. Aquí se llama al cache de vanilla (cubre countdown, judgement
   * y combo) y además se cachean las llaves exactas (con y sin librería) a partir de las rutas crudas del estilo.
   */
  function cacheNoteStyleFull(style:Dynamic):Void
  {
    try
    {
      FunkinMemory.cacheNoteStyle(style);
    }
    catch (e:Dynamic)
    {
      trace('[NewLoadingState] FunkinMemory.cacheNoteStyle falló para ' + style.id + ': ' + e);
    }

    try
    {
      cacheStyleImage(style.getNoteAssetPath(true));
      cacheStyleImage(style.getHoldNoteAssetPath(true));
      cacheStyleImage(style.getStrumlineAssetPath(true));
      cacheStyleImage(style.getSplashAssetPath(true));

      // NoteDirection es un enum abstract sobre Int: LEFT = 0, DOWN = 1, UP = 2, RIGHT = 3.
      for (dir in 0...4) cacheStyleImage(style.getHoldCoverDirectionAssetPath(dir, true));
    }
    catch (e:Dynamic)
    {
      trace('[NewLoadingState] Cache por llaves exactas falló para ' + style.id + ': ' + e);
    }
  }

  function cacheStyleImage(raw:Dynamic):Void
  {
    if (raw == null || raw == '') return;

    var path:String = raw;
    var library:String = null;
    var sep:Int = path.indexOf(':');
    if (sep != -1)
    {
      library = path.substr(0, sep);
      path = path.substr(sep + 1);
    }

    var keyLib:String = Paths.image(path, library);
    var keyNoLib:String = Paths.image(path);

    cacheImageKey(keyLib);
    if (keyNoLib != keyLib) cacheImageKey(keyNoLib);
  }

  function cacheImageKey(key:String):Void
  {
    if (key == null) return;

    if (!Assets.exists(key))
    {
      trace('[NewLoadingState] notestyle: no existe el asset ' + key);
      return;
    }

    FunkinMemory.cacheTexture(key);
    if (!FunkinMemory.isTextureCached(key)) trace('[NewLoadingState] notestyle: no quedó en caché ' + key);
  }

  function playBf(name:String):Void
  {
    bf.animation.play(name, true);
    bf.updateHitbox();
    bf.centerOrigin();
    placeBf(0);
  }

  function placeBf(bob:Float):Void
  {
    bf.x = sx(bfCX) - bf.width / 2;
    bf.y = sy(bfCY + bob) - bf.height / 2;
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (phase == 0) updateLoading(elapsed);
    else if (phase == 1) updateComplete(elapsed);
    else if (phase == 2) updateWaitEnter(elapsed);

    if (FlxG.keys.justPressed.ENTER || PlayerSettings.player1.controls.ACCEPT_P || (FlxG.onMobile && TouchUtil.justPressed))
    {
      bopBackground();
    }

    if (dadbattleViz.length > 0) updateDadbattleViz(elapsed);
  }

  function updateLoading(elapsed:Float):Void
  {
    timeAlive += elapsed;

    if (timeAlive >= LOAD_START_DELAY && loadIndex < loadItems.length)
    {
      for (k in 0...LOAD_PER_FRAME)
      {
        if (loadIndex >= loadItems.length) break;
        var item:Dynamic = loadItems[loadIndex];
        loadItem(item);
        loadedWeight = loadedWeight + item.w;
        loadIndex = loadIndex + 1;
      }
    }

    var realP:Float = totalWeight <= 0 ? 1.0 : Math.min(1.0, loadedWeight / totalWeight);
    if (timeAlive < LOAD_START_DELAY) realP = 0;
    var targetCX:Float = bfStartCX + (bfEndCX - bfStartCX) * realP;

    var moving:Bool = bfCX > targetCX + 0.01;
    if (moving) bfCX = Math.max(targetCX, bfCX - BF_SPEED * elapsed);

    bf.animation.paused = !moving;
    if (moving) chewTime += elapsed;
    placeBf(moving ? Math.sin(chewTime * 14) * BF_BOB : 0);

    var visibleW:Float = Math.max(0, Math.min(bfCX - BF_MOUTH_DX - noodleLeft, noodleFullW));
    if (visibleW < 0.5)
    {
      noodle.visible = false;
    }
    else
    {
      noodle.visible = !hideMudbang;
      noodle.clipRect = new FlxRect(0, 0, visibleW / NOODLE_SCALE, noodle.frameHeight);
    }

    if (loadIndex >= loadItems.length && bfCX <= bfEndCX + 0.01)
    {
      noodle.visible = false;
      bfCX = bfEndCX;
      bf.animation.paused = false;
      playBf('complete');
      phase = 1;
    }
  }

  function updateComplete(elapsed:Float):Void
  {
    if (bf.animation.finished)
    {
      phase = 2;
      pressEnter.visible = true;
      pressEnter.animation.play('idle', true);
    }
  }

  function updateWaitEnter(elapsed:Float):Void
  {
    var accept:Bool = FlxG.keys.justPressed.ENTER || PlayerSettings.player1.controls.ACCEPT_P || (FlxG.onMobile && TouchUtil.justPressed);
    if (accept) leave();
  }

  function leave():Void
  {
    phase = 3;
    fadeOutLoadingMusic();

    var overlay = getOrCreateFadeOverlay();
    FlxTween.tween(overlay, {alpha: 1}, FADE_OUT_TIME, {
      onComplete: function(twn) {
        stopLoadingMusic();
        var playParams = launch;
        if (playParams != null) launch.targetSong.cacheCharts(true);
        FlxG.switchState(function() {
          return new PlayState(playParams);
        });
      }
    });
  }

  /** Equivalente a onLoadParams del .script. Las canciones del mod llevan '-animania': se normaliza y se usa la tabla original. */
  function resolveBgSuffix(params:Dynamic):String
  {
    if (params == null || params.targetSong == null) return '';

    var id:String = Std.string(params.targetSong.id).toLowerCase();
    id = id.split('-animania').join('');

    if (id == 'tutorial' || id == 'bopeebo' || id == 'fresh') return '-week1';
    if (id == 'dadbattle') return '-week1-dadbattle';
    if (id == 'phone-call' || id == 'how2funk') return '-komi';
    if (id == 'winter-horrorland') return '-wh';
    return '';
  }

  /** Equivalente a onCreateBG del .script. */
  function setupVariant():Void
  {
    if (bgSuffix == '-week1-dadbattle')
    {
      hideMudbang = true;
      hideMudbangSprites();
      if (!startLoadingMusic(MUSIC_DADBATTLE, MUSIC_FADE_IN_DADBATTLE)) startLoadingMusic(MUSIC_DEFAULT, MUSIC_FADE_IN);
      buildDadbattleViz();
      addBlackFadeIn();
    }
    else if (bgSuffix == '-wh')
    {
      hideMudbang = true;
      hideMudbangSprites();
      if (startLoadingMusic(MUSIC_DEFAULT, MUSIC_FADE_IN))
      {
        FlxTween.tween(FlxG.sound.music, {pitch: WH_PITCH}, WH_PITCH_TIME, {ease: FlxEase.expoOut});
      }

      pressEnter.color = 0xFF808080;
      applyPressScale(WH_PRESS_SCALE);
      FlxG.camera.bgColor = 0xFF000000;
      addBlackFadeIn();
    }
    else
    {
      startLoadingMusic(MUSIC_DEFAULT, MUSIC_FADE_IN);
    }
  }

  function hideMudbangSprites():Void
  {
    box.visible = false;
    noodle.visible = false;
    bf.visible = false;
  }

  /** Pantalla negra que se desvanece por encima de todo (el script la añade al final de onCreateBG). */
  function addBlackFadeIn():Void
  {
    var black:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
    black.scrollFactor.set(0, 0);
    add(black);

    FlxTween.tween(black, {alpha: 0}, BLACK_FADE_TIME, {
      ease: FlxEase.circOut,
      onComplete: function(twn) {
        remove(black, true);
        black.destroy();
      }
    });
  }

  // ---------------------------------------------------------------- Música

  function firstExistingMusic(keys:Array<String>):Dynamic
  {
    for (key in keys)
    {
      var path:String = Paths.music(key);
      if (Assets.exists(path)) return path;
    }
    return null;
  }

  /** @return true si la música de carga quedó sonando como FlxG.sound.music. */
  function startLoadingMusic(keys:Array<String>, fadeTime:Float):Bool
  {
    var path = firstExistingMusic(keys);
    if (path == null)
    {
      trace('[NewLoadingState] No encontré la música de carga (' + keys + ').');
      return false;
    }

    var old = FlxG.sound.music;
    if (old != null)
    {
      if (old.fadeTween != null) old.fadeTween.cancel();
      old.stop();
      old.kill();
    }

    var snd = FunkinSound.load(path, 0, true, false, true);
    if (snd == null)
    {
      FlxG.sound.music = null;
      return false;
    }

    FlxG.sound.music = snd;
    snd.fadeIn(fadeTime, 0.0, 1.0);
    return true;
  }

  function fadeOutLoadingMusic():Void
  {
    var music = FlxG.sound.music;
    if (music == null) return;

    FlxTween.cancelTweensOf(music);
    if (music.fadeTween != null) music.fadeTween.cancel();
    music.fadeOut(FADE_OUT_TIME, 0);
  }

  function stopLoadingMusic():Void
  {
    analyzer = null;
    dadbattleViz = [];

    var music = FlxG.sound.music;
    if (music == null) return;

    FlxTween.cancelTweensOf(music);
    if (music.fadeTween != null) music.fadeTween.cancel();
    music.stop();
    music.destroy();
    FlxG.sound.music = null;
  }

  // ---------------------------------------------------- Visualizador (dadbattle)

  /** @return true si el visualizador quedó armado. */
  function buildDadbattleViz():Bool
  {
    var frames = null;
    try
    {
      frames = Paths.getAnimateAtlas(VIZ_ATLAS, null, null);
    }
    catch (e:Dynamic)
    {
      trace('[NewLoadingState] No pude cargar el atlas ' + VIZ_ATLAS + ': ' + e);
      return false;
    }

    // Se insertan justo encima del fondo para no tapar el "press enter".
    var insertAt:Int = members.indexOf(bg) + 1;

    for (i in 1...(VIZ_COUNT + 1))
    {
      var viz:FunkinSprite = new FunkinSprite();
      viz.frames = frames;
      viz.antialiasing = true;

      // Cada barra es una etiqueta 'viz<i>'. Se deja pausada: el frame lo controla el analizador de audio cada update.
      viz.animation.addByFrameLabel('y', 'viz' + i, 24, false);
      viz.animation.play('y', true);
      viz.animation.curAnim.finish();
      viz.animation.curAnim.curFrame = 0;

      viz.scale.set(bg.scale.x, bg.scale.y);
      viz.updateHitbox();
      viz.screenCenter();
      viz.x = viz.x + VIZ_OFFSET_X;
      viz.y = viz.y + VIZ_OFFSET_Y;

      insert(insertAt, viz);
      insertAt = insertAt + 1;
      dadbattleViz.push(viz);
      vizBaseScale.push({x: viz.scale.x, y: viz.scale.y});
    }

    analyzer = createAnalyzer(FlxG.sound.music, VIZ_COUNT);
    if (analyzer == null) trace('[NewLoadingState] No pude crear el SpectralAnalyzer; el visualizador quedará quieto.');

    return true;
  }

  /**
   * En V-Slice el analizador es funkin.vis.dsp.SpectralAnalyzer y recibe el AudioSource del canal (igual que ABotVis:
   * snd._channel.__audioSource, ambos privados, por eso Reflect). Se calibra como ABotVis.
   */
  function createAnalyzer(snd:Dynamic, bars:Int):Dynamic
  {
    if (snd == null) return null;

    var channel = Reflect.field(snd, '_channel');
    if (channel == null) return null;

    var source = Reflect.field(channel, '__audioSource');
    if (source == null) return null;

    var result = new SpectralAnalyzer(source, bars, VIZ_MAX_DELTA, 30);
    result.minDb = VIZ_MIN_DB;
    result.maxDb = VIZ_MAX_DB;
    return result;
  }

  /** Equivalente a doDadbattleTTF del .script. */
  function updateDadbattleViz(elapsed:Float):Void
  {
    if (analyzer == null) return;

    vizLevels = analyzer.getLevels(vizLevels);
    if (vizLevels == null) return;

    var follow:Float = Math.max(0, Math.min(1, elapsed * VIZ_FOLLOW));

    for (i in 0...dadbattleViz.length)
    {
      if (i >= vizLevels.length) break;

      var viz = dadbattleViz[i];
      var cur:Float = viz.animation.curAnim.curFrame;

      var target:Float = vizLevels[i].value * VIZ_GAIN;
      target = Math.max(0, Math.min(VIZ_MAX_FRAME, target));

      cur = cur + (target - cur) * follow;
      viz.animation.curAnim.curFrame = Math.round(cur);
    }
  }

  override function destroy():Void
  {
    analyzer = null;
    dadbattleViz = [];
    vizBaseScale = [];
    super.destroy();
  }

  function bopBackground():Void
  {
    FlxTween.num(BOP_SCALE, 1.0, BOP_TIME, {ease: FlxEase.quadOut}, function(v) {
      bg.scale.set(bgBaseScaleX * v, bgBaseScaleY * v);

      for (i in 0...dadbattleViz.length)
      {
        if (i >= vizBaseScale.length) break;
        dadbattleViz[i].scale.set(vizBaseScale[i].x * v, vizBaseScale[i].y * v);
      }
    });
  }

  function getOrCreateFadeOverlay():Dynamic
  {
    var overlay = FlxG.stage.getChildByName(FADE_OVERLAY_NAME);
    if (overlay == null)
    {
      overlay = new Sprite();
      overlay.name = FADE_OVERLAY_NAME;
      overlay.mouseEnabled = false;
      overlay.graphics.beginFill(0x000000, 1);
      overlay.graphics.drawRect(-4096, -4096, 16384, 16384);
      overlay.graphics.endFill();
      overlay.alpha = 0;
      FlxG.stage.addChild(overlay);
    }
    return overlay;
  }
}
