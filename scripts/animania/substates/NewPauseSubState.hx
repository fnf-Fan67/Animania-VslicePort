package animania.substates;

class NewPauseSubState extends MusicBeatSubState
{
  var BG_ALPHA:Float = 0.6;
  var BG_FADE_TIME:Float = 0.8;

  var TILT_ANGLE:Float = 2;
  var ZOOM_MULT:Float = 1.1;
  var CAM_IN_TIME:Float = 0.6;
  var CAM_OUT_TIME:Float = 0.35;

  var MUSIC_FADEOUT_TIME:Float = 1.5;
  var PAUSE_MUSIC_FADE_TIME:Float = 5;

  var BOP_SCALE:Float = 1.12;
  var BOP_TIME:Float = 0.25;

  var MENU_LEFT_X:Float = 0;
  var MENU_LEFT_Y:Float = 0;
  var RESUME_X:Float = 14;
  var RESUME_Y:Float = 164;
  var RESTART_X:Float = 29;
  var RESTART_Y:Float = 318;
  var CHANGEDIFF_X:Float = 28;
  var CHANGEDIFF_Y:Float = 480;

  var DIFF_EASY_X:Float = 21;
  var DIFF_EASY_Y:Float = 180;
  var DIFF_NORMAL_X:Float = 26;
  var DIFF_NORMAL_Y:Float = 322;
  var DIFF_HARD_X:Float = 61;
  var DIFF_HARD_Y:Float = 444;
  var DIFF_EXIT_X:Float = 364;
  var DIFF_EXIT_Y:Float = 583;

  var OPTIONS_X:Float = 370;
  var OPTIONS_Y:Float = 441;
  var MAIN_EXIT_X:Float = 364;
  var MAIN_EXIT_Y:Float = 583;
  var OPTIONS_ASSET:String = 'pause/buttons/eng/Options';
  var OPTIONS_PREFIX:String = 'options';
  var DIFF_OTHER_X:Float = 40;
  var DIFF_OTHER_Y:Float = 180;
  var DIFF_OTHER_STEP:Float = 90;

  var CHANGEDIFF_ASSET:String = 'pause/buttons/eng/Change Difficulty';
  var CHANGEDIFF_PREFIX:String = 'change difficulty';
  var EXIT_ASSET:String = 'pause/buttons/eng/Exit';
  var EXIT_PREFIX:String = 'exit';
  var DIFFS_ASSET:String = 'pause/buttons/eng/defaultDiffs';
  var MENU_LEFT_DIFF_ASSET:String = 'pause/menuleft';

  var STICKER_PACKS:Array<Dynamic> = [
    {
      folder: 'week1',
      left: 'gf1',
      right: 'bf2',
      songs: ['bopeebo-animania', 'fresh-animania', 'dadbattle-animania']
    },
    {
      folder: 'week5',
      left: 'gf1',
      right: 'bf2',
      songs: ['cocoa-animania', 'eggnog-animania', 'winter-horrorland-animania']
    },
    {
      folder: 'komi',
      left: 'komi',
      right: 'tadano',
      songs: ['phone-call']
    }
  ];

  var MOD_OPTIONS_ID:String = 'animania';

  var OPT_PANEL_X:Float = 49;
  var OPT_PANEL_Y:Float = 52;
  var OPT_PANEL_W:Float = 1198;
  var OPT_PANEL_H:Float = 616;
  var OPT_PANEL_ALPHA:Float = 0.85;
  var OPT_HIGHLIGHT_ALPHA:Float = 0.15;
  var OPT_ROW_H:Float = 30;
  var OPT_ROW_PAD:Float = 7;
  var OPT_FONT:String = 'vcr.ttf';
  var OPT_FONT_SIZE:Int = 23;
  var OPT_FADE_TIME:Float = 0.2;
  var OPT_PREBUILD_AT:Float = 2.2;   // la pagina de Options se arma de a poco desde este segundo (ya terminada la intro)
  var OPT_ROWS_PER_STEP:Int = 3;     // filas que se construyen por frame

  var BANNER_FONT:String = 'SQR721B.ttf';
  var BANNER_SIZE:Int = 40;
  var BANNER_TEXT:String = 'OPTIONS! ';
  var BANNER_SPEED:Float = 120;
  var BANNER_SPACE_W:Float = 12;
  var BANNER_L:Float = 49;
  var BANNER_R:Float = 1247;
  var BANNER_FADE:Float = 120;
  var BANNER_FADE_STEPS:Int = 6;   // el degradado de cada borde se hace con este numero de bandas
  var BANNER_TOP_Y:Float = 26;
  var BANNER_BOTTOM_Y:Float = 694;

  var OPTION_DEFS:Array<Dynamic> = [
    {id: 'noteLeft', label: 'NOTE LEFT', type: 'key'},
    {id: 'noteDown', label: 'NOTE DOWN', type: 'key'},
    {id: 'noteUp', label: 'NOTE UP', type: 'key'},
    {id: 'noteRight', label: 'NOTE RIGHT', type: 'key'},
    {id: 'mechanics', label: 'MECHANICS', type: 'key', def: 32},
    {id: 'missVolume', label: 'MISS SOUNDS VOLUME', type: 'number', min: 0, max: 1, step: 0.1, def: 0.2},
    {id: 'hitVolume', label: 'HIT SOUNDS VOLUME', type: 'number', min: 0, max: 1, step: 0.1, def: 0},
    {id: 'framerate', label: 'FRAMERATE', type: 'number', min: 30, max: 360, step: 1},
    {id: 'showJudges', label: 'SHOW JUDGES', type: 'bool', def: true},
    {id: 'noteSplashes', label: 'NOTE SPLASHES', type: 'bool', def: true},
    {id: 'cameraShake', label: 'CAMERA SHAKE', type: 'bool', def: true},
    {id: 'hints', label: 'HINTS', type: 'bool', def: true},
    {id: 'flashingLights', label: 'FLASHING LIGHTS', type: 'bool'},
    {id: 'autoPause', label: 'AUTO PAUSE', type: 'bool'},
    {id: 'vsync', label: 'VSYNC', type: 'enum', values: ['Off', 'On', 'Adaptive']}
  ];

  var STICKER_SCALE:Float = 0.5;
  var STICKER_LEFT_CX:Float = 121;
  var STICKER_LEFT_CY:Float = 91;
  var STICKER_RIGHT_CX:Float = 262;
  var STICKER_RIGHT_CY:Float = 71;

  var UNSELECTED_COLOR:Int = 0xFFA3A3A3;
  var DIFF_UNSELECTED_COLOR:Int = 0xFFB8B8B8;

  // ---- Intro (todos los tiempos en segundos desde que abre el pause) ---
  var SLIDE_TIME:Float = 0.5;          // entrada de menuleft / menuright

  var T_FLICK:Float = 0.5;             // FlxFlicker de botones + luces (justo al terminar el slide)
  var FLICKER_TIME:Float = 0.4;        // duracion del FlxFlicker
  var FLICKER_INTERVAL:Float = 0.05;   // cada cuanto alterna visible (TIME / INTERVAL = numero PAR de toggles)
  var FLICKER_SHOW_SELECTION:Bool = false; // true = el boton seleccionado ya se ve "white" durante el flicker (sin tinte)

  var T_STICKERS:Float = 1.2;          // stickers al final: cuando todo ya esta puesto (T_ALBUM + ALBUM_FALL_TIME)
  var STICKER_STAGGER:Float = 0.12;
  var STICKER_IN_TIME:Float = 0.35;    // bop (escala) mientras se inclina
  var STICKER_SETTLE_TIME:Float = 0.45; // vuelve a su posicion base
  var STICKER_TILT:Float = 12;         // grados (izq: antihorario, der: horario)
  var STICKER_RISE:Float = 14;         // px que sube mientras entra

  var T_ALBUM:Float = 0.5;             // album: caida + alpha (sincronizado con el flicker)
  var ALBUM_FALL_TIME:Float = 0.7;
  var ALBUM_FALL_DIST:Float = 160;
  var ALBUM_FADE_FRAC:Float = 0.35;    // el alpha llega a 1 en esta fraccion de la caida
  var ALBUM_TITLE_DELAY:Float = 0;
  var ALBUM_TITLE_FALL:Float = 40;

  var T_TEXT:Float = 0.5;              // textos + calavera + contador (alpha 0 -> 1, sincronizado)
  var TEXT_FADE_TIME:Float = 0.4;

  var TEXT_COLOR:Int = 0xFFAAAAAA;     // gris de todas las letras del panel derecho

  // ---- Pantallas anchas / mobile ---------------------------------------
  // Todo el diseno esta pensado para 1280 de ancho. En pantallas anchas FlxG.width crece (cutout de
  // FullScreenScaleMode): el panel izquierdo se queda pegado a la izquierda, el derecho se pega a la
  // derecha (WIDE_SHIFT = FlxG.width - DESIGN_W) y Options queda centrado. El diseno en si no cambia.
  var DESIGN_W:Float = 1280;
  // El panel izquierdo (menuleft + botones + stickers) SIEMPRE esta anclado a x = 0, sin margenes.
  var USE_NOTCH_SAFE_AREA:Bool = false; // true = el panel derecho se aparta del notch si esta a ese lado

  // ---- Panel derecho -------------------------------------------------
  var RIGHT_X:Float = 878;
  var RIGHT_Y:Float = 0;
  var RIGHT_SLIDE:Float = 450;

  var LIGHT_CX:Float = 961;
  var LIGHT_CY:Float = 37;
  var LIGHT_ALPHA:Float = 0.8;
  var LIGHT_PULSE:Float = 0.08;

  // Fuente png + xml (assets/images/alphabet-white.png/.xml). Cambia la ruta si la tienes en otra carpeta.
  var FONT_ASSET:String = 'fonts/alphabet-white';
  var FONT_SPACE:Float = 14;
  var FONT_GAP:Float = 3;

