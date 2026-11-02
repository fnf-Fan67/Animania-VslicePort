import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import funkin.Assets;
import funkin.graphics.FunkinSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxColor;
import openfl.display.BlendMode;
import funkin.PlayerSettings;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinCamera;
import funkin.input.Cursor;
import funkin.input.Cursor.CursorMode;
import funkin.ui.MusicBeatState;
import haxe.ds.StringMap;

/**
 * Freeplay AmTake (WIP), construido por capas de atrás hacia adelante.
 * Referencia: captura 1280x720. Todas las posiciones están medidas contra esa captura (escala 1.0 = tamaño original del asset).
 *
 * Assets: la carpeta del zip (animania-freeplay) va completa en  assets/images/animania-freeplay/  (AM_DIR).
 *
 *  CAPA 1 : pared del fondo (freeplay backwall) + cama (bed)
 *  CAPA 2 : brillo de la TV (tv glow, blend ADD, queda DEBAJO del panel) + panel diagonal izquierdo con glitch (TVBACK)
 *  CAPA 3 : estática de la TV (TVNOISE, 111 frames en loop) + marco de la TV encendida (freeplay tv, frame 4), la estática queda DEBAJO del marco
 *  CAPA 4 : videograbadora RiVER (player, queda DETRÁS de la base de la TV) + discos (random seleccionado, tutorial y bopeebo más chicos a la derecha) + flechas de canciones
 *
 *  CAPA 5 : personajes en la cama (atlas Animate de skinSelector, estilo según el disco) + navegación con teclado entre discos
 *
 * Navegación: IZQUIERDA / DERECHA (UI_LEFT / UI_RIGHT, mantener = repite) o tocar las flechas con el mouse/dedo.
 * BACK vuelve al menú principal nuevo (sin intro).
 */
class AmTakeFreeplayState extends MusicBeatState
{
  // ---- Assets ----
  var AM_DIR:String = 'animania-freeplay/';   // carpeta dentro de assets/images/

  // ---- Fondo de cámara ----
  // El borde de la pared tiene exactamente este color: la pared de 912x712 no cubre toda la pantalla y el resto es este mismo color liso.
  var BG_COLOR:Int = 0xFF18121C;

  // ---- CAPA 1: pared + cama ----
  var WALL_IMAGE:String = 'bg/freeplay backwall';
  var WALL_X:Float = 137;
  var WALL_Y:Float = 19;

  var BED_ATLAS:String = 'bg/bed';            // bed.png/.xml: bed0000, bed0001, bed0002 (742x474 cada uno)
  var BED_X:Float = 547;
  var BED_Y:Float = 254;

  var BED_FRAME_LIT:Int = 2;                  // con iluminación (sin personajes). Es el de la captura
  var BED_FRAME_DARK:Int = 0;                 // sin iluminación (cuando hay personajes)

  // ---- CAPA 2: brillo + panel ----
  // El brillo es verde y se suma (ADD) sobre la cama; el panel lo tapa. Medido contra la captura (centro y escala).
  var GLOW_IMAGE:String = 'bg/tv glow';
  var GLOW_CX:Float = 977;                    // centro del brillo (px de pantalla)
  var GLOW_CY:Float = 669;
  var GLOW_SCALE:Float = 1.03;

  // Panel diagonal izquierdo: TVBACK.png/.xml, 98 frames "pink0000".. de 668x721, pegado a la esquina superior izquierda.
  var PANEL_ATLAS:String = 'bg/TVBACK';
  var PANEL_X:Float = 0;
  var PANEL_Y:Float = 0;
  var PANEL_REST_FRAME:Int = 2;               // frame que coincide con la captura
  var PANEL_PLAY:Bool = true;                 // true = reproduce los 98 frames en loop (glitch continuo); false = se queda en PANEL_REST_FRAME
  var PANEL_FPS:Int = 24;

  // ---- CAPA 3: estática + TV ----
  // Medido contra la captura (1365x767 -> dividido entre 1365/1280 para pasar a coordenadas de juego 1280x720).
  //
  // Estática: TVNOISE.png/.xml, 111 frames "noise sprite0002".."noise sprite0112" de 373x301 (sin offsets). X/Y = esquina superior izquierda.
  // Se extiende un poco por detrás del marco de la TV (el marco la recorta), por eso es más grande que la pantalla visible.
  var NOISE_ATLAS:String = 'bg/TVNOISE';
  var NOISE_X:Float = 118;
  var NOISE_Y:Float = 128;
  var NOISE_FPS:Int = 24;

  // TV: freeplay tv.png/.xml, 6 frames dentro de una caja de 727x749:
  //   0-1 = TV apagada (pantalla negra) | 2-3 = TV girada de lado (transición) | 4-5 = TV de frente con la pantalla hueca (la de la captura)
  // Los frames 4-5 traen frameX=-135 / frameY=-288 en el XML: la caja de 727x749 empieza en (VISIBLE_X - 135, VISIBLE_Y - 288).
  // La esquina visible de la TV en la captura está en (76, 90)  ->  caja en (-59, -198).
  var TV_ATLAS:String = 'bg/freeplay tv';
  var TV_X:Float = -59;
  var TV_Y:Float = -198;
  var TV_FRAME_OFF:Int = 0;
  var TV_FRAME_SIDE:Int = 2;
  var TV_FRAME_ON:Int = 4;                    // el de la captura (el 5 es idéntico)

  // ---- CAPA 4: videograbadora + discos + flechas ----
  // Videograbadora: bg/player.png/.xml, 5 frames "player0000".."player0004" de 528x~125 dentro de una caja de 531x143.
  //   0-1 = reposo | 2-4 = rebote hacia abajo (para cuando cambie de disco). Por ahora queda quieta en el 0.
  // La base negra de la TV tapa el borde superior de la videograbadora, así que se inserta DEBAJO de la TV (ver buildLayer4).
  var PLAYER_ATLAS:String = 'bg/player';
  var PLAYER_X:Float = 49;
  var PLAYER_Y:Float = 511;
  var PLAYER_FRAME_REST:Int = 0;

  // Discos: disks/<nombre>.png (imagen suelta, sin atlas). X/Y = esquina superior izquierda YA ESCALADO.
  // El disco seleccionado va a escala 1; los de los lados se achican (en la captura: ~0.74 el siguiente, ~0.58 el que sigue).
  // Orden de dibujo, de atrás hacia adelante: bopeebo -> tutorial -> random.
  var DISK_DIR:String = 'disks/';
  var DISK_SEL_X:Float = 142.5;
  var DISK_SEL_Y:Float = 574;
  var DISK_SEL_SCALE:Float = 1.0;

  var DISK_NEXT_X:Float = 412.5;
  var DISK_NEXT_Y:Float = 606;
  var DISK_NEXT_SCALE:Float = 0.74;

  var DISK_NEXT2_X:Float = 653.5;
  var DISK_NEXT2_Y:Float = 671.5;
  var DISK_NEXT2_SCALE:Float = 0.58;

  // ---- Carrusel de discos ----
  // Orden de izquierda a derecha (el de las capturas). name = disks/<name>.png | style = estilo de personajes ('' = sin personajes):
  //   'animania' = skinSelector/*/*-animania | 'standart' = el de week 1 (captura de bopeebo) | 'xmas' = el de navidad (captura de cocoa)
  // dim = true oscurece toda la pantalla (captura de winter horrorland). Si el PNG de un disco no existe se omite (sale en el trace).
  var DISK_LIST:Array<Dynamic> = [
    {name: 'random',            style: ''},
    {name: 'tutorial',          style: 'animania'},
    {name: 'bopeebo',           style: 'standart'},
    {name: 'fresh',             style: 'standart'},
    {name: 'dadbattle',         style: 'standart'},
    {name: 'cocoa',             style: 'xmas'},
    {name: 'eggnog',            style: 'xmas'},
    {name: 'winter horrorland', style: 'xmas', dim: true},
    {name: 'phone call',        style: ''}
  ];
  var DISK_DEFAULT_SIZE:Float = 320;          // si no se puede leer el tamaño de un disco de referencia
  var DISK_TWEEN_TIME:Float = 0.22;
  var DIM_ALPHA:Float = 0.55;                 // oscuridad de los discos con dim:true

  // Mantener pulsado: espera HOLD_DELAY y luego repite cada HOLD_REPEAT segundos.
  var HOLD_DELAY:Float = 0.35;
  var HOLD_REPEAT:Float = 0.12;