  // Texto con "Cancion - Dificultad" que avanza hacia la derecha
  var TICKER_L:Float = 1020;
  var TICKER_R:Float = 1200;
  var TICKER_BASE_Y:Float = 30;
  var TICKER_SCALE:Float = 0.48;
  var TICKER_GAP:Float = 34;
  var TICKER_FADE:Float = 22;
  var TICKER_SPEED:Float = 90;
  var TICKER_INTERVAL:Float = 6;
  var TICKER_FIRST_DELAY:Float = 1.6;

  // Artista -> Charter
  var CREDITS_R:Float = 1271;
  var CREDITS_SCALE:Float = 0.47;
  var CREDITS_LABEL_BASE_Y:Float = 70;
  var CREDITS_NAME_BASE_Y:Float = 92;
  var CREDITS_MAX_W:Float = 190;
  var CREDITS_TIME:Float = 5;
  var CREDITS_FADE:Float = 0.3;
  var CREDITS_LOOP:Bool = true;
  // Si el texto es mas ancho que CREDITS_MAX_W ya no se achica: rebota de izquierda a derecha y vuelve.
  var CREDITS_EDGE_FADE:Float = 14;
  var CREDITS_BOUNCE_HOLD:Float = 0.8;   // pausa al inicio, al final y al volver
  var CREDITS_BOUNCE_SPEED:Float = 60;   // px por segundo
  var CREDITS_BOUNCE_MIN:Float = 0.7;    // duracion minima de cada recorrido

  var SKULL_CX:Float = 1210;
  var SKULL_CY:Float = 122;
  var SKULL_SCALE:Float = 0.75;
  var COUNT_R:Float = 1271;
  var COUNT_BASE_Y:Float = 142;
  var COUNT_SCALE:Float = 0.85;

  var ALBUM_X:Float = 1017;
  var ALBUM_Y:Float = 457;
  var ALBUM_SIZE:Float = 230;
  var ALBUM_TITLE_CX:Float = 1128;
  var ALBUM_TITLE_CY:Float = 680;
  var ALBUM_TITLE_W:Float = 237;

  var bg:FunkinSprite;
  var menuLeft:FunkinSprite;
  var resumeBtn:FunkinSprite;
  var restartBtn:FunkinSprite;
  var changeDiffBtn:FunkinSprite;
  var optionsBtn:FunkinSprite;
  var exitBtnMain:FunkinSprite;
  var menuLeftDiff:FunkinSprite;
  var menuRight:FunkinSprite;
  var lightCircle:FunkinSprite;
  var lightRestX:Float = 0;
  var lightTime:Float = 0;
  var rightItems:Array<Dynamic> = [];
  var rightItemX:Array<Float> = [];
  var rightItemY:Array<Float> = [];
  var rightKind:Array<Int> = []; // 0 = menuright, 1 = calavera/contador, 2 = album, 3 = titulo del album
  var rightOffset:Float = 0;     // desplazamiento de TODO el panel (solo se usa al salir)
  var menuRightIntro:Float = 450; // desplazamiento de menuright al entrar
  var rightTween:Dynamic;
  var menuRightTween:Dynamic;

  var rightShift:Float = 0;      // WIDE_SHIFT (menos el notch si esta a la derecha)
  var optShift:Float = 0;        // centrado de Options entre los dos paneles
  var optShiftApplied:Float = 0;

  var introT:Float = 0;
  var buttonsReady:Bool = false;
  var flickTimer:Dynamic;
  var flickDone:Int = 0;
  var introTextA:Float = 0;
  var albumA:Float = 0;
  var albumYOff:Float = 0;
  var titleA:Float = 0;
  var titleYOff:Float = 0;

  var tickChars:Array<Dynamic> = [];
  var tickOffs:Array<Float> = [];
  var tickRel:Array<Float> = [];
  var tickPeriod:Float = 1;
  var tickTotal:Float = 1;
  var tickScroll:Float = 0;
  var tickWait:Float = 0;
  var tickNextAt:Float = 0;
  var tickMoving:Bool = false;
  var tickT:Float = 0;
  var tickDur:Float = 1;

  var creditLabels:Array<String> = [];
  var creditNames:Array<String> = [];
  var creditLines:Array<Dynamic> = [];
  var creditBounceT:Float = 0;
  var creditShowTime:Float = 5;
  var creditIndex:Int = 0;
  var creditState:Int = 0;
  var creditTimer:Float = 0;
  var creditFade:Float = 0;
  var creditAlpha:Float = 1;


  var stickers:Array<Dynamic> = [];
  var stickerX:Array<Float> = [];
  var stickerY:Array<Float> = [];

  var optBuilt:Bool = false;
  var optStage:Int = 0;
  var optRowIdx:Int = 0;
  var optStripTpl:Dynamic;            // texto largo del banner (plantilla; las bandas son clones)
  var optStripPeriod:Float = 1;       // ancho de una repeticion de BANNER_TEXT
  var optMulApplied:Float = -1;

  // Cache para no recalcular cada frame lo que no cambio (HScript es lento).
  var rightLast:Array<Float> = [];
  var tickDrawn:Bool = false;
  var tickLastWin:Float = 0;
  var tickLastRm:Float = 0;
  var tickLastScroll:Float = 0;
  var creditDirty:Bool = true;
  var creditHasOver:Bool = false;
  var creditLastWinR:Float = 0;
  var creditLastRm:Float = 0;
  var creditLastAlpha:Float = 0;
  var optOpen:Bool = false;
  var optRebinding:Bool = false;
  var optEntry:Int = 0;
  var optMul:Float = 0;
  var optHold:Float = 0;
  var optRepeat:Float = 0;
  var optTween:Dynamic;
  var customDirty:Bool = false;
  var optPanel:FunkinSprite;
  var optHighlight:FunkinSprite;
  var optLabels:Array<Dynamic> = [];
  var optValues:Array<Dynamic> = [];
  var banners:Array<Dynamic> = [];

  var currentPage:Int = 0;
  var mainButtons:Array<Dynamic> = [];
  var mainButtonX:Array<Float> = [];
  var diffButtons:Array<Dynamic> = [];
  var diffButtonX:Array<Float> = [];
  var diffIds:Array<String> = [];

  var buttons:Array<Dynamic> = [];
  var buttonX:Array<Float> = [];
  var currentEntry:Int = 0;

  var pauseMusic:FunkinSound;

  var slowingDown:Bool = false;
  var fadeTween:Dynamic;
  var pitchTween:Dynamic;
  var volumeTouched:Bool = false;
  var baseVolume:Float = 1;
  var basePitch:Float = 1;
  var songWasPlaying:Bool = false;

  var justOpened:Bool = true;
  var allowInput:Bool = false;
  var closing:Bool = false;
  var camsRestored:Bool = false;

  var gameCam:Dynamic;
  var hudCam:Dynamic;
  var gameAngle0:Float = 0;
  var gameZoom0:Float = 1;
  var hudAngle0:Float = 0;
  var hudZoom0:Float = 1;

  public function new()
  {
    super();
  }