  // ---- Personajes en la cama ----
  // Atlas Animate (carpeta con Animation.json + spritemap1) en skinSelector/. Etiquetas: BF 'idle' | GF 'idle' y 'idle blink' (30 frames).
  // Se cargan con applyStageMatrix: x/y = origen del stage de Animate. blink = true: parpadea cada BLINK_MIN..BLINK_MAX segundos.
  // ⚠ x/y medidos a ojo de las capturas: afínalos con CHAR_DEBUG (abajo).
  var CHAR_LIST:Array<Dynamic> = [
    {style: 'animania', role: 'bf', atlas: 'skinSelector/bf/bf-animania', x: 647, y: 262},
    {style: 'animania', role: 'gf', atlas: 'skinSelector/gf/gf-animania', x: 975, y: 234, blink: true},
    {style: 'standart', role: 'bf', atlas: 'skinSelector/bf/bf-standart', x: 647, y: 262},
    {style: 'standart', role: 'gf', atlas: 'skinSelector/gf/gf-standart', x: 975, y: 234, blink: true},
    {style: 'xmas',     role: 'bf', atlas: 'skinSelector/bf/bf-xmas',     x: 640, y: 262},
    {style: 'xmas',     role: 'gf', atlas: 'skinSelector/gf/gf-xmas',     x: 975, y: 205, blink: true}
  ];

  // Transición al cambiar de estilo: primero aparece la silueta de estática de cada personaje (13 frames: estática -> flash blanco ->
  // se deshace en trozos) y los personajes reales aparecen en el flash. BF = youKnowWhoIsThisRight, GF = againAndAgain (Sparrow, en skinSelector/).
  // DX/DY = posición de la caja del atlas relativa al personaje (x/y del CHAR_LIST), así sigue a CHAR_DEBUG. ⚠ Estimados: afinar.
  var TRANS_BF_ATLAS:String = 'skinSelector/bf/youKnowWhoIsThisRight';
  var TRANS_BF_PREFIX:String = 'skin switch';
  var TRANS_BF_DX:Float = -208;
  var TRANS_BF_DY:Float = -41;
  var TRANS_GF_ATLAS:String = 'skinSelector/gf/againAndAgain';
  var TRANS_GF_PREFIX:String = 'gf skin switch';
  var TRANS_GF_DX:Float = -206;
  var TRANS_GF_DY:Float = -9;
  var TRANS_FPS:Int = 24;
  var TRANS_FRAMES:Int = 13;
  var TRANS_REVEAL_FRAME:Int = 6;             // frame del flash blanco: ahí aparecen los personajes
  var CHAR_FPS:Int = 24;
  var CHAR_FADE_TIME:Float = 0.2;
  var BLINK_MIN:Float = 2;
  var BLINK_MAX:Float = 5;
  var BLINK_LENGTH:Float = 1.25;              // 30 frames a 24 fps

  // Ajuste de posiciones: true = con el estilo actual, 1 / 2 elige personaje (orden de CHAR_LIST), I J K L lo mueven 1 px (SHIFT = 10)
  // y el trace imprime x/y para copiarlos a CHAR_LIST. Dejar en false al terminar.
  var CHAR_DEBUG:Bool = false;
  var charDebugIdx:Int = 0;

  // Flechas de canciones: FREEPLAY_ASSETS.png/.xml (en la raíz de animania-freeplay). Se eligen por índice de frame
  // (los nombres del segundo par llevan una palabra en cirílico): 8 = "songs arrow" (izquierda), 12 = segunda variante (derecha).
  // 8-9 / 12-13 = normales | 10-11 / 14-15 = presionadas. Sus XML traen frameX=-2 (izq) y -3 (der): X de abajo es el de la caja.
  var ARROW_ATLAS:String = 'FREEPLAY_ASSETS';
  var ARROW_L_FRAME:Int = 8;
  var ARROW_L_FRAME_PRESSED:Int = 10;
  var ARROW_R_FRAME:Int = 12;
  var ARROW_R_FRAME_PRESSED:Int = 14;
  var ARROW_L_X:Float = 75.8;
  var ARROW_R_X:Float = 476.2;
  var ARROW_Y:Float = 604.8;

  var wall:FlxSprite;
  var bed:FlxSprite;
  var glow:FlxSprite;
  var panel:FlxSprite;
  var noise:FlxSprite;
  var tv:FlxSprite;
  var player:FlxSprite;
  var diskGroup:FlxGroup;
  var disks:Array<Dynamic> = [];              // entradas de DISK_LIST cuyo PNG existe
  var diskSprites:Array<FlxSprite> = [];
  var diskOffs:Array<Int> = [];               // offset actual de cada disco respecto al seleccionado
  var curDisk:Int = 0;

  // Slots por offset -2..+2 (índice = offset + 2): centro, escala
  var slotCX:Array<Float> = [0, 0, 0, 0, 0];
  var slotCY:Array<Float> = [0, 0, 0, 0, 0];
  var slotS:Array<Float> = [0, 0, 0, 0, 0];

  var charSprites:StringMap<Array<FlxSprite>> = new StringMap();
  var charByKey:StringMap<FlxSprite> = new StringMap();   // 'estilo:rol' -> sprite
  var transBf:FlxSprite;
  var transGf:FlxSprite;
  var transActive:Bool = false;
  var transTime:Float = 0;
  var transRevealed:Bool = false;
  var transStyle:String = '';
  var blinkSprites:Array<FlxSprite> = [];
  var blinkStyles:Array<String> = [];
  var blinkTimes:Array<Float> = [];
  var blinkOn:Array<Bool> = [];
  var curStyle:String = 'none';
  var dimOverlay:FlxSprite;

  var holdTime:Float = 0;
  var holdRepeat:Float = 0;
  var arrowL:FlxSprite;
  var arrowR:FlxSprite;

  var leaving:Bool = false;

  function new()
  {
    super();
  }

  override function create():Void
  {
    FlxG.cameras.reset(new FunkinCamera('amTakeFreeplay'));
    FlxG.camera.bgColor = BG_COLOR;

    // Misma música que el menú, sin reiniciarla si ya suena.
    FunkinSound.playMusic('freakyMenu', {
      overrideExisting: true,
      restartTrack: false,
      persist: true
    });

    this.persistentUpdate = true;
    this.persistentDraw = true;

    if (!FlxG.onMobile) Cursor.show();

    buildLayer1();
    buildLayer2();
    buildCharacters();   // después de la capa 2: se inserta justo antes del brillo
    buildLayer3();
    buildLayer4();
    buildDim();          // siempre lo último: oscurece todo lo que haya debajo

    refreshDisks(false);
    refreshStyle(false);

    super.create();
  }

  // ---------------------------------------------------------------------------
  // CAPA 1 — pared + cama
  // ---------------------------------------------------------------------------

  function buildLayer1():Void
  {
    // Objeto 1: pared oscura con las formas azules.
    wall = new FlxSprite(WALL_X, WALL_Y).loadGraphic(Paths.image(AM_DIR + WALL_IMAGE));
    wall.antialiasing = true;
    add(wall);

    // Objeto 2: cama, a la derecha. Es un atlas Sparrow de 3 frames; por ahora se deja quieto en el de reposo.
    bed = new FlxSprite(BED_X, BED_Y);
    bed.frames = Paths.getSparrowAtlas(AM_DIR + BED_ATLAS);
    bed.animation.addByIndices('lit', 'bed', [BED_FRAME_LIT], '', 24, false);
    bed.animation.addByIndices('dark', 'bed', [BED_FRAME_DARK], '', 24, false);
    bed.antialiasing = true;
    add(bed);
    setBedLit(true);
  }

  /** true = frame con iluminación (no hay personajes); false = sin iluminación (cuando se muestren los personajes). */
  function setBedLit(lit:Bool):Void
  {
    bed.animation.play(lit ? 'lit' : 'dark', true);
  }

  // ---------------------------------------------------------------------------
  // CAPA 2 — brillo de la TV + panel diagonal con glitch
  // ---------------------------------------------------------------------------

  function buildLayer2():Void
  {
    // Objeto 3: brillo verde, sumado a lo que hay debajo. Va ANTES del panel: el panel lo tapa en su zona.
    glow = new FlxSprite().loadGraphic(Paths.image(AM_DIR + GLOW_IMAGE));
    glow.blend = BlendMode.ADD;
    glow.antialiasing = true;
    glow.x = GLOW_CX - glow.frameWidth / 2;
    glow.y = GLOW_CY - glow.frameHeight / 2;
    glow.scale.set(GLOW_SCALE, GLOW_SCALE);
    add(glow);

    // Objeto 4: panel diagonal con las líneas glitch.
    panel = new FlxSprite(PANEL_X, PANEL_Y);
    panel.frames = Paths.getSparrowAtlas(AM_DIR + PANEL_ATLAS);
    panel.animation.addByPrefix('glitch', 'pink', PANEL_FPS, true);                                   // los 98 frames, en loop
    panel.animation.addByIndices('rest', 'pink', [PANEL_REST_FRAME], '', PANEL_FPS, false);           // un solo frame (antes 'rest' no existía)
    panel.animation.play(PANEL_PLAY ? 'glitch' : 'rest', true);
    panel.antialiasing = true;
    add(panel);
  }

  // ---------------------------------------------------------------------------
  // CAPA 3 — estática (TVNOISE) + TV (freeplay tv)
  // ---------------------------------------------------------------------------