  public override function create():Void
  {
    super.create();

    computeShifts();
    buildBackground();
    buildMenuLeft();
    buildStickers();
    buildButtons();
    buildDifficultyPage();
    buildRightPanel();
    showPage(0, false);
    transitionIn();
    tiltCameras();
    startSongFadeOut();
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);
    updateLayout();
    updateIntro(elapsed);
    handleInputs(elapsed);
    updateOptionsVisuals(elapsed);
    updateRightPanel(elapsed);
  }

  public override function destroy():Void
  {
    restoreCamerasInstant();

    FlxTween.cancelTweensOf(bg);
    FlxTween.cancelTweensOf(menuLeft);
    cancelButtonTweens();

    cancelFade();

    if (optTween != null) optTween.cancel();
    flushCustom();

    if (rightTween != null) rightTween.cancel();
    if (menuRightTween != null) menuRightTween.cancel();
    if (flickTimer != null) flickTimer.cancel();
    for (b in mainButtons) FlxFlicker.stopFlickering(b);
    if (lightCircle != null) FlxFlicker.stopFlickering(lightCircle);
    if (pauseMusic != null) pauseMusic.stop();

    super.destroy();
  }

  function startPauseMusic():Void
  {
    var path:String = Paths.music('breakfast' + PauseSubState.musicSuffix + '/breakfast' + PauseSubState.musicSuffix);
    pauseMusic = FunkinSound.load(path, 0, true, true);
    if (pauseMusic == null) return;

    pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
    pauseMusic.fadeIn(PAUSE_MUSIC_FADE_TIME, 0, 0.75);
  }

  function startSongFadeOut():Void
  {
    var music = FlxG.sound.music;
    var ps = PlayState.instance;

    startPauseMusic();

    basePitch = music.pitch;
    baseVolume = music.volume;
    volumeTouched = true;
    slowingDown = true;

    music.resume();

    fadeTween = FlxTween.num(baseVolume, 0, MUSIC_FADEOUT_TIME, {ease: FlxEase.quadInOut, onComplete: function(_) {
      fadeTween = null;
      cancelFade();
    }}, function(v:Float) {
      if (FlxG.sound.music != null) FlxG.sound.music.volume = v;
    });

    pitchTween = FlxTween.num(basePitch, 0, MUSIC_FADEOUT_TIME, {ease: FlxEase.quadInOut, onComplete: function(_) {
      pitchTween = null;
      cancelFade();
    }}, function(v:Float) {
      if (FlxG.sound.music != null) FlxG.sound.music.pitch = v;
    });
  }

  function cancelFade():Void
  {
    if (fadeTween != null)
    {
      fadeTween.cancel();
      fadeTween = null;
    }

    if (pitchTween != null)
    {
      pitchTween.cancel();
      pitchTween = null;
    }

    if (!volumeTouched) return;
    volumeTouched = false;
    slowingDown = false;

    var music = FlxG.sound.music;
    if (music != null)
    {
      music.pause();
      music.volume = baseVolume;
      music.pitch = basePitch;
    }
  }

  public override function onFocusLost():Void
  {
    super.onFocusLost();
    if (Preferences.autoPause && pauseMusic != null) pauseMusic.pause();
  }

  public override function onFocus():Void
  {
    super.onFocus();
    if (Preferences.autoPause && pauseMusic != null) pauseMusic.resume();
  }

  function buildBackground():Void
  {
    bg = new FunkinSprite(0, 0);
    bg.makeSolidColor(camera.width, camera.height, FlxColor.BLACK);
    bg.alpha = 0;
    bg.scrollFactor.set(0, 0);
    bg.updateHitbox();
    add(bg);
  }

  function buildMenuLeft():Void
  {
    menuLeft = FunkinSprite.create(MENU_LEFT_X, MENU_LEFT_Y, 'pause/menuleft');
    menuLeft.scrollFactor.set(0, 0);
    add(menuLeft);
  }

  function buildButtons():Void
  {
    resumeBtn = makeButton('pause/buttons/eng/Resume', 'resume', RESUME_X, RESUME_Y, mainButtons, mainButtonX);
    restartBtn = makeButton('pause/buttons/eng/Restart', 'restart', RESTART_X, RESTART_Y, mainButtons, mainButtonX);
    changeDiffBtn = makeButton(CHANGEDIFF_ASSET, CHANGEDIFF_PREFIX, CHANGEDIFF_X, CHANGEDIFF_Y, mainButtons, mainButtonX);
    optionsBtn = makeButton(OPTIONS_ASSET, OPTIONS_PREFIX, OPTIONS_X, OPTIONS_Y, mainButtons, mainButtonX);
    exitBtnMain = makeButton(EXIT_ASSET, EXIT_PREFIX, MAIN_EXIT_X, MAIN_EXIT_Y, mainButtons, mainButtonX);
  }

  // ======================= PANEL DERECHO =======================

  function regRight(spr:Dynamic, restX:Float, kind:Int):Void
  {
    rightItems[rightItems.length] = spr;
    rightItemX[rightItemX.length] = restX;
    rightItemY[rightItemY.length] = spr.y;
    rightKind[rightKind.length] = kind;
  }

  function buildRightPanel():Void
  {
    var ps = PlayState.instance;

    menuRight = FunkinSprite.create(RIGHT_X, RIGHT_Y, 'pause/menuright');
    menuRight.scrollFactor.set(0, 0);
    add(menuRight);
    regRight(menuRight, RIGHT_X, 0);
    menuRightIntro = RIGHT_SLIDE;

    lightCircle = FunkinSprite.create(0, 0, 'pause/lightcircle');
    lightCircle.scrollFactor.set(0, 0);
    lightRestX = LIGHT_CX - lightCircle.width / 2;
    lightCircle.y = LIGHT_CY - lightCircle.height / 2;
    lightCircle.alpha = 0;
    add(lightCircle);

    albumYOff = -ALBUM_FALL_DIST;
    titleYOff = -ALBUM_TITLE_FALL;

    buildTicker(ps);
    buildCredits(ps);
    buildDeathCounter(ps);
    buildAlbum(ps);

    applyRightOffset();
  }

  function applyRightOffset():Void
  {
    for (i in 0...rightItems.length)
    {
      var k:Int = rightKind[i];
      var spr = rightItems[i];

      spr.x = rightItemX[i] + rightOffset + rightShift + ((k == 0) ? menuRightIntro : 0);
      if (k == 2) spr.y = rightItemY[i] + albumYOff;
      else if (k == 3) spr.y = rightItemY[i] + titleYOff;
    }

    if (lightCircle != null) lightCircle.x = lightRestX + rightOffset + rightShift;
  }

  function rightChanged(rm:Float):Bool
  {
    var v:Array<Float> = [rightOffset, rightShift, menuRightIntro, albumYOff, titleYOff, rm, introTextA, albumA, titleA];

    var same:Bool = rightLast.length == v.length;
    if (same)
    {
      for (i in 0...v.length)
      {
        if (v[i] != rightLast[i]) same = false;
      }
    }

    if (!same) rightLast = v;
    return !same;
  }

  function updateRightPanel(elapsed:Float):Void
  {
    if (menuRight == null) return;

    // Al abrir Options se desvanece todo el panel derecho.
    var rm:Float = 1 - optMul;

    if (rightChanged(rm))
    {
      applyRightOffset();
      for (i in 0...rightItems.length)
      {
        var k:Int = rightKind[i];
        var a:Float = rm;
        if (k == 1) a = rm * introTextA;
        else if (k == 2) a = rm * albumA;
        else if (k == 3) a = rm * titleA;
        rightItems[i].alpha = a;
      }
    }

    lightTime = lightTime + elapsed;
    lightCircle.alpha = (LIGHT_ALPHA + LIGHT_PULSE * Math.sin(lightTime * 2.2)) * rm;

    var rmText:Float = rm * introTextA;
    updateTicker(elapsed, rmText);
    updateCredits(elapsed, rmText);
  }

  // ---------- Fuente png + xml ----------

  function glyphFrame(ch:String):String
  {
    if (ch == '.') return '-period-0000';
    if (ch == ',') return '-comma-0000';
    if (ch == '!') return '-exclamation point-0000';
    if (ch == '?') return '-question mark-0000';
    if (ch == '/') return '-forward slash-0000';
    if (ch == "'") return '-apostraphie-0000';
    if (ch == '-') return '-0000';
    return ch + '0000';
  }

  // Y del glifo respecto a la linea base (h = alto ya escalado).
  function glyphRel(ch:String, h:Float, s:Float):Float
  {
    if (ch == '-') return -14 * s;
    if (ch == ',') return -6 * s;
    if (ch == "'") return -48 * s;
    if (ch == ';') return -15 * s;
    if (ch == '^') return -38 * s;
    if (ch == '_') return -2 * s;
    if (ch == '*' || ch == '+' || ch == '=' || ch == '~' || ch == '<' || ch == '>') return -12 * s - h / 2;
    // q y j bajan de la linea base (p, g e y ya traen su offset en el xml)
    if (ch == 'q') return -h + 22 * s;
    if (ch == 'j') return -h + 14 * s;
    return -h;
  }

  function makeGlyph(ch:String, s:Float):Dynamic
  {
    var key:String = glyphFrame(ch);

    var spr:FunkinSprite = FunkinSprite.createSparrow(0, 0, FONT_ASSET);
    if (spr == null || spr.frames == null)
    {
      return null;
    }

    if (spr.frames.getByName(key) == null)
    {
      spr.destroy();
      return null;
    }

    spr.animation.addByNames('g', [key], 24, false);
    spr.animation.play('g');
    spr.scale.set(s, s);
    spr.updateHitbox();
    spr.scrollFactor.set(0, 0);
    spr.alpha = 0;
    spr.color = TEXT_COLOR;
    return spr;
  }

  function layoutText(str:String, s:Float):Dynamic
  {
    var chars:Array<Dynamic> = [];
    var offs:Array<Float> = [];
    var rels:Array<Float> = [];
    var cx:Float = 0;
    var gap:Float = FONT_GAP * s;
    var lastGap:Float = 0;

    for (i in 0...str.length)
    {
      var ch:String = str.charAt(i);
      var g:Dynamic = null;
      if (ch != ' ') g = makeGlyph(ch, s);

      if (g == null)
      {
        cx = cx + FONT_SPACE * s;
        lastGap = 0;
        continue;
      }

      add(g);
      chars[chars.length] = g;
      offs[offs.length] = cx;
      rels[rels.length] = glyphRel(ch, g.height, s);
      cx = cx + g.width + gap;
      lastGap = gap;
    }

    return {chars: chars, offs: offs, rels: rels, width: cx - lastGap};
  }

  function destroyText(t:Dynamic):Void
  {
    for (c in t.chars)
    {
      remove(c, true);
      c.destroy();
    }
  }

  function layoutFit(str:String, s:Float, maxW:Float):Dynamic
  {
    var t = layoutText(str, s);
    if (t.width <= maxW || t.width <= 0) return t;

    var w:Float = t.width;
    destroyText(t);
    return layoutText(str, s * maxW / w);
  }

  // ---------- "Cancion - Dificultad" ----------

  function buildTicker(ps:Dynamic):Void
  {
    if (ps == null || ps.currentChart == null) return;

    var diff:String = ps.currentDifficulty;
    if (diff == null) diff = '';
    if (diff.length > 0) diff = diff.charAt(0).toUpperCase() + diff.substr(1);

    var seg:String = ps.currentChart.songName;
    if (diff != '') seg = seg + ' - ' + diff;

    var probe = layoutText(seg, TICKER_SCALE);
    if (probe.chars.length == 0)
    {
      destroyText(probe);
      return;
    }

    tickPeriod = probe.width + TICKER_GAP;
    var reps:Int = Std.int(Math.ceil((TICKER_R - TICKER_L) / tickPeriod)) + 2;
    tickTotal = reps * tickPeriod;

    for (r in 0...reps)
    {
      var t = (r == 0) ? probe : layoutText(seg, TICKER_SCALE);
      for (i in 0...t.chars.length)
      {
        tickChars[tickChars.length] = t.chars[i];
        tickOffs[tickOffs.length] = r * tickPeriod + t.offs[i];
        tickRel[tickRel.length] = t.rels[i];
      }
    }

    tickDur = Math.max(1.4, tickPeriod / TICKER_SPEED);
    tickNextAt = TICKER_FIRST_DELAY;
  }

  // Avanza hacia la derecha UNA vuelta (un periodo del texto) y descansa TICKER_INTERVAL segundos.
  function updateTicker(elapsed:Float, rm:Float):Void
  {
    if (tickChars.length == 0) return;

    if (tickMoving)
    {
      tickT = tickT + elapsed / tickDur;
      if (tickT >= 1)
      {
        tickT = 0;
        tickMoving = false;
        tickScroll = 0;
        tickWait = 0;
        tickNextAt = TICKER_INTERVAL;
      }
      else
      {
        tickScroll = tickPeriod * FlxEase.quadInOut(tickT);
      }
    }
    else if (rightOffset < 2 && optMul <= 0 && introTextA >= 1)
    {
      tickWait = tickWait + elapsed;
      if (tickWait >= tickNextAt)
      {
        tickMoving = true;
        tickT = 0;
      }
    }

    var winL:Float = TICKER_L + rightOffset + rightShift;
    if (tickDrawn && winL == tickLastWin && rm == tickLastRm && tickScroll == tickLastScroll) return;
    tickDrawn = true;
    tickLastWin = winL;
    tickLastRm = rm;
    tickLastScroll = tickScroll;

    var originX:Float = winL - tickPeriod;

    for (i in 0...tickChars.length)
    {
      var c = tickChars[i];
      var px:Float = originX + ((tickOffs[i] + tickScroll) % tickTotal);

      c.x = px;
      c.y = TICKER_BASE_Y + tickRel[i];

      var cx:Float = px + c.width / 2;
      var a:Float = 1;
      if (cx <= winL) a = 0;
      else if (cx < winL + TICKER_FADE) a = (cx - winL) / TICKER_FADE;

      c.alpha = a * rm;
    }
  }

  // ---------- Artista -> Charter ----------

  function buildCredits(ps:Dynamic):Void
  {
    if (ps == null || ps.currentChart == null) return;

    var artist:String = ps.currentChart.songArtist;
    var charter:String = ps.currentChart.charter;

    if (artist != null && artist != '')
    {
      creditLabels[creditLabels.length] = 'Artist';
      creditNames[creditNames.length] = artist;
    }
    if (charter != null && charter != '')
    {
      creditLabels[creditLabels.length] = 'Charter';
      creditNames[creditNames.length] = charter;
    }

    if (creditNames.length == 0) return;

    creditIndex = 0;
    showCredit(0);
  }

  function clearCreditGlyphs():Void
  {
    for (line in creditLines) destroyText(line);
    creditLines = [];
  }

  function addCreditLine(t:Dynamic, baseY:Float):Void
  {
    var over:Float = t.width - CREDITS_MAX_W;
    if (over < 0) over = 0;

    var move:Float = over / CREDITS_BOUNCE_SPEED;
    if (move < CREDITS_BOUNCE_MIN) move = CREDITS_BOUNCE_MIN;

    var ys:Array<Float> = [];
    for (i in 0...t.chars.length) ys[ys.length] = baseY + t.rels[i];

    creditLines[creditLines.length] = {chars: t.chars, offs: t.offs, ys: ys, width: t.width, over: over, move: move};
  }

  function bounceCycle(move:Float):Float
  {
    return CREDITS_BOUNCE_HOLD * 3 + move * 2;
  }

  // 0 = inicio del texto, 1 = final del texto. Pausa, va, pausa, vuelve, pausa.
  function bounceFrac(t:Float, move:Float):Float
  {
    var h:Float = CREDITS_BOUNCE_HOLD;
    var cyc:Float = bounceCycle(move);
    t = t % cyc;

    if (t < h) return 0;
    t = t - h;
    if (t < move) return FlxEase.sineInOut(t / move);
    t = t - move;
    if (t < h) return 1;
    t = t - h;
    if (t < move) return 1 - FlxEase.sineInOut(t / move);
    return 0;
  }

  function showCredit(i:Int):Void
  {
    clearCreditGlyphs();

    addCreditLine(layoutText(creditLabels[i], CREDITS_SCALE), CREDITS_LABEL_BASE_Y);
    addCreditLine(layoutText(creditNames[i], CREDITS_SCALE), CREDITS_NAME_BASE_Y);

    // Cada credito se queda lo necesario para completar su rebote.
    creditBounceT = 0;
    creditShowTime = CREDITS_TIME;
    creditHasOver = false;
    creditDirty = true;
    for (line in creditLines)
    {
      if (line.over > 0)
      {
        creditHasOver = true;
        var cyc:Float = bounceCycle(line.move);
        if (cyc > creditShowTime) creditShowTime = cyc;
      }
    }
  }

  function updateCredits(elapsed:Float, rm:Float):Void
  {
    if (creditLines.length == 0) return;

    var idle:Bool = rightOffset < 2 && optMul <= 0 && introTextA >= 1;

    if (creditState == 0)
    {
      if (idle)
      {
        creditBounceT = creditBounceT + elapsed;

        var canAdvance:Bool = creditNames.length > 1 && (CREDITS_LOOP || creditIndex < creditNames.length - 1);
        if (canAdvance)
        {
          creditTimer = creditTimer + elapsed;
          if (creditTimer >= creditShowTime)
          {
            creditState = 1;
            creditFade = 0;
          }
        }
      }
    }
    else if (creditState == 1)
    {
      creditFade = creditFade + elapsed / CREDITS_FADE;
      creditAlpha = 1 - creditFade;
      if (creditFade >= 1)
      {
        creditIndex = creditIndex + 1;
        if (creditIndex >= creditNames.length) creditIndex = 0;
        showCredit(creditIndex);
        creditState = 2;
        creditFade = 0;
        creditAlpha = 0;
      }
    }
    else
    {
      creditFade = creditFade + elapsed / CREDITS_FADE;
      creditAlpha = creditFade;
      if (creditFade >= 1)
      {
        creditAlpha = 1;
        creditState = 0;
        creditTimer = 0;
      }
    }

    if (creditAlpha < 0) creditAlpha = 0;
    if (creditAlpha > 1) creditAlpha = 1;

    var winR:Float = CREDITS_R + rightOffset + rightShift;
    var winL:Float = winR - CREDITS_MAX_W;

    // Si no hay rebote ni fundido ni movimiento del panel, no hay nada que recalcular.
    if (!creditDirty && !creditHasOver && winR == creditLastWinR && rm == creditLastRm && creditAlpha == creditLastAlpha) return;
    creditDirty = false;
    creditLastWinR = winR;
    creditLastRm = rm;
    creditLastAlpha = creditAlpha;

    for (line in creditLines)
    {
      var frac:Float = 0;
      var base:Float = winR - line.width; // cabe: alineado a la derecha como antes
      if (line.over > 0)
      {
        frac = bounceFrac(creditBounceT, line.move);
        base = winL - line.over * frac;
      }

      // Solo se difumina el borde hacia el que hay texto escondido.
      var fadeL:Float = CREDITS_EDGE_FADE * Math.min(1, frac * 6);
      var fadeR:Float = CREDITS_EDGE_FADE * Math.min(1, (1 - frac) * 6);

      for (i in 0...line.chars.length)
      {
        var c = line.chars[i];
        c.x = base + line.offs[i];
        c.y = line.ys[i];

        var a:Float = creditAlpha;
        if (line.over > 0)
        {
          var cx:Float = c.x + c.width / 2;
          if (cx >= winR) a = 0;
          else if (fadeR > 0 && cx > winR - fadeR) a = a * (winR - cx) / fadeR;

          if (cx <= winL) a = 0;
          else if (fadeL > 0 && cx < winL + fadeL) a = a * (cx - winL) / fadeL;
        }

        c.alpha = a * rm;
      }
    }
  }

  // ---------- Calavera + contador ----------

  function buildDeathCounter(ps:Dynamic):Void
  {
    var skull:FunkinSprite = FunkinSprite.create(0, 0, 'pause/skull');
    skull.scrollFactor.set(0, 0);
    skull.scale.set(SKULL_SCALE, SKULL_SCALE);
    skull.updateHitbox();
    skull.x = SKULL_CX - skull.width / 2;
    skull.y = SKULL_CY - skull.height / 2;
    skull.alpha = 0;
    add(skull);
    regRight(skull, skull.x, 1);

    var n:Int = 0;
    if (ps != null) n = ps.deathCounter;

    var t = layoutText(Std.string(n), COUNT_SCALE);
    var left:Float = COUNT_R - t.width;
    for (i in 0...t.chars.length)
    {
      var c = t.chars[i];
      c.x = left + t.offs[i];
      c.y = COUNT_BASE_Y + t.rels[i];
      regRight(c, c.x, 1);
    }
  }

  // ---------- Album de la cancion ----------

  function buildAlbum(ps:Dynamic):Void
  {
    if (ps == null || ps.currentSong == null || ps.currentChart == null) return;

    var albumId:String = ps.currentSong.getAlbumId(ps.currentDifficulty, ps.currentChart.variation);
    if (albumId == null || albumId == '') return;

    var album = AlbumRegistry.instance.fetchEntry(albumId);
    if (album == null) return;

    var art:FunkinSprite = FunkinSprite.create(ALBUM_X, ALBUM_Y, album.getAlbumArtAssetKey());
    if (art.frameWidth <= 1)
    {
      art.destroy();
      return;
    }

    var sc:Float = ALBUM_SIZE / art.frameWidth;
    art.scale.set(sc, sc);
    art.updateHitbox();
    art.x = ALBUM_X;
    art.y = ALBUM_Y;
    art.scrollFactor.set(0, 0);
    art.alpha = 0;
    add(art);
    regRight(art, ALBUM_X, 2);

    var title:FunkinSprite = FunkinSprite.createSparrow(0, 0, album.getAlbumTitleAssetKey());
    if (title.frames == null)
    {
      title.destroy();
      return;
    }

    title.animation.addByPrefix('idle', 'idle0', 24, true);
    title.animation.play('idle');

    if (ALBUM_TITLE_W > 0 && title.frameWidth > 1)
    {
      var ts:Float = ALBUM_TITLE_W / title.frameWidth;
      title.scale.set(ts, ts);
    }
    title.updateHitbox();
    title.x = ALBUM_TITLE_CX - title.width / 2;
    title.y = ALBUM_TITLE_CY - title.height / 2;
    title.scrollFactor.set(0, 0);
    title.alpha = 0;
    add(title);
    regRight(title, title.x, 3);
  }

  function findStickerPack():Dynamic
  {
    var ps = PlayState.instance;
    if (ps == null || ps.currentSong == null) return null;

    var songId = ps.currentSong.id.toLowerCase();
    for (i in 0...STICKER_PACKS.length)
    {
      var pack = STICKER_PACKS[i];
      var songs = pack.songs;
      for (j in 0...songs.length)
      {
        if (songs[j].toLowerCase() == songId) return pack;
      }
    }
    return null;
  }

  function buildStickers():Void
  {
    var pack = findStickerPack();
    if (pack == null) return;

    addSticker(pack.folder, pack.left, STICKER_LEFT_CX, STICKER_LEFT_CY);
    addSticker(pack.folder, pack.right, STICKER_RIGHT_CX, STICKER_RIGHT_CY);
  }

  function addSticker(folder:String, name:String, cx:Float, cy:Float):Void
  {
    var spr:FunkinSprite = FunkinSprite.create(0, 0, 'pause/stickers/' + folder + '/' + name);
    spr.scale.set(STICKER_SCALE, STICKER_SCALE);
    spr.updateHitbox();
    spr.x = cx - spr.width / 2;
    spr.y = cy - spr.height / 2;
    spr.scrollFactor.set(0, 0);
    add(spr);

    spr.alpha = 0; // invisibles hasta su bop de entrada

    stickers[stickers.length] = spr;
    stickerX[stickerX.length] = spr.x;
    stickerY[stickerY.length] = spr.y;
  }

  function buildDifficultyPage():Void
  {
    var ps = PlayState.instance;
    var list:Array<String> = [];
    if (ps != null && ps.currentSong != null && ps.currentChart != null)
    {
      list = ps.currentSong.listDifficulties(ps.currentChart.variation, null, false, false);
    }

    for (i in 0...list.length)
    {
      var id:String = list[i];
      diffIds[i] = id;
      var bx:Float = diffX(id, i);
      var by:Float = diffY(id, i);

      var btn:Dynamic;
      if (isKnownDifficulty(id))
      {
        btn = makeButton(diffAssetKey(id), id.toLowerCase(), bx, by, diffButtons, diffButtonX);
      }
      else
      {
        btn = new FlxText(bx, by, 0, StringTools.replace(id.toUpperCase(), '-', ' '), 48);
        btn.setFormat(Paths.font('vcr.ttf'), 48, FlxColor.WHITE);
        btn.scrollFactor.set(0, 0);
        add(btn);
        diffButtons[diffButtons.length] = btn;
        diffButtonX[diffButtonX.length] = bx;
      }
      btn.visible = false;
    }

    var exitBtn:FunkinSprite = makeButton(EXIT_ASSET, EXIT_PREFIX, DIFF_EXIT_X, DIFF_EXIT_Y, diffButtons, diffButtonX);
    exitBtn.visible = false;

    if (MENU_LEFT_DIFF_ASSET != 'pause/menuleft')
    {
      menuLeftDiff = FunkinSprite.create(MENU_LEFT_X, MENU_LEFT_Y, MENU_LEFT_DIFF_ASSET);
      menuLeftDiff.scrollFactor.set(0, 0);
      menuLeftDiff.visible = false;
      add(menuLeftDiff);
    }
  }

  function isKnownDifficulty(id:String):Bool
  {
    var d:String = id.toLowerCase();
    return d == 'easy' || d == 'normal' || d == 'hard';
  }

  function diffAssetKey(id:String):String
  {
    return DIFFS_ASSET;
  }

  function diffX(id:String, index:Int):Float
  {
    var d:String = id.toLowerCase();
    if (d == 'easy') return DIFF_EASY_X;
    if (d == 'normal') return DIFF_NORMAL_X;
    if (d == 'hard') return DIFF_HARD_X;
    return DIFF_OTHER_X;
  }

  function diffY(id:String, index:Int):Float
  {
    var d:String = id.toLowerCase();
    if (d == 'easy') return DIFF_EASY_Y;
    if (d == 'normal') return DIFF_NORMAL_Y;
    if (d == 'hard') return DIFF_HARD_Y;
    return DIFF_OTHER_Y + DIFF_OTHER_STEP * index;
  }

  function showPage(page:Int, bop:Bool):Void
  {
    currentPage = page;

    for (b in mainButtons) b.visible = (page == 0);
    for (b in diffButtons) b.visible = (page == 1);

    buttons = (page == 0) ? mainButtons : diffButtons;
    buttonX = (page == 0) ? mainButtonX : diffButtonX;

    for (i in 0...buttons.length)
    {
      FlxTween.cancelTweensOf(buttons[i]);
      if (page == 1) buttons[i].x = buttonX[i];
    }

    if (menuLeftDiff != null)
    {
      menuLeft.visible = (page == 0);
      menuLeftDiff.visible = (page == 1);
    }

    for (b in mainButtons) b.scale.set(1, 1);
    for (b in diffButtons) b.scale.set(1, 1);

    currentEntry = 0;
    if (page == 1)
    {
      for (i in 0...diffIds.length)
      {
        if (diffIds[i].toLowerCase() == 'easy') currentEntry = i;
      }
    }

    refreshSelection();
    if (bop) bopButton(buttons[currentEntry]);
  }

  function bopButton(btn:Dynamic):Void
  {
    if (btn == null || BOP_SCALE == 1) return;
    FlxTween.cancelTweensOf(btn.scale);
    btn.scale.set(BOP_SCALE, BOP_SCALE);
    FlxTween.tween(btn.scale, {x: 1, y: 1}, BOP_TIME, {ease: FlxEase.quadOut});
  }

  function makeButton(atlasKey:String, prefix:String, bx:Float, by:Float, list:Array<Dynamic>, listX:Array<Float>):FunkinSprite
  {
    var btn:FunkinSprite = FunkinSprite.createSparrow(bx, by, atlasKey);
    btn.animation.addByPrefix('basic', prefix + ' basic', 24, false);
    btn.animation.addByPrefix('white', prefix + ' white', 24, false);
    btn.animation.play('basic');
    btn.scrollFactor.set(0, 0);
    add(btn);
    list[list.length] = btn;
    listX[listX.length] = bx;
    return btn;
  }

  function transitionIn():Void
  {
    FlxTween.tween(bg, {alpha: BG_ALPHA}, BG_FADE_TIME, {ease: FlxEase.quartOut});

    // Primero entran menuleft y menuright. Todo lo demas espera su turno en updateIntro().
    menuLeft.x = MENU_LEFT_X - menuLeft.width;
    FlxTween.tween(menuLeft, {x: MENU_LEFT_X}, SLIDE_TIME, {ease: FlxEase.quartOut});

    if (menuRightTween != null) menuRightTween.cancel();
    menuRightIntro = RIGHT_SLIDE;
    menuRightTween = FlxTween.num(RIGHT_SLIDE, 0, SLIDE_TIME, {ease: FlxEase.quartOut}, function(v:Float) {
      menuRightIntro = v;
    });

    // Botones y luces listos pero invisibles hasta su FlxFlicker (que alterna .visible).
    for (b in mainButtons) b.visible = false;
    lightCircle.visible = false;

    if (flickTimer != null) flickTimer.cancel();
    flickTimer = new FlxTimer().start(T_FLICK, function(_) {
      startFlicker();
    });
  }

  function clamp01(v:Float):Float
  {
    if (v < 0) return 0;
    if (v > 1) return 1;
    return v;
  }

  // ======================= PANTALLAS ANCHAS / MOBILE =======================

  function computeShifts():Void
  {
    var wide:Float = FlxG.width - DESIGN_W;
    if (wide < 0) wide = 0;

    var nr:Float = 0;
    if (USE_NOTCH_SAFE_AREA)
    {
      var nw:Float = FullScreenScaleMode.gameNotchSize.x;
      if (nw > 0 && FullScreenScaleMode.gameNotchPosition.x + nw / 2 >= FlxG.width / 2) nr = nw;
    }

    rightShift = wide - nr;
    optShift = rightShift / 2;
  }

  // Se llama cada frame: si cambia el tamano de la ventana se reajusta todo lo que depende del ancho.
  function updateLayout():Void
  {
    computeShifts();

    if (bg != null && Math.abs(bg.width - camera.width) > 1)
    {
      bg.makeSolidColor(camera.width, camera.height, FlxColor.BLACK);
      bg.updateHitbox();
    }

    if (optBuilt && optShift != optShiftApplied) layoutOptions();

    // Options se construye de a poco, ya terminada la intro.
    if (!optBuilt && !closing && introT >= OPT_PREBUILD_AT) buildOptionsStep();
  }

  function layoutOptions():Void
  {
    optShiftApplied = optShift;

    optPanel.x = OPT_PANEL_X + optShift;
    optHighlight.x = OPT_PANEL_X + optShift;
    for (t in optLabels) t.x = OPT_PANEL_X + optShift + OPT_ROW_PAD;
    refreshAllOptionRows();
  }

  // Tocar un boton lo selecciona; tocar el ya seleccionado lo acepta. En desktop equivale a un clic.
  function handleTouchInputs():Void
  {
    if (!FlxG.onMobile || closing) return;

    var hit:Int = -1;
    for (i in 0...buttons.length)
    {
      if (hit < 0 && buttons[i].visible && TouchUtil.pressAction(buttons[i], camera, false)) hit = i;
    }
    if (hit < 0) return;

    if (hit == currentEntry)
    {
      selectEntry();
    }
    else
    {
      currentEntry = hit;
      FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
      refreshSelection();
      bopButton(buttons[currentEntry]);
    }
  }

  // Options por touch: tocar una fila la selecciona; tocar la seleccionada la cambia
  // (numeros: mitad izquierda baja, mitad derecha sube). Tocar fuera del panel cierra.
  function handleOptionsTouch():Bool
  {
    if (!FlxG.onMobile || optRebinding) return false;
    if (!TouchUtil.pressAction()) return false;

    var pt = TouchUtil.touch.getScreenPosition(camera);
    var px:Float = pt.x;
    var py:Float = pt.y;
    pt.put();

    var panelX:Float = OPT_PANEL_X + optShift;
    var panelH:Float = OPT_ROW_H * OPTION_DEFS.length;

    if (px < panelX || px > panelX + OPT_PANEL_W || py < OPT_PANEL_Y || py > OPT_PANEL_Y + panelH)
    {
      closeOptions();
      return true;
    }

    var row:Int = Math.floor((py - OPT_PANEL_Y) / OPT_ROW_H);
    if (row < 0 || row >= OPTION_DEFS.length) return false;

    if (row != optEntry)
    {
      changeOptionSelection(row - optEntry);
    }
    else
    {
      var def = OPTION_DEFS[optEntry];
      if (def.type == 'number') changeOption(def, (px < panelX + OPT_PANEL_W / 2) ? -1 : 1, false);
      else if (def.type == 'bool' || def.type == 'enum') changeOption(def, 1, false);
      // 'key' necesita teclado: no se puede reasignar por touch.
    }

    return false;
  }

  function startFlicker():Void
  {
    flickDone = 0;

    for (b in mainButtons) flickerButton(b);
    FlxFlicker.flicker(lightCircle, FLICKER_TIME, FLICKER_INTERVAL, true);

    if (mainButtons.length == 0) onButtonsReady();
  }

  function flickerButton(b:Dynamic):Void
  {
    FlxFlicker.flicker(b, FLICKER_TIME, FLICKER_INTERVAL, true, true, function(_) {
      flickDone = flickDone + 1;
      if (flickDone >= mainButtons.length) onButtonsReady();
    });
  }

  function onButtonsReady():Void
  {
    if (buttonsReady) return;

    // Recien ahora se aplican seleccion y colores.
    buttonsReady = true;
    refreshSelection();
    allowInput = true;
  }

  function updateIntro(elapsed:Float):Void
  {
    introT = introT + Math.min(elapsed, 0.1);

    updateStickers();

    // Album: cae mientras su alpha sube a 1.
    var au:Float = clamp01((introT - T_ALBUM) / ALBUM_FALL_TIME);
    albumYOff = -ALBUM_FALL_DIST * (1 - FlxEase.bounceOut(au));
    albumA = clamp01(au / ALBUM_FADE_FRAC);

    var tu:Float = clamp01((introT - T_ALBUM - ALBUM_TITLE_DELAY) / ALBUM_FALL_TIME);
    titleYOff = -ALBUM_TITLE_FALL * (1 - FlxEase.quadOut(tu));
    titleA = clamp01(tu / ALBUM_FADE_FRAC);

    // Textos, calavera y contador: alpha 0 -> 1.
    introTextA = clamp01((introT - T_TEXT) / TEXT_FADE_TIME);
  }

  // Bop (escala con rebote) mientras se inclinan, y despues vuelven a su posicion base.
  function updateStickers():Void
  {
    for (i in 0...stickers.length)
    {
      var s = stickers[i];
      var t:Float = introT - (T_STICKERS + i * STICKER_STAGGER);

      if (t < 0)
      {
        s.alpha = 0;
        s.scale.set(0, 0);
      }
      else
      {
        var u:Float = clamp01(t / STICKER_IN_TIME);
        var v:Float = clamp01((t - STICKER_IN_TIME) / STICKER_SETTLE_TIME);
        var dir:Float = (i % 2 == 0) ? -1 : 1;
        var sc:Float = STICKER_SCALE * FlxEase.backOut(u);

        s.alpha = 1;
        s.scale.set(sc, sc);
        s.angle = dir * STICKER_TILT * FlxEase.quadOut(u) * (1 - FlxEase.backOut(v));
        s.y = stickerY[i] + STICKER_RISE * (1 - FlxEase.quadOut(u));
      }
    }
  }

  function tiltCameras():Void
  {
    var ps = PlayState.instance;
    if (ps == null) return;

    gameCam = ps.camGame;
    hudCam = ps.camHUD;

    gameAngle0 = gameCam.angle;
    gameZoom0 = gameCam.zoom;
    hudAngle0 = hudCam.angle;
    hudZoom0 = hudCam.zoom;

    FlxTween.tween(gameCam, {angle: gameAngle0 + TILT_ANGLE, zoom: gameZoom0 * ZOOM_MULT}, CAM_IN_TIME, {ease: FlxEase.quartOut});
    FlxTween.tween(hudCam, {angle: hudAngle0 + TILT_ANGLE, zoom: hudZoom0 * ZOOM_MULT}, CAM_IN_TIME, {ease: FlxEase.quartOut});
  }

  function restoreCamerasInstant():Void
  {
    if (camsRestored || gameCam == null) return;
    camsRestored = true;

    FlxTween.cancelTweensOf(gameCam);
    FlxTween.cancelTweensOf(hudCam);
    gameCam.angle = gameAngle0;
    gameCam.zoom = gameZoom0;
    hudCam.angle = hudAngle0;
    hudCam.zoom = hudZoom0;
  }

  function refreshSelection():Void
  {
    for (i in 0...buttons.length)
    {
      var btn:Dynamic = buttons[i];
      var isDiffArt:Bool = (currentPage == 1 && i < diffIds.length);

      if (Std.isOfType(btn, FlxText))
      {
        btn.color = (i == currentEntry) ? FlxColor.WHITE : UNSELECTED_COLOR;
      }
      else if (!buttonsReady && !(FLICKER_SHOW_SELECTION && i == currentEntry))
      {
        // Durante el flicker: sin seleccion y sin colores.
        btn.animation.play('basic');
        btn.color = FlxColor.WHITE;
      }
      else if (i == currentEntry)
      {
        btn.animation.play('white');
        btn.color = FlxColor.WHITE;
      }
      else
      {
        btn.animation.play('basic');
        btn.color = isDiffArt ? DIFF_UNSELECTED_COLOR : UNSELECTED_COLOR;
      }
    }
  }

  function handleInputs(elapsed:Float):Void
  {
    if (!allowInput || closing || slowingDown) return;

    if (justOpened)
    {
      justOpened = false;
      return;
    }

    if (optOpen)
    {
      handleOptionsInputs(elapsed);
      return;
    }

    if (controls.UI_UP_P) changeSelection(-1);
    if (controls.UI_DOWN_P) changeSelection(1);
    handleTouchInputs();

    if (controls.ACCEPT_P)
    {
      selectEntry();
    }
    else if (controls.PAUSE_P)
    {
      exitPause(false);
    }
    else if (controls.BACK_P && currentPage == 1)
    {
      FunkinSound.playOnce(Paths.sound('cancelMenu'), 0.4);
      showPage(0, true);
    }
  }

  function changeSelection(change:Int):Void
  {
    if (buttons.length <= 1) return;

    currentEntry += change;
    if (currentEntry < 0) currentEntry = buttons.length - 1;
    if (currentEntry >= buttons.length) currentEntry = 0;

    FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
    refreshSelection();
    bopButton(buttons[currentEntry]);
  }

  function selectEntry():Void
  {
    if (currentPage == 0)
    {
      if (currentEntry == 0) exitPause(false);
      else if (currentEntry == 1) exitPause(true);
      else if (currentEntry == 2) showPage(1, true);
      else if (currentEntry == 3) openOptions();
      else if (currentEntry == 4) exitToMenu();
    }
    else
    {
      if (currentEntry < diffIds.length) changeDifficulty(diffIds[currentEntry]);
      else showPage(0, true);
    }
  }

  function openOptions():Void
  {
    if (optOpen || closing) return;
    if (!optBuilt) buildOptionsPage();

    optOpen = true;
    optRebinding = false;
    optEntry = 0;
    optHold = 0;
    optRepeat = 0;

    refreshAllOptionRows();
    updateOptionHighlight();
    setOptionsVisible(true);

    FunkinSound.playOnce(Paths.sound('confirmMenu'), 0.4);
    tweenOptionsMul(1);
  }

  function closeOptions():Void
  {
    optOpen = false;
    optRebinding = false;
    flushCustom();

    FunkinSound.playOnce(Paths.sound('cancelMenu'), 0.4);
    tweenOptionsMul(0);
  }

  function tweenOptionsMul(target:Float):Void
  {
    if (optTween != null) optTween.cancel();
    optTween = FlxTween.num(optMul, target, OPT_FADE_TIME, {ease: FlxEase.quadOut, onComplete: function(_) {
      optTween = null;
      if (target <= 0) setOptionsVisible(false);
    }}, function(v:Float) {
      optMul = v;
    });
  }

  function setOptionsVisible(vis:Bool):Void
  {
    optPanel.visible = vis;
    optHighlight.visible = vis;
    for (t in optLabels) t.visible = vis;
    for (t in optValues) t.visible = vis;
    for (b in banners)
    {
      for (c in b.chars) c.visible = vis;
    }
  }


  // Se arma en segundo plano, un pedazo por frame, para que abrir Options no trabe.
  // Si se abre antes de terminar, buildOptionsPage() completa lo que falte.
  function buildOptionsPage():Void
  {
    while (!optBuilt) buildOptionsStep();
  }

  function buildOptionsStep():Void
  {
    if (optBuilt) return;

    if (optStage == 0)
    {
      optShiftApplied = optShift;

      optPanel = new FunkinSprite(OPT_PANEL_X + optShift, OPT_PANEL_Y);
      optPanel.makeSolidColor(Std.int(OPT_PANEL_W), Std.int(OPT_PANEL_H), FlxColor.BLACK);
      optPanel.scrollFactor.set(0, 0);
      optPanel.alpha = 0;
      add(optPanel);

      optHighlight = new FunkinSprite(OPT_PANEL_X + optShift, OPT_PANEL_Y);
      optHighlight.makeSolidColor(Std.int(OPT_PANEL_W), Std.int(OPT_ROW_H), FlxColor.WHITE);
      optHighlight.scrollFactor.set(0, 0);
      optHighlight.alpha = 0;
      add(optHighlight);

      optStage = 1;
    }
    else if (optStage == 1)
    {
      var n:Int = 0;
      while (n < OPT_ROWS_PER_STEP && optRowIdx < OPTION_DEFS.length)
      {
        buildOptionRow(optRowIdx);
        optRowIdx = optRowIdx + 1;
        n = n + 1;
      }
      if (optRowIdx >= OPTION_DEFS.length) optStage = 2;
    }
    else if (optStage == 2)
    {
      buildBannerStrip();
      optStage = 3;
    }
    else
    {
      buildBanner(true);
      buildBanner(false);
      setOptionsVisible(false);
      optBuilt = true;

      if (optShift != optShiftApplied) layoutOptions();
    }
  }

  function buildOptionRow(i:Int):Void
  {
    var def = OPTION_DEFS[i];
    var rowY = OPT_PANEL_Y + OPT_ROW_H * i;

    var label = new FlxText(OPT_PANEL_X + optShift + OPT_ROW_PAD, rowY, 0, def.label, OPT_FONT_SIZE);
    label.setFormat(Paths.font(OPT_FONT), OPT_FONT_SIZE, FlxColor.WHITE);
    label.scrollFactor.set(0, 0);
    label.y = rowY + (OPT_ROW_H - label.height) / 2;
    label.alpha = 0;
    add(label);
    optLabels[optLabels.length] = label;

    // Ya con su texto final para no regenerar el bitmap dos veces.
    var value = new FlxText(0, rowY, 0, formatOptionValue(def, getOptionValue(def)), OPT_FONT_SIZE);
    value.setFormat(Paths.font(OPT_FONT), OPT_FONT_SIZE, FlxColor.WHITE);
    value.scrollFactor.set(0, 0);
    value.x = OPT_PANEL_X + optShift + OPT_PANEL_W - OPT_ROW_PAD - value.width;
    value.y = label.y;
    value.alpha = 0;
    add(value);
    optValues[optValues.length] = value;
  }

  function bannerText(reps:Int):Dynamic
  {
    var str:String = '';
    for (i in 0...reps) str = str + BANNER_TEXT;

    var t = new FlxText(0, 0, 0, str, BANNER_SIZE);
    t.setFormat(Paths.font(BANNER_FONT), BANNER_SIZE, FlxColor.WHITE);
    return t;
  }

  // El banner ya no son ~130 sprites que se mueven uno a uno por script: es UN solo texto largo
  // (repeticiones de BANNER_TEXT) generado una vez. Como el patron es periodico, basta con desplazarlo
  // un periodo y volver a empezar. El degradado de los bordes se hace con pocas "bandas" (clones que
  // comparten el grafico y se recortan con clipRect), asi cada frame solo se tocan ~13 sprites por fila.
  function buildBannerStrip():Void
  {
    // Periodo = ancho(2 repeticiones) - ancho(1): el margen interno del texto se cancela.
    var p1 = bannerText(1);
    var p2 = bannerText(2);
    optStripPeriod = p2.width - p1.width;
    p1.destroy();
    p2.destroy();
    if (optStripPeriod < 1) optStripPeriod = 1;

    var winW:Float = BANNER_R - BANNER_L;
    var reps:Int = Std.int(Math.ceil((winW + optStripPeriod) / optStripPeriod)) + 1;

    var tpl = bannerText(reps);
    var forceRegen:Float = tpl.width; // leer width fuerza a generar el grafico
    tpl.scrollFactor.set(0, 0);
    tpl.alpha = 0;
    tpl.visible = false;
    add(tpl);
    optStripTpl = tpl;
  }

  function makeBand(by:Float, a:Float, b:Float, al:Float, bnr:Dynamic):Void
  {
    var t = new FunkinSprite(0, 0);
    t.loadGraphicFromSprite(optStripTpl);
    t.updateHitbox();
    t.scrollFactor.set(0, 0);
    t.y = by - t.height / 2;
    t.alpha = 0;

    var r = FlxRect.get(0, 0, 1, t.frameHeight);
    t.clipRect = r;
    add(t);

    bnr.chars[bnr.chars.length] = t;
    bnr.rects[bnr.rects.length] = r;
    bnr.relA[bnr.relA.length] = a;
    bnr.relB[bnr.relB.length] = b;
    bnr.alphas[bnr.alphas.length] = al;
  }

  function buildBanner(topRow:Bool):Void
  {
    var by:Float = topRow ? BANNER_TOP_Y : BANNER_BOTTOM_Y;
    var winW:Float = BANNER_R - BANNER_L;
    var n:Int = BANNER_FADE_STEPS;
    var bw:Float = BANNER_FADE / n;

    var bnr = {
      chars: [],
      rects: [],
      relA: [],
      relB: [],
      alphas: [],
      h: optStripTpl.frameHeight,
      period: optStripPeriod,
      dir: topRow ? 1 : -1,
      scroll: 0.0
    };

    for (k in 0...n) makeBand(by, k * bw, (k + 1) * bw, (k + 0.5) / n, bnr);
    makeBand(by, BANNER_FADE, winW - BANNER_FADE, 1, bnr);
    for (m in 0...n) makeBand(by, winW - BANNER_FADE + m * bw, winW - BANNER_FADE + (m + 1) * bw, 1 - (m + 0.5) / n, bnr);

    banners[banners.length] = bnr;
  }

  function updateOptionsVisuals(elapsed:Float):Void
  {
    if (!optBuilt || optMul <= 0) return;

    // Solo mientras cambia el fundido (0.2s), no cada frame.
    if (optMul != optMulApplied)
    {
      optMulApplied = optMul;
      optPanel.alpha = OPT_PANEL_ALPHA * optMul;
      optHighlight.alpha = OPT_HIGHLIGHT_ALPHA * optMul;
      for (t in optLabels) t.alpha = optMul;
      for (t in optValues) t.alpha = optMul;
    }

    var bl:Float = BANNER_L + optShift;
    for (b in banners) updateBanner(b, elapsed, bl);
  }

  function updateBanner(b:Dynamic, elapsed:Float, bl:Float):Void
  {
    var period:Float = b.period;
    var ph:Float = (b.scroll + b.dir * BANNER_SPEED * elapsed) % period;
    if (ph < 0) ph = ph + period;
    b.scroll = ph;

    // El texto cubre [sx, sx + largo] y siempre sobra un periodo a cada lado de la ventana.
    var sx:Float = bl - period + ph;

    var chars = b.chars;
    var rects = b.rects;
    var relA = b.relA;
    var relB = b.relB;
    var alphas = b.alphas;
    var h:Float = b.h;

    for (i in 0...chars.length)
    {
      var c = chars[i];
      var a0:Int = Math.round(bl + relA[i] - sx);
      var w:Int = Math.round(bl + relB[i] - sx) - a0;

      if (w <= 0)
      {
        c.visible = false;
      }
      else
      {
        var r = rects[i];
        r.set(a0, 0, w, h);
        c.clipRect = r;
        c.x = sx;
        c.alpha = alphas[i] * optMul;
        c.visible = true;
      }
    }
  }

  function updateOptionHighlight():Void
  {
    optHighlight.y = OPT_PANEL_Y + OPT_ROW_H * optEntry;
  }

  function isNoteKey(id:String):Bool
  {
    return id == 'noteLeft' || id == 'noteDown' || id == 'noteUp' || id == 'noteRight';
  }

  function controlFor(id:String):Dynamic
  {
    if (id == 'noteLeft') return Control.NOTE_LEFT;
    if (id == 'noteDown') return Control.NOTE_DOWN;
    if (id == 'noteUp') return Control.NOTE_UP;
    return Control.NOTE_RIGHT;
  }

  function noteKeyList(id:String):Array<Dynamic>
  {
    return PlayerSettings.player1.controls.getInputsFor(controlFor(id), Device.Keys);
  }

  function getNoteKeyCode(id:String):Int
  {
    var list = noteKeyList(id);
    if (list != null && list.length > 0) return list[0];
    return 0;
  }

  function customGet(key:String, defaultValue:Dynamic):Dynamic
  {
    var o = Save.instance.getModOptions(MOD_OPTIONS_ID);
    if (Reflect.hasField(o, key)) return Reflect.field(o, key);
    return defaultValue;
  }

  function customSet(key:String, value:Dynamic):Void
  {
    var o = Save.instance.getModOptions(MOD_OPTIONS_ID);
    Reflect.setField(o, key, value);
    customDirty = true;
  }

  function flushCustom():Void
  {
    if (!customDirty) return;
    customDirty = false;
    Save.instance.setModOptions(MOD_OPTIONS_ID, Save.instance.getModOptions(MOD_OPTIONS_ID));
  }

  function getOptionValue(def:Dynamic):Dynamic
  {
    var id:String = def.id;
    if (isNoteKey(id)) return getNoteKeyCode(id);
    if (id == 'framerate') return Preferences.framerate;
    if (id == 'flashingLights') return Preferences.flashingLights;
    if (id == 'autoPause') return Preferences.autoPause;
    if (id == 'vsync')
    {
      var m = Save.instance.options.vsyncMode;
      if (m == null) return 'Off';
      return m;
    }
    return customGet(id, def.def);
  }

  function setOptionValue(def:Dynamic, v:Dynamic):Void
  {
    var id:String = def.id;
    if (id == 'framerate') Preferences.framerate = Std.int(v);
    else if (id == 'flashingLights') Preferences.flashingLights = v;
    else if (id == 'autoPause') Preferences.autoPause = v;
    else if (id == 'vsync') applyVsync(v);
    else customSet(id, v);
  }

  function applyVsync(name:String):Void
  {
    var mode = WindowVSyncMode.OFF;
    if (name == 'On') mode = WindowVSyncMode.ON;
    else if (name == 'Adaptive') mode = WindowVSyncMode.ADAPTIVE;
    Preferences.vsyncMode = mode;
  }

  function formatOptionValue(def:Dynamic, v:Dynamic):String
  {
    if (def.type == 'bool') return v ? 'ENABLED' : 'DISABLED';
    if (def.type == 'key')
    {
      if (v == null || v <= 0) return 'NONE';
      return InputUtil.getKeyName(v);
    }
    return Std.string(v);
  }

  function refreshOptionRow(i:Int):Void
  {
    var def = OPTION_DEFS[i];
    var txt = optValues[i];

    if (optRebinding && i == optEntry) txt.text = 'PRESS A KEY...';
    else txt.text = formatOptionValue(def, getOptionValue(def));

    txt.x = OPT_PANEL_X + optShift + OPT_PANEL_W - OPT_ROW_PAD - txt.width;
  }

  function refreshAllOptionRows():Void
  {
    for (i in 0...OPTION_DEFS.length) refreshOptionRow(i);
  }

  function handleOptionsInputs(elapsed:Float):Void
  {
    if (optRebinding)
    {
      updateRebind();
      return;
    }

    if (controls.BACK_P)
    {
      closeOptions();
      return;
    }

    if (handleOptionsTouch()) return;

    if (controls.UI_UP_P) changeOptionSelection(-1);
    if (controls.UI_DOWN_P) changeOptionSelection(1);

    var def = OPTION_DEFS[optEntry];
    var dir = 0;

    if (controls.UI_LEFT_P)
    {
      dir = -1;
      optHold = 0;
      optRepeat = 0;
    }
    else if (controls.UI_RIGHT_P)
    {
      dir = 1;
      optHold = 0;
      optRepeat = 0;
    }
    else if (controls.UI_LEFT || controls.UI_RIGHT)
    {
      optHold = optHold + elapsed;
      if (optHold > 0.4 && def.type == 'number')
      {
        optRepeat = optRepeat + elapsed;
        if (optRepeat >= 0.06)
        {
          optRepeat = 0;
          dir = controls.UI_LEFT ? -1 : 1;
        }
      }
    }
    else
    {
      optHold = 0;
      optRepeat = 0;
    }

    if (dir != 0) changeOption(def, dir, optHold > 1.2);

    if (controls.ACCEPT_P)
    {
      if (def.type == 'key') startRebind();
      else if (def.type == 'bool' || def.type == 'enum') changeOption(def, 1, false);
    }
  }

  function changeOptionSelection(change:Int):Void
  {
    optEntry = optEntry + change;
    if (optEntry < 0) optEntry = OPTION_DEFS.length - 1;
    if (optEntry >= OPTION_DEFS.length) optEntry = 0;

    optHold = 0;
    optRepeat = 0;

    FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
    updateOptionHighlight();
  }

  function changeOption(def:Dynamic, dir:Int, big:Bool):Void
  {
    var v = getOptionValue(def);

    if (def.type == 'bool')
    {
      setOptionValue(def, !v);
    }
    else if (def.type == 'number')
    {
      var step:Float = def.step * (big ? 5 : 1);
      var nv:Float = Math.round((v + dir * step) * 100) / 100;
      if (nv < def.min) nv = def.min;
      if (nv > def.max) nv = def.max;
      if (nv == v) return;
      setOptionValue(def, nv);
    }
    else if (def.type == 'enum')
    {
      var idx = 0;
      for (i in 0...def.values.length)
      {
        if (def.values[i] == v) idx = i;
      }
      idx = idx + dir;
      if (idx < 0) idx = def.values.length - 1;
      if (idx >= def.values.length) idx = 0;
      setOptionValue(def, def.values[idx]);
    }
    else
    {
      return;
    }

    FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
    refreshOptionRow(optEntry);
  }

  function startRebind():Void
  {
    optRebinding = true;
    refreshOptionRow(optEntry);
  }

  function updateRebind():Void
  {
    var k:Int = FlxG.keys.firstJustPressed();
    if (k <= 0) return;

    optRebinding = false;

    if (k == 27)
    {
      FunkinSound.playOnce(Paths.sound('cancelMenu'), 0.4);
      refreshOptionRow(optEntry);
      return;
    }

    applyKeyBinding(OPTION_DEFS[optEntry], k);
    FunkinSound.playOnce(Paths.sound('confirmMenu'), 0.4);
    refreshAllOptionRows();
  }

  function applyKeyBinding(def:Dynamic, k:Int):Void
  {
    var id:String = def.id;

    if (!isNoteKey(id))
    {
      customSet(id, k);
      return;
    }

    var pc = PlayerSettings.player1.controls;
    var device = Device.Keys;
    var old = getNoteKeyCode(id);
    if (old == k) return;

    var ids = ['noteLeft', 'noteDown', 'noteUp', 'noteRight'];
    for (j in 0...ids.length)
    {
      if (ids[j] == id) continue;
      if (noteKeyList(ids[j]).indexOf(k) >= 0) pc.replaceBinding(controlFor(ids[j]), device, old, k);
    }

    pc.replaceBinding(controlFor(id), device, k, old);
    PlayerSettings.player1.saveControls();

    PreciseInputManager.instance.initializeKeys(pc);
  }

  function exitToMenu():Void
  {
    if (closing) return;
    closing = true;
    allowInput = false;

    camsRestored = true;
    cancelFade();

    var ps = PlayState.instance;
    if (ps != null) ps.deathCounter = 0;

    FlxTransitionableState.skipNextTransIn = true;
    FlxTransitionableState.skipNextTransOut = true;

    var targetState;
    if (PlayStatePlaylist.isStoryMode)
    {
      targetState = function(sticker) {
        return new StoryMenuState(sticker);
      };
    }
    else
    {
      targetState = function(sticker) {
        return FreeplayState.build(null, sticker);
      };
    }

    if (PlayStatePlaylist.isStoryMode) PlayStatePlaylist.reset();

    var stickerPackId = null;
    if (ps != null && ps.currentChart != null)
    {
      stickerPackId = ps.currentChart.stickerPack;

      if (stickerPackId == null)
      {
        var ownerId = PlayerRegistry.instance.getCharacterOwnerId(ps.currentChart.characters.player);
        if (ownerId == null) ownerId = Constants.DEFAULT_CHARACTER;
        var playerCharacter = PlayerRegistry.instance.fetchEntry(ownerId);
        if (playerCharacter != null) stickerPackId = playerCharacter.getStickerPackID();
      }
    }

    openSubState(new StickerSubState({targetState: targetState, stickerPack: stickerPackId}));
  }

  function changeDifficulty(difficulty:String):Void
  {
    var ps = PlayState.instance;
    if (ps == null)
    {
      exitPause(false);
      return;
    }

    ps.currentSong = SongRegistry.instance.fetchEntry(ps.currentSong.id.toLowerCase(), {variation: ps.currentChart.variation});

    if (difficulty != ps.currentDifficulty)
    {
      PlayStatePlaylist.campaignScore = 0;
      PlayStatePlaylist.campaignDifficulty = difficulty;
      ps.previousDifficulty = ps.currentDifficulty;
      ps.currentDifficulty = PlayStatePlaylist.campaignDifficulty;
      FreeplayState.rememberedDifficulty = difficulty;
    }

    exitPause(true);
  }

  function cancelButtonTweens():Void
  {
    for (b in mainButtons)
    {
      FlxTween.cancelTweensOf(b);
      FlxTween.cancelTweensOf(b.scale);
    }
    for (b in diffButtons)
    {
      FlxTween.cancelTweensOf(b);
      FlxTween.cancelTweensOf(b.scale);
    }
    for (s in stickers)
    {
      FlxTween.cancelTweensOf(s);
    }
  }

  function exitPause(restart:Bool):Void
  {
    if (closing) return;
    closing = true;

    cancelFade();

    FlxTween.cancelTweensOf(bg);
    FlxTween.cancelTweensOf(menuLeft);
    cancelButtonTweens();

    FlxTween.tween(bg, {alpha: 0}, CAM_OUT_TIME, {ease: FlxEase.quartOut});
    FlxTween.tween(menuLeft, {x: MENU_LEFT_X - menuLeft.width}, CAM_OUT_TIME, {ease: FlxEase.quartIn});
    if (menuLeftDiff != null)
    {
      FlxTween.cancelTweensOf(menuLeftDiff);
      FlxTween.tween(menuLeftDiff, {x: MENU_LEFT_X - menuLeftDiff.width}, CAM_OUT_TIME, {ease: FlxEase.quartIn});
    }
    for (i in 0...buttons.length)
    {
      FlxTween.tween(buttons[i], {x: buttonX[i] - menuLeft.width}, CAM_OUT_TIME, {ease: FlxEase.quartIn});
    }
    for (i in 0...stickers.length)
    {
      FlxTween.tween(stickers[i], {x: stickerX[i] - menuLeft.width}, CAM_OUT_TIME, {ease: FlxEase.quartIn});
    }

    if (rightTween != null) rightTween.cancel();
    if (menuRightTween != null) menuRightTween.cancel();
    rightTween = FlxTween.num(rightOffset, RIGHT_SLIDE, CAM_OUT_TIME, {ease: FlxEase.quartIn}, function(v:Float) {
      rightOffset = v;
    });

    if (gameCam != null)
    {
      FlxTween.cancelTweensOf(gameCam);
      FlxTween.cancelTweensOf(hudCam);
      FlxTween.tween(hudCam, {angle: hudAngle0, zoom: hudZoom0}, CAM_OUT_TIME, {ease: FlxEase.quartOut});
      FlxTween.tween(gameCam, {angle: gameAngle0, zoom: gameZoom0}, CAM_OUT_TIME, {ease: FlxEase.quartOut, onComplete: function(_) {
        finishExit(restart);
      }});
    }
    else
    {
      finishExit(restart);
    }
  }

  function finishExit(restart:Bool):Void
  {
    if (restart && PlayState.instance != null) PlayState.instance.needsReset = true;

    close();
  }
}