  function buildLayer3():Void
  {
    // Objeto 5: estática. Va ANTES de la TV: el marco de la TV tapa los bordes de la estática.
    noise = new FlxSprite(NOISE_X, NOISE_Y);
    noise.frames = Paths.getSparrowAtlas(AM_DIR + NOISE_ATLAS);
    noise.animation.addByPrefix('static', 'noise sprite', NOISE_FPS, true);
    noise.animation.play('static', true);
    noise.antialiasing = true;
    add(noise);

    // Objeto 6: TV encendida (marco con la pantalla hueca). Es un atlas de 6 frames; se elige por índice porque los nombres
    // del XML llevan una palabra en cirílico ("freeplay tv образец 1000N") y así no hay que escribirla en el script.
    tv = new FlxSprite(TV_X, TV_Y);
    tv.frames = Paths.getSparrowAtlas(AM_DIR + TV_ATLAS);
    tv.animation.frameIndex = TV_FRAME_ON;
    tv.antialiasing = true;
    add(tv);
  }

  // ---------------------------------------------------------------------------
  // CAPA 4 — videograbadora + discos + flechas
  // ---------------------------------------------------------------------------

  function buildLayer4():Void
  {
    // Objeto 7: videograbadora RiVER. La base de la TV la tapa por arriba, por eso se mete justo ANTES de la TV en la lista de dibujo.
    player = new FlxSprite(PLAYER_X, PLAYER_Y);
    player.frames = Paths.getSparrowAtlas(AM_DIR + PLAYER_ATLAS);
    player.animation.addByIndices('rest', 'player', [PLAYER_FRAME_REST], '', 24, false);
    player.animation.play('rest', true);
    player.antialiasing = true;
    insert(members.indexOf(tv), player);

    // Objetos 8-10: discos. Son todos los de DISK_LIST; los slots (sel / lados) se calculan con los tamaños reales de los de referencia.
    diskGroup = new FlxGroup();
    add(diskGroup);
    buildDisks();

    // Objetos 11-12: flechas a los lados del disco seleccionado (van por encima de los discos).
    arrowL = makeArrow(ARROW_L_FRAME, ARROW_L_X, ARROW_Y);
    add(arrowL);
    arrowR = makeArrow(ARROW_R_FRAME, ARROW_R_X, ARROW_Y);
    add(arrowR);
  }

  /** Disco suelto. Sin updateHitbox: x/y es la esquina del frame SIN escalar; la escala se aplica desde el centro. */
  function makeDisk(name:String):FlxSprite
  {
    var d = new FlxSprite().loadGraphic(Paths.image(AM_DIR + DISK_DIR + name));
    d.antialiasing = true;
    return d;
  }

  function makeArrow(frameIdx:Int, x:Float, y:Float):FlxSprite
  {
    var a = new FlxSprite(x, y);
    a.frames = Paths.getSparrowAtlas(AM_DIR + ARROW_ATLAS);
    a.animation.frameIndex = frameIdx;
    a.antialiasing = true;
    return a;
  }

  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // CAPA 5 — personajes
  // ---------------------------------------------------------------------------

  function buildCharacters():Void
  {
    var i = 0;
    while (i < CHAR_LIST.length)
    {
      var def = CHAR_LIST[i];
      i = i + 1;

      var spr = makeCharacter(def);
      if (spr == null) continue;

      spr.alpha = 0;
      // Entre la cama y el brillo: el brillo (ADD) aclara la parte de abajo de los personajes, como en las capturas.
      insert(members.indexOf(glow), spr);

      if (!charSprites.exists(def.style)) charSprites.set(def.style, []);
      var arr = charSprites.get(def.style);
      arr[arr.length] = spr;
      charByKey.set(def.style + ':' + def.role, spr);

      if (def.blink == true)
      {
        var k = blinkSprites.length;
        blinkSprites[k] = spr;
        blinkStyles[k] = def.style;
        blinkTimes[k] = FlxG.random.float(BLINK_MIN, BLINK_MAX);
        blinkOn[k] = false;
      }
    }

    buildTransitions();
  }

  /** Siluetas de la transición. Van justo antes del brillo, encima de los personajes. */
  function buildTransitions():Void
  {
    transBf = makeTransition(TRANS_BF_ATLAS, TRANS_BF_PREFIX);
    transGf = makeTransition(TRANS_GF_ATLAS, TRANS_GF_PREFIX);
  }

  function makeTransition(atlas:String, prefix:String):FlxSprite
  {
    var spr = new FlxSprite();
    try
    {
      spr.frames = Paths.getSparrowAtlas(AM_DIR + atlas);
    }
    catch (e:Dynamic)
    {
      trace('[AmTakeFreeplay] transición omitida (' + atlas + '): ' + e);
      return null;
    }
    spr.animation.addByPrefix('go', prefix, TRANS_FPS, false);
    spr.antialiasing = true;
    spr.visible = false;
    insert(members.indexOf(glow), spr);
    return spr;
  }

  /** Muestra la silueta sobre el personaje del estilo st (rol bf/gf) y la reproduce. */
  function playTransition(spr:FlxSprite, st:String, role:String, dx:Float, dy:Float):Void
  {
    if (spr == null) return;
    var target = charByKey.get(st + ':' + role);
    if (target == null) return;
    spr.x = target.x + dx;
    spr.y = target.y + dy;
    spr.visible = true;
    spr.animation.play('go', true);
  }

  function startTransition(st:String):Void
  {
    playTransition(transBf, st, 'bf', TRANS_BF_DX, TRANS_BF_DY);
    playTransition(transGf, st, 'gf', TRANS_GF_DX, TRANS_GF_DY);
    transStyle = st;
    transTime = 0;
    transRevealed = false;
    transActive = true;
  }

  function stopTransition():Void
  {
    transActive = false;
    if (transBf != null) transBf.visible = false;
    if (transGf != null) transGf.visible = false;
  }

  function updateTransition(elapsed:Float):Void
  {
    if (!transActive) return;
    transTime = transTime + elapsed;

    // En el flash blanco los personajes reales aparecen de golpe (quedan tapados por el flash).
    if (!transRevealed && transTime >= TRANS_REVEAL_FRAME / TRANS_FPS)
    {
      transRevealed = true;
      fadeStyle(transStyle, 1, 0);
    }
    if (transTime >= TRANS_FRAMES / TRANS_FPS) stopTransition();
  }

  function makeCharacter(def:Dynamic):FlxSprite
  {
    var spr = new FunkinSprite(def.x, def.y);
    try
    {
      spr.loadTextureAtlas(AM_DIR + def.atlas, null, {swfMode: true, applyStageMatrix: true});
    }
    catch (e:Dynamic)
    {
      trace('[AmTakeFreeplay] personaje omitido (' + def.atlas + '): ' + e);
      return null;
    }

    spr.anim.addByFrameLabel('idle', 'idle', CHAR_FPS, true);
    if (def.blink == true) spr.anim.addByFrameLabel('blink', 'idle blink', CHAR_FPS, false);
    spr.anim.play('idle', true);
    spr.antialiasing = true;
    return spr;
  }

  /** GF: parpadea de vez en cuando (solo mientras su estilo está visible). */
  function updateBlink(elapsed:Float):Void
  {
    var i = 0;
    while (i < blinkSprites.length)
    {
      if (blinkStyles[i] == curStyle)
      {
        blinkTimes[i] = blinkTimes[i] - elapsed;
        if (blinkTimes[i] <= 0)
        {
          blinkOn[i] = !blinkOn[i];
          blinkSprites[i].anim.play(blinkOn[i] ? 'blink' : 'idle', true);
          blinkTimes[i] = blinkOn[i] ? BLINK_LENGTH : FlxG.random.float(BLINK_MIN, BLINK_MAX);
        }
      }
      i = i + 1;
    }
  }

  function debugNudge():Void
  {
    if (!charSprites.exists(curStyle)) return;
    var arr = charSprites.get(curStyle);

    if (FlxG.keys.justPressed.ONE) charDebugIdx = 0;
    if (FlxG.keys.justPressed.TWO) charDebugIdx = 1;
    if (charDebugIdx >= arr.length) return;

    var step = FlxG.keys.pressed.SHIFT ? 10 : 1;
    var dx = 0;
    var dy = 0;
    if (FlxG.keys.justPressed.J) dx = -step;
    if (FlxG.keys.justPressed.L) dx = step;
    if (FlxG.keys.justPressed.I) dy = -step;
    if (FlxG.keys.justPressed.K) dy = step;
    if (dx == 0 && dy == 0) return;

    var spr = arr[charDebugIdx];
    spr.x = spr.x + dx;
    spr.y = spr.y + dy;
    trace('[AmTakeFreeplay] ' + curStyle + ' #' + charDebugIdx + ' -> x: ' + spr.x + ', y: ' + spr.y);
  }

  function buildDim():Void
  {
    dimOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
    dimOverlay.alpha = 0;
    add(dimOverlay);
  }

  /** Muestra el estilo del disco seleccionado: fade entre estilos, cama iluminada si no hay personajes y oscurecido si dim. */
  function refreshStyle(animate:Bool):Void
  {
    if (disks.length == 0) return;

    var info = disks[curDisk];
    var st = info.style;
    var t = animate ? CHAR_FADE_TIME : 0;

    if (st != curStyle)
    {
      stopTransition();
      fadeStyle(curStyle, 0, t);

      if (charSprites.exists(st))
      {
        if (animate) startTransition(st);   // los personajes aparecen en el flash de la transición
        else fadeStyle(st, 1, 0);
      }

      setBedLit(st == '' || !charSprites.exists(st));
      curStyle = st;
    }

    var dimTarget = (info.dim == true) ? DIM_ALPHA : 0;
    FlxTween.cancelTweensOf(dimOverlay);
    if (animate) FlxTween.tween(dimOverlay, {alpha: dimTarget}, 0.3, {ease: FlxEase.quadOut});
    else dimOverlay.alpha = dimTarget;
  }

  function fadeStyle(style:String, target:Float, time:Float):Void
  {
    if (!charSprites.exists(style)) return;

    var arr = charSprites.get(style);
    var i = 0;
    while (i < arr.length)
    {
      var spr = arr[i];
      i = i + 1;
      FlxTween.cancelTweensOf(spr);
      if (time > 0) FlxTween.tween(spr, {alpha: target}, time);
      else spr.alpha = target;
    }
  }

  // ---------------------------------------------------------------------------
  // Carrusel de discos
  // ---------------------------------------------------------------------------

  function buildDisks():Void
  {
    var i = 0;
    while (i < DISK_LIST.length)
    {
      var info = DISK_LIST[i];
      i = i + 1;

      if (!Assets.exists(Paths.image(AM_DIR + DISK_DIR + info.name)))
      {
        trace('[AmTakeFreeplay] disco omitido, no existe: ' + info.name);
        continue;
      }

      var d = makeDisk(info.name);
      d.alpha = 0;
      diskGroup.add(d);
      disks[disks.length] = info;
      diskSprites[diskSprites.length] = d;
      diskOffs[diskOffs.length] = 99;   // 99 = todavía sin colocar
    }

    // Slots a partir de las posiciones medidas (esquina superior izquierda ya escalada) y el tamaño real del disco de referencia.
    var wSel = diskRefSize('random', true);
    var hSel = diskRefSize('random', false);
    var wNext = diskRefSize('tutorial', true);
    var hNext = diskRefSize('tutorial', false);
    var wNext2 = diskRefSize('bopeebo', true);
    var hNext2 = diskRefSize('bopeebo', false);

    slotS[2] = DISK_SEL_SCALE;
    slotCX[2] = DISK_SEL_X + wSel * DISK_SEL_SCALE / 2;
    slotCY[2] = DISK_SEL_Y + hSel * DISK_SEL_SCALE / 2;

    slotS[3] = DISK_NEXT_SCALE;
    slotCX[3] = DISK_NEXT_X + wNext * DISK_NEXT_SCALE / 2;
    slotCY[3] = DISK_NEXT_Y + hNext * DISK_NEXT_SCALE / 2;

    slotS[4] = DISK_NEXT2_SCALE;
    slotCX[4] = DISK_NEXT2_X + wNext2 * DISK_NEXT2_SCALE / 2;
    slotCY[4] = DISK_NEXT2_Y + hNext2 * DISK_NEXT2_SCALE / 2;

    // Lado izquierdo: espejo del derecho respecto al seleccionado (en las capturas el anterior asoma cortado por el borde).
    slotS[1] = slotS[3];
    slotCX[1] = slotCX[2] - (slotCX[3] - slotCX[2]);
    slotCY[1] = slotCY[3];

    slotS[0] = slotS[4];
    slotCX[0] = slotCX[1] - (slotCX[4] - slotCX[3]);
    slotCY[0] = slotCY[4];
  }

  /** Ancho/alto del PNG de un disco de referencia; DISK_DEFAULT_SIZE si ese disco no está en la lista. */
  function diskRefSize(name:String, width:Bool):Float
  {
    var i = 0;
    while (i < disks.length)
    {
      if (disks[i].name == name) return width ? diskSprites[i].frameWidth : diskSprites[i].frameHeight;
      i = i + 1;
    }
    return DISK_DEFAULT_SIZE;
  }

  /** Offset de un disco respecto al seleccionado (la lista no da la vuelta: random es el primero y phone call el último). */
  function diskOffset(i:Int):Int
  {
    return i - curDisk;
  }

  function refreshDisks(animate:Bool):Void
  {
    var n = diskSprites.length;
    var i = 0;
    while (i < n)
    {
      placeDisk(i, diskOffset(i), animate);
      i = i + 1;
    }
    reorderDisks();
  }

  function placeDisk(i:Int, off:Int, animate:Bool):Void
  {
    var d = diskSprites[i];
    var oldOff = diskOffs[i];
    diskOffs[i] = off;

    var slot = off;
    if (slot < -2) slot = -2;
    if (slot > 2) slot = 2;

    var tx = slotCX[slot + 2] - d.frameWidth / 2;
    var ty = slotCY[slot + 2] - d.frameHeight / 2;
    var ts = slotS[slot + 2];
    var ta = (off == slot) ? 1 : 0;

    FlxTween.cancelTweensOf(d);
    FlxTween.cancelTweensOf(d.scale);

    // Sin animación si es la primera vez, o si el disco se queda fuera de pantalla (no hace falta animarlo).
    var wasHidden = (oldOff == 99) || oldOff < -2 || oldOff > 2;
    if (!animate || (wasHidden && ta == 0))
    {
      d.x = tx;
      d.y = ty;
      d.scale.set(ts, ts);
      d.alpha = ta;
      return;
    }

    FlxTween.tween(d, {x: tx, y: ty, alpha: ta}, DISK_TWEEN_TIME, {ease: FlxEase.quadOut});
    FlxTween.tween(d.scale, {x: ts, y: ts}, DISK_TWEEN_TIME, {ease: FlxEase.quadOut});
  }

  /** Dibuja de atrás hacia adelante: primero los más lejanos, el seleccionado queda encima. */
  function reorderDisks():Void
  {
    var n = diskSprites.length;
    var dist = n;
    while (dist >= 0)
    {
      var i = 0;
      while (i < n)
      {
        if (Std.int(Math.abs(diskOffs[i])) == dist)
        {
          diskGroup.remove(diskSprites[i], true);
          diskGroup.add(diskSprites[i]);
        }
        i = i + 1;
      }
      dist = dist - 1;
    }
  }

  function changeDisk(dir:Int):Void
  {
    var n = diskSprites.length;
    var next = curDisk + dir;
    if (next < 0 || next >= n) return;   // tope en los extremos, no hay loop

    curDisk = next;

    FunkinSound.playOnce(Paths.sound('scrollMenu'));
    refreshDisks(true);
    refreshStyle(true);
  }

  // ---------------------------------------------------------------------------

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (leaving) return;

    var ctrl = PlayerSettings.player1.controls;

    if (ctrl.BACK_P)
    {
      goBack();
      return;
    }

    var left = ctrl.UI_LEFT;
    var right = ctrl.UI_RIGHT;
    var dir = 0;

    if (ctrl.UI_LEFT_P) dir = -1;
    else if (ctrl.UI_RIGHT_P) dir = 1;

    // Tocar / clicar las flechas
    if (FlxG.mouse.justPressed)
    {
      if (FlxG.mouse.overlaps(arrowL)) { dir = -1; left = true; }
      else if (FlxG.mouse.overlaps(arrowR)) { dir = 1; right = true; }
    }

    // Mantener pulsado: repite tras HOLD_DELAY
    if (left != right)
    {
      holdTime = holdTime + elapsed;
      if (holdTime >= HOLD_DELAY)
      {
        holdRepeat = holdRepeat + elapsed;
        if (holdRepeat >= HOLD_REPEAT)
        {
          holdRepeat = holdRepeat - HOLD_REPEAT;
          dir = left ? -1 : 1;
        }
      }
    }
    else
    {
      holdTime = 0;
      holdRepeat = 0;
    }

    if (dir != 0) changeDisk(dir);

    updateTransition(elapsed);
    updateBlink(elapsed);
    if (CHAR_DEBUG) debugNudge();

    // Flechas presionadas mientras se mantiene la tecla
    var fl = (left && !right) ? ARROW_L_FRAME_PRESSED : ARROW_L_FRAME;
    var fr = (right && !left) ? ARROW_R_FRAME_PRESSED : ARROW_R_FRAME;
    if (arrowL.animation.frameIndex != fl) arrowL.animation.frameIndex = fl;
    if (arrowR.animation.frameIndex != fr) arrowR.animation.frameIndex = fr;
  }

  function goBack():Void
  {
    if (leaving) return;
    leaving = true;

    FunkinSound.playOnce(Paths.sound('cancelMenu'));
    Cursor.cursorMode = CursorMode.Default;

    // NewMainMenuState lee esta bandera como "no hacer intro" (igual que cuando vuelve de Options/Credits).
    FlxTransitionableState.skipNextTransIn = true;
    FlxG.switchState(new NewMainMenuState());
  }
}
