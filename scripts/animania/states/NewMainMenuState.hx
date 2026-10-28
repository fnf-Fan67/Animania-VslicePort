import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import funkin.FunkinMemory;
import funkin.Conductor;
import funkin.PlayerSettings;
import funkin.input.Controls;
import funkin.audio.FunkinSound;
import funkin.ui.UIStateMachine;
import funkin.ui.UIStateMachine.UIState;
import funkin.audio.waveform.WaveformSprite;
import funkin.audio.waveform.WaveformSprite.WaveformOrientation;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.input.Cursor;
import funkin.input.Cursor.CursorMode;
import funkin.ui.MusicBeatState;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.credits.CreditsState;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.options.OptionsState;
import funkin.ui.title.TitleState;
import funkin.ui.story.StoryMenuState;
import funkin.ui.debug.DebugMenuSubState;
import funkin.ui.FullScreenScaleMode;
import funkin.util.TouchUtil;
import funkin.modding.module.ModuleHandler;
import openfl.filters.BlurFilter;

/**
 * Nuevo menú principal (WIP).
 *
 * Capas (de atrás hacia adelante):
 *  1. Fondo cian
 *  2. Waveform semitransparente (sincronizado con la música)
 *  3. Nieve cayendo desde la esquina derecha (por rondas, con tope de partículas)
 *  4. Personajes (BF + GF) bailando en loop (por encima de la nieve)
 *  5. Fondo del panel de botones
 *  6. Botones del menú (atlas de Animate, controlados con el mouse)
 *  7. Hojas cayendo en vertical por toda la pantalla, por encima de todo
 *     (el emisor de hojas se crea SIEMPRE al final de create(), para que quede encima de las capas nuevas)
 *  Touch (SOLO móviles, FlxG.onMobile): tocar un botón = select mientras el dedo está encima; soltar sobre él = confirm.
 *     Los botones bloqueados tiemblan al tocarlos. Se añade un BackButton (vuelve al título). En PC no cambia nada (mouse).
 *  8. Intro: 2 barras negras inclinadas con el mismo ángulo que la cámara (INTRO_ANGLE, encima de todo) que cubren
 *     la pantalla; luego se abren hasta dejar una franja en cada borde y cámara + barras vuelven a 0°.
 *     La cámara empieza con zoom INTRO_ZOOM y va volviendo a 1.0 mientras dura la apertura.
 *  10. Selección de modo (al pulsar Story): dos bloques (AM Take = StoryMenuState vanilla, Animania = StoryMenuCustom)
 *     sobre una cámara propia (selectCam, entre el menú y las barras), con el menú de fondo oscurecido y con blur.
 *     BACK (o el BackButton en móvil) la cierra y devuelve al menú; al elegir un bloque se hace el outro y se cambia de state.
 *  9. Outro: lo inverso. Las barras se cierran, la cámara gira a OUTRO_ANGLE (positivo) y se acerca a OUTRO_ZOOM.
 *     Se usa en todos los botones (menos Freeplay) y al volver al título (BACK / Exit).
 */
class NewMainMenuState extends MusicBeatState
{
  var bg:FlxSprite;
  var buttonsBG:FlxSprite;

  // ---- Ajustes del waveform (onda vertical semitransparente) ----
  var WAVE_X:Float = 24;           // posición X de la onda
  var WAVE_WIDTH:Float = 110;      // ancho (amplitud máxima de la onda)
  var WAVE_DURATION:Float = 4.0;   // segundos de audio visibles en pantalla
  var WAVE_COLOR:Int = 0x70FFFFFF; // ARGB: blanco con ~44% de opacidad
  var WAVE_AMPLITUDE:Float = 1.6;

  // ---- Ajustes de la nieve ----
  var SNOW_CFG:Dynamic = {
    atlas: 'newmenu/snow',
    maxActive: 20,       // tope de copos en pantalla
    startDelay: 0.1,     // segundos hasta la primera ronda
    batchMin: 10,         // copos por grupo
    batchMax: 10,
    intervalMin: 1.0,    // segundos entre grupos
    intervalMax: 2.0,
    staggerMin: 0.1,    // ~0.3 s entre un copo y el siguiente dentro del grupo
    staggerMax: 0.1,
    vxMin: -430, vxMax: -430,  // velocidad horizontal (negativa = hacia la izquierda)
    vyMin: 300, vyMax: 300,    // velocidad de caída
    scaleMin: 1.0, scaleMax: 2.2,
    alphaMin: 0.7, alphaMax: 1.0,
    sway: 25,            // vaivén lateral
    spin: 40,            // giro máximo (grados/seg)
    vertical: false      // false = diagonal desde la esquina derecha
  };

  // ---- Ajustes de las hojas ----
  // Caen una por una, en vertical, desde cualquier punto del borde superior, por encima de todo.
  var LEAF_CFG:Dynamic = {
    atlas: 'newmenu/leafs',
    maxActive: 5,        // tope de hojas en pantalla
    startDelay: 0.0,    // empiezan a caer a los 10 segundos
    batchMin: 3,         // hojas por grupo (5 como máximo)
    batchMax: 5,
    intervalMin: 1.0,   // segundos entre grupos
    intervalMax: 1.0,
    staggerMin: 0.45,    // ~0.5 s entre una hoja y la siguiente: caen seguidas, no todas juntas
    staggerMax: 0.55,
    vxMin: -12, vxMax: 12,    // casi sin deriva lateral: cae recto
    vyMin: 80, vyMax: 140,
    scaleMin: 0.5, scaleMax: 0.9,
    alphaMin: 0.9, alphaMax: 1.0,
    sway: 30,            // vaivén lateral suave
    spin: 70,
    vertical: true       // true = nace en cualquier X del borde superior y cae recto
  };

  // ---- Ajustes de los personajes (BF + GF, Caramel.xml) ----
  var CHAR_SCALE:Float = 1.0;        // escala del sprite (el frame original mide 687x510)
  var CHAR_X:Float = 0;              // posición X (esquina inferior izquierda)
  var CHAR_BOTTOM_MARGIN:Float = 0;  // separación respecto al borde inferior
  var CHAR_FPS:Int = 24;             // velocidad del loop

  // ---- Ajustes del bop de cámara ----
  var BOP_ZOOM:Float = 0.03;  // cuánto "salta" el zoom en cada beat
  var BOP_DECAY:Float = 6.0;  // qué tan rápido vuelve a 1.0 (más alto = más rápido)

  // ---- Parallax del mouse (scroll sutil) ----
  // Cada capa se mueve según su factor: 0 = quieta, 1 = lo máximo. Más cerca de la cámara = más movimiento.
  var PARALLAX_MAX_X:Float = 25;     // desplazamiento máximo de la cámara en X (px)
  var PARALLAX_MAX_Y:Float = 0;      // desplazamiento máximo de la cámara en Y (px)
  var PARALLAX_SMOOTH:Float = 5.0;   // suavizado (más alto = sigue al mouse más rápido)
  var PARALLAX_BG:Float = 0.15;
  var PARALLAX_WAVE:Float = 0.3;
  var PARALLAX_SNOW:Float = 0.5;
  var PARALLAX_CHARS:Float = 0.0;
  var PARALLAX_PANEL:Float = 0.6;
  var PARALLAX_LEAVES:Float = 1.0;

  // ---- Parallax en móvil ----
  // En móvil no hay mouse: el parallax sigue al dedo mientras toca la pantalla y, si no hay toque,
  // la cámara hace un vaivén lento por sí sola (así se nota siempre). Mientras el dedo está sobre un botón se congela.
  var PARALLAX_MOBILE_X:Float = 48;        // desplazamiento máximo en X (px). En PC se usa PARALLAX_MAX_X
  var PARALLAX_MOBILE_Y:Float = 10;        // desplazamiento máximo en Y (px). En PC se usa PARALLAX_MAX_Y
  var PARALLAX_IDLE_SWAY:Bool = true;      // vaivén automático cuando no hay dedo en pantalla
  var PARALLAX_IDLE_SPEED:Float = 0.6;     // velocidad del vaivén (rad/seg)
  var PARALLAX_IDLE_AMOUNT:Float = 0.8;    // 0..1: qué parte del máximo recorre el vaivén

  // ---- Pantalla ancha (FullScreenScaleMode) ----
  // En pantallas más anchas que 16:9 (móvil) FlxG.width crece (hasta 20:9) y FlxG.height se queda igual.
  // El layout de los botones está medido a 1280 px: se desplazan junto con el panel (anclado a la derecha).
  // El fondo se escala desde la esquina inferior izquierda; los personajes mantienen su tamaño y se mueven un poco a la derecha (CHAR_WIDE_SHIFT).
  var CHAR_WIDE_SHIFT:Float = 0.5;        // fracción del ancho extra que los personajes se mueven a la derecha (0 = pegados a la izquierda, 1 = como los botones)
  var wideShiftX:Float = 0;                // px extra a la derecha que se suman a todos los botones
  var sceneK:Float = 1.0;                  // factor de escala de la escena (1 = 16:9)
  var parMaxX:Float = 16;                  // valores de parallax activos (PC o móvil)
  var parMaxY:Float = 0;
  var parTime:Float = 0;

  // ---- Botones del menú (atlas de Animate: Animation.json + spritemap1.*) ----
  // Carpeta del atlas: assets/images/newmenu/buttons/  (ahí van Animation.json, spritemap1.json y spritemap1.png)
  var BTN_ATLAS:String = 'newmenu/buttons';
  var BTN_SCALE:Float = 0.9;         // escala de TODOS los botones
  var BTN_SHIFT_X:Float = 0;         // desplazamiento extra de TODOS los botones (px, + = derecha)
  var BTN_SHIFT_Y:Float = 10;         // idem en vertical (+ = abajo)
  var PANEL_SHIFT_X:Float = 70;      // cuánto se mueve buttonsBG hacia la derecha (px)
  var BTN_FPS:Float = 24;            // fps de las animaciones del atlas
  var BTN_CONFIRM_WAIT:Float = 1.0;  // segundos que se ve la animación "confirm" antes de cambiar de state

  var STORY_X:Float = 705;
  var STORY_Y:Float = 35;
  var STORY_BOUNDS:Array<Float> = [20.3, 8.9, 463.3, 170.0];

  var SHOP_X:Float = 1105;
  var SHOP_Y:Float = 35;
  var SHOP_BOUNDS:Array<Float> = [450.2, 9.8, 625.2, 180.8];

  var FREEPLAY_X:Float = 705;
  var FREEPLAY_Y:Float = 165;
  var FREEPLAY_BOUNDS:Array<Float> = [28.1, 152.9, 635.1, 302.9];

  var WEBSITE_X:Float = 700;
  var WEBSITE_Y:Float = 275;
  var WEBSITE_BOUNDS:Array<Float> = [26.5, 275.4, 618.9, 428.8];

  var OPTIONS_X:Float = 735;
  var OPTIONS_Y:Float = 410;
  var OPTIONS_BOUNDS:Array<Float> = [47.5, 426.4, 217.4, 558.4];

  var CREDITS_X:Float = 890;
  var CREDITS_Y:Float = 411;
  var CREDITS_BOUNDS:Array<Float> = [226.5, 425.9, 619.5, 558.5];

  var AWARDS_X:Float = 735;
  var AWARDS_Y:Float = 535;
  var AWARDS_BOUNDS:Array<Float> = [47.5, 565.9, 217.4, 697.9];

  var EXIT_X:Float = 890;
  var EXIT_Y:Float = 535;
  var EXIT_BOUNDS:Array<Float> = [226.3, 565.5, 619.3, 697.5];

  // Candado (button_lock.png/.xml en assets/images/newmenu/): se pone encima de los botones bloqueados.
  var LOCK_ATLAS:String = 'newmenu/button_lock';
  var LOCK_FPS:Int = 24;
  var LOCK_DIM_ALPHA:Float = 0.5;    // cuánto se oscurece el botón bloqueado (0.5 = como un negro al 50% con la forma exacta del botón)

  // ---- Botón OST + fila de redes (music_social*.png/.xml en assets/images/newmenu/) ----
  // Al pulsar OST: suena confirmMenu, se anima "soundtrack press" y la fila de redes se abre HACIA LA IZQUIERDA
  // desde el OST, en su misma línea horizontal. La línea (music_social_lines) NO se ve (LINES_VISIBLE = false),
  // pero su escala X sigue marcando el progreso: va de casi 0 a normal y, mientras tanto, los botones sociales
  // aparecen con un deslizamiento y se quedan quietos en su sitio. El último en entrar es Amazon.
  var OST_ENABLED:Bool = true;
  var OST_ATLAS:String = 'newmenu/music_social';              // soundtrack basic / white / press
  var SOCIAL_ATLAS:String = 'newmenu/music_social_buttons';   // youtube, spotify, soundcloud, apple music, amazon
  var LINES_IMAGE:String = 'newmenu/music_social_lines';      // línea (invisible) que marca el progreso
  var OST_CENTER_X:Float = 645;       // centro del botón OST (px, antes de parallax)
  var OST_CENTER_Y:Float = 624;
  var OST_SCALE:Float = 0.85;
  var OST_IDLE_FPS:Float = 12;
  var OST_SELECT_FPS:Float = 12;
  var OST_PRESS_FPS:Float = 24;
  var OST_TOGGLE:Bool = true;         // true = volver a pulsar OST recoge la fila; false = se queda abierta

  var LINES_VISIBLE:Bool = true;     // true = dibuja la línea (para depurar)
  var LINES_GAP:Float = -38;            // separación entre el botón OST y el borde de la línea
  var LINES_SCALE_X:Float = 0.8;     // escala X FINAL de la línea
  var LINES_SCALE_Y:Float = 0.8;
  var LINES_START_SCALE_X:Float = 0.02; // escala X inicial (muy baja)
  var SOCIAL_DURATION:Float = 0.9;    // segundos que tarda en abrirse / cerrarse la fila
  var SOCIAL_SCALE:Float = 0.9;       // escala de los botones sociales
  var SOCIAL_FIRST_DX:Float = 121;    // distancia (px) del centro del OST al centro del primer botón
  var SOCIAL_SPACING:Float = 90;      // distancia entre centros de botones sociales
  var SOCIAL_SLIDE:Float = 50;        // px que se deslizan (desde el lado del OST) hasta su sitio
  var SOCIAL_WINDOW:Float = 0.3;      // fracción de la apertura que dura la entrada de cada botón
  var SOCIAL_HOVER_SCALE:Float = 0.12; // cuánto crece un botón social con el mouse encima
  var SOCIAL_LIST:Array<Dynamic> = [
    {id: 'apple', prefix: 'apple music button', url: 'https://music.apple.com/us/artist/animania-crew/1777493090'},
    {id: 'spotify', prefix: 'spotify button', url: 'https://open.spotify.com/artist/2BW1sh84ELs0TO4grqYmT3?si=TuwSLrFMR3uVeswvC_e9aw&nd=1&dlsi=e4834619b18e4a3b'},
    {id: 'soundcloud', prefix: 'soundcloud button', url: 'https://soundcloud.com/animaniacrew'},
    {id: 'youtube', prefix: 'youtube button', url: 'https://music.youtube.com/channel/UCRu6t87EK4A-hUaNw8x4OYw'},
    {id: 'amazon', prefix: 'amazon', url: 'https://music.amazon.com/artists/B0DLRGCSTC/animania-crew'}
  ];

  // ---- Intro (barras negras + ángulo de cámara) ----
  var INTRO_ENABLED:Bool = true;
  var INTRO_ANGLE:Float = -30;         // ángulo inicial de la cámara Y de las barras (grados); termina en 0
  var INTRO_HOLD:Float = 0.6;          // segundos con las barras cerradas (pantalla negra) antes de abrir
  var INTRO_DURATION:Float = 1.4;      // segundos que tardan en abrirse las barras / volver el ángulo a 0
  var INTRO_BAR_REST:Float = 40;       // px de cada barra que se quedan visibles (arriba y abajo) al terminar
  var INTRO_SKIP_ON_RETURN:Bool = true; // true = no repetir la intro al volver desde Freeplay/Options/Credits
  var INTRO_ZOOM:Float = 1.35;         // zoom con el que empieza la cámara; vuelve a 1.0 mientras se abre la intro

  // ---- Outro (barras que se cierran + ángulo positivo + zoom hacia adentro) ----
  var OUTRO_ENABLED:Bool = true;
  var OUTRO_ANGLE:Float = 30;          // ángulo final de la cámara Y de las barras (positivo)
  var OUTRO_ZOOM:Float = 1.35;         // zoom final de la cámara
  var OUTRO_DURATION:Float = 1.0;      // segundos que tardan en cerrarse las barras

  // ---- Selección de modo al pulsar Story ----
  // Atlas: assets/images/newmenu/story_select_buttons.png/.xml  (frames "amtake basic/white" y "animania basic/white").
  //   basic = reposo, white = hover (un poco más grande, se centra sobre el mismo punto).
  // El hover/click sigue la forma real del bloque (paralelogramo), no su caja.
  var SELECT_ATLAS:String = 'story_select_buttons';
  var SELECT_SCALE:Float = 0.94;         // escala de los bloques (el frame mide ~623x670; 0.94 = como la captura de referencia)
  var SELECT_LEFT_DX:Float = -292;       // centro del bloque izquierdo respecto al centro de la pantalla (px)
  var SELECT_RIGHT_DX:Float = 298;       // idem del bloque derecho
  var SELECT_DY:Float = 0;               // desplazamiento vertical de ambos (+ = abajo)
  var SELECT_DIM_ALPHA:Float = 0.6;      // oscurecimiento del menú de fondo
  var SELECT_BLUR:Float = 6;             // blur del menú de fondo (0 = sin blur)
  var SELECT_ANIM_TIME:Float = 0.3;      // segundos que tarda en abrirse / cerrarse
  var SELECT_SLIDE:Float = 70;           // px que entran deslizando cada bloque (desde su lado)
  var SELECT_CONFIRM_WAIT:Float = 0.45;  // segundos que se ve el bloque elegido antes del outro
  var SELECT_OTHER_ALPHA:Float = 0.35;   // opacidad del bloque NO elegido
  // Geometría de cada bloque en el frame "basic" (sin escalar): esquinas superior/inferior de los bordes izquierdo y derecho.
  var SELECT_AMTAKE_SHAPE:Array<Float> = [4, 4, 622, 521];     // topL, botL, topR, botR
  var SELECT_ANIMANIA_SHAPE:Array<Float> = [101, 1, 618, 618];
  var SELECT_SHAPE_H:Float = 668;        // alto útil del frame basic

  // ---- Touch (solo móviles) ----
  var BACK_BUTTON_X:Float = 10;      // posición del BackButton (esquina superior izquierda)
  var BACK_BUTTON_Y:Float = 10;

  var characters:FlxSprite;

  var waveform:WaveformSprite;

  var buttons:Array<Dynamic> = [];
  var busy:Bool = false;
  var touchBtn:Dynamic = null;

  var ostBtn:Dynamic = null;
  var socialLines:FlxSprite = null;
  var socialItems:Array<Dynamic> = [];
  var socialT:Float = 0;
  var socialTarget:Float = 0;

  var emitters:Array<Dynamic> = [];
  var particleTime:Float = 0;

  // Selección de modo (Story)
  var selectCam:FlxCamera = null;
  var selectDim:FlxSprite = null;
  var selectPanels:Array<Dynamic> = [];
  var selectOpen:Bool = false;       // la pantalla de selección está visible (abriéndose, abierta o cerrándose)
  var selectClosing:Bool = false;
  var selectChosen:Bool = false;     // ya se eligió un bloque (espera el outro)
  var selectT:Float = 0;             // 0 = cerrada, 1 = abierta
  var selectTouchPanel:Dynamic = null;
  var storyBtn:Dynamic = null;

  // Intro
  var introCam:FlxCamera;
  var barTop:FlxSprite;
  var barBottom:FlxSprite;
  var barW:Float = 0;
  var barH:Float = 0;
  var introPlaying:Bool = false;
  var introTime:Float = 0;

  // Outro
  var outroStarted:Bool = false;   // true en cuanto se pidió salir (evita lanzar dos outros / dos switchState)
  var outroPlaying:Bool = false;
  var outroTime:Float = 0;
  var outroDone:Dynamic = null;    // callback que cambia de state al terminar el outro

  // Zoom de cámara = (1 + bopAdd) * transZoom: el bop y el zoom de intro/outro no se pisan entre sí.
  var bopAdd:Float = 0;
  var transZoom:Float = 1.0;

  var uiStateMachine:UIStateMachine = new UIStateMachine();
  var canInteract(get, never):Bool;

  function get_canInteract():Bool
  {
    uiStateMachine.canInteract();
  }

  function new()
  {
    super();
  }

  override function create():Void
  {
    FlxG.cameras.reset(new FunkinCamera('newMainMenu'));

    var router = ModuleHandler.getModule('NewLoadingRouterModule');
    if (router != null && router.spareCount() < 2)
    {
      router.addSpareStates([new NewLoadingState(null), new NewLoadingState(null)]);
    }

    // Sin transición de entrada (se taparía la intro). La de salida se queda igual.
    // Ojo: transitionIn() es quien consume skipNextTransIn; como ya no corre, lo consumimos aquí
    // para que no se "escape" al siguiente state. Además sirve para saber si volvemos desde un sub-menú.
    var returningFromSubMenu:Bool = FlxTransitionableState.skipNextTransIn;
    FlxTransitionableState.skipNextTransIn = false;
    this.transIn = null;
    this.transOut = FlxTransitionableState.defaultTransOut;

    // Misma música que el menú normal, sin reiniciarla si ya está sonando.
    FunkinSound.playMusic('freakyMenu', {
      overrideExisting: true,
      restartTrack: false,
      persist: true
    });

    this.persistentUpdate = true;
    this.persistentDraw = true;

    // El juego oculta el mouse desde el título: aquí lo mostramos (en móvil no hay cursor).
    if (!FlxG.onMobile) Cursor.show();

    computeWideLayout();

    buildBackground();
    buildWaveform();
    emitters.push(createEmitter(SNOW_CFG, PARALLAX_SNOW));
    buildCharacters();
    buildButtonsBackground();
    buildButtons();
    // Las hojas van al final: quedan por encima de todo lo anterior.
    emitters.push(createEmitter(LEAF_CFG, PARALLAX_LEAVES));

    // La selección de modo usa su propia cámara: se crea ANTES que la de la intro para que las barras queden por encima.
    buildStorySelect();

    // La intro va al final de todo (su cámara se dibuja encima de las demás).
    buildIntro(returningFromSubMenu && INTRO_SKIP_ON_RETURN);

    super.create();

    // Controles táctiles (solo móviles).
    if (FlxG.onMobile) buildMobileControls();
  }

  /**
   * Solo móviles: BackButton nativo (equivale a BACK_P / ESC en PC). Como este menú ya es el principal,
   * vuelve a la pantalla de título, igual que goBack().
   */
  #if mobile
  function buildMobileControls():Void
  {
    addBackButton(BACK_BUTTON_X + Math.max(FullScreenScaleMode.gameNotchSize.x - 10, 0), BACK_BUTTON_Y, FlxColor.WHITE, goBack, 0.7);

    if (backButton != null)
    {
      // Al empezar el confirm del BackButton se ignoran los toques sobre los botones del menú.
      backButton.onConfirmStart.add(function()
      {
        busy = true;
      });
    }
  }
  #end

  /**
   * Intro: 2 barras negras (mitad superior + mitad inferior) cubren TODA la pantalla mientras la cámara
   * principal está a INTRO_ANGLE. Después las barras se abren (sin salir de pantalla: queda INTRO_BAR_REST px
   * en cada borde) y el ángulo vuelve a 0. Se anima a mano en update() (sin FlxTween, que en HScript falla).
   * Si `skip` es true (volvemos desde otro menú) las barras aparecen directamente en su posición final.
   */
  function buildIntro(skip:Bool):Void
  {
    if (!INTRO_ENABLED) return;

    introCam = new FlxCamera();
    introCam.bgColor = 0x00000000; // transparente
    FlxG.cameras.add(introCam, false);

    // Cada barra es un píxel negro escalado (sin texturas gigantes), mucho más grande que la pantalla:
    // así sigue cubriéndola entera aunque se incline. Rota alrededor del centro de la pantalla (ver setBarsOpen).
    barW = FlxG.width * 3;
    barH = FlxG.height * 2;

    barTop = makeBar();
    barBottom = makeBar();

    if (skip)
    {
      setBarsOpen(1, 0);
      FlxG.camera.angle = 0;
      transZoom = 1.0;
      return;
    }

    setBarsOpen(0, INTRO_ANGLE);
    FlxG.camera.angle = INTRO_ANGLE;
    transZoom = INTRO_ZOOM;
    FlxG.camera.zoom = INTRO_ZOOM;
    introPlaying = true;
    introTime = 0;
  }

  function makeBar():FlxSprite
  {
    var bar:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
    bar.scale.set(barW, barH);
    bar.origin.set(0, 0); // gira y escala desde su esquina superior izquierda
    bar.antialiasing = true; // bordes suaves al ir inclinadas
    bar.scrollFactor.set(0, 0);
    bar.cameras = [introCam];
    add(bar);
    return bar;
  }

  /**
   * e = 0: barras cerradas (cubren la pantalla). e = 1: abiertas (queda INTRO_BAR_REST px arriba y abajo).
   * `angle` inclina las barras (mismo valor que FlxG.camera.angle): rotan alrededor del centro de la pantalla.
   */
  function setBarsOpen(e:Float, angle:Float):Void
  {
    var cx:Float = FlxG.width / 2;
    var cy:Float = FlxG.height / 2;

    // Distancia del eje central al borde interior de cada barra. Cerrado = -2 px (solape, sin costura).
    var o:Float = -2 + (FlxG.height / 2 - INTRO_BAR_REST + 2) * e;

    var rad:Float = angle * Math.PI / 180;
    placeBar(barTop, -barW / 2, -o - barH, cx, cy, Math.cos(rad), Math.sin(rad), angle);
    placeBar(barBottom, -barW / 2, o, cx, cy, Math.cos(rad), Math.sin(rad), angle);
  }

  /** (dx, dy) = esquina superior izquierda de la barra respecto al centro, sin rotar. Se rota esa esquina y la barra gira sobre ella. */
  function placeBar(bar:FlxSprite, dx:Float, dy:Float, cx:Float, cy:Float, cs:Float, sn:Float, angle:Float):Void
  {
    bar.x = cx + dx * cs - dy * sn;
    bar.y = cy + dx * sn + dy * cs;
    bar.angle = angle;
  }

  function updateIntro(elapsed:Float):Void
  {
    if (!introPlaying) return;

    introTime += Math.min(elapsed, 0.05); // evita saltarse la espera si el primer frame tarda en cargar

    var t:Float = (introTime - INTRO_HOLD) / INTRO_DURATION;
    t = Math.min(Math.max(t, 0), 1);
    var e:Float = FlxEase.quartInOut(t);

    var angle:Float = INTRO_ANGLE * (1 - e);
    setBarsOpen(e, angle);
    FlxG.camera.angle = angle;
    transZoom = 1.0 + (INTRO_ZOOM - 1.0) * (1 - e); // INTRO_ZOOM -> 1.0

    if (t >= 1)
    {
      introPlaying = false;
      FlxG.camera.angle = 0;
      transZoom = 1.0;
      setBarsOpen(1, 0);
    }
  }

  /**
   * Outro: inverso de la intro. Las barras se cierran por completo, la cámara gira hasta OUTRO_ANGLE (positivo)
   * y se acerca hasta OUTRO_ZOOM. Al terminar llama a `onDone` (normalmente el switchState).
   * Si el outro está desactivado (o no hay barras) llama a `onDone` directamente.
   */
  function playOutro(onDone:Dynamic):Void
  {
    if (outroStarted) return;
    outroStarted = true;
    busy = true;

    if (!OUTRO_ENABLED || !INTRO_ENABLED || barTop == null)
    {
      onDone();
      return;
    }

    // La pantalla ya queda negra con las barras cerradas: la transición de salida (fundido negro) solo añadiría espera.
    this.transOut = null;

    if (introCam != null) introCam.visible = true;
    introPlaying = false;
    bopAdd = 0;

    outroDone = onDone;
    outroPlaying = true;
    outroTime = 0;
  }

  function updateOutro(elapsed:Float):Void
  {
    if (!outroPlaying) return;

    outroTime += Math.min(elapsed, 0.05);

    var t:Float = Math.min(outroTime / OUTRO_DURATION, 1);
    var e:Float = FlxEase.quartInOut(t);

    var angle:Float = OUTRO_ANGLE * e;
    setBarsOpen(1 - e, angle);
    FlxG.camera.angle = angle;
    transZoom = 1.0 + (OUTRO_ZOOM - 1.0) * e; // 1.0 -> OUTRO_ZOOM

    if (t >= 1)
    {
      outroPlaying = false;
      FlxG.camera.angle = OUTRO_ANGLE;
      transZoom = OUTRO_ZOOM;
      setBarsOpen(0, OUTRO_ANGLE);

      var cb:Dynamic = outroDone;
      outroDone = null;
      if (cb != null) cb();
    }
  }

  /**
   * Calcula cómo se adapta el layout a la pantalla actual (FullScreenScaleMode).
   * Se usa FlxG.width / FlxG.initialWidth directamente (en vez de FullScreenScaleMode.wideScale) porque
   * wideScale solo se actualiza cuando hay recorte y puede quedar con un valor viejo tras un resize.
   */
  function computeWideLayout():Void
  {
    var baseW:Float = FlxG.initialWidth;
    var baseH:Float = FlxG.initialHeight;

    wideShiftX = Math.max(FlxG.width - baseW, 0);
    sceneK = Math.max(1.0, Math.max(FlxG.width / baseW, FlxG.height / baseH));

    parMaxX = FlxG.onMobile ? PARALLAX_MOBILE_X : PARALLAX_MAX_X;
    parMaxY = FlxG.onMobile ? PARALLAX_MOBILE_Y : PARALLAX_MAX_Y;
  }

  /**
   * Fondo principal. A 16:9 queda exactamente igual que antes (cover + 4% de sobreescala, centrado).
   * En pantallas anchas el fondo crece para cubrir el ancho, pero se ancla ABAJO-IZQUIERDA (no al centro):
   * así el suelo no sube/baja respecto a los personajes (que van anclados abajo).
   */
  function buildBackground():Void
  {
    bg = new FlxSprite().loadGraphic(Paths.image('newmenu/bg'));
    bg.scrollFactor.set(PARALLAX_BG, PARALLAX_BG);

    var baseW:Float = FlxG.initialWidth;
    var baseH:Float = FlxG.initialHeight;

    // Sobreescala: mínimo 4%, o lo que haga falta para que el parallax (según plataforma) nunca deje ver los bordes.
    var marginX:Float = PARALLAX_BG * parMaxX + 2;
    var marginY:Float = PARALLAX_BG * parMaxY + 2;
    var over:Float = Math.max(1.04, Math.max(1 + 2 * marginX / FlxG.width, 1 + 2 * marginY / FlxG.height));

    // Diseño 16:9 (referencia) y escala real. r = cuánto más grande es el fondo que en 16:9.
    var coverBase:Float = Math.max(baseW / bg.frameWidth, baseH / bg.frameHeight);
    var coverNow:Float = Math.max(FlxG.width / bg.frameWidth, FlxG.height / bg.frameHeight);
    var r:Float = Math.max(coverNow / coverBase, 1.0);

    var scaleBase:Float = coverBase * over;
    var w0:Float = bg.frameWidth * scaleBase;
    var h0:Float = bg.frameHeight * scaleBase;
    var x0:Float = (baseW - w0) / 2;   // posición en el diseño 16:9 (centrado)
    var y0:Float = (baseH - h0) / 2;

    bg.scale.set(scaleBase * r, scaleBase * r);
    bg.updateHitbox();

    // Se escala la posición de diseño respecto a la esquina inferior izquierda de la pantalla.
    bg.x = x0 * r;
    bg.y = FlxG.height + (y0 + h0 - baseH) * r - bg.height;

    // Seguro: nunca debe quedar hueco a la derecha ni arriba.
    if (bg.x + bg.width < FlxG.width + marginX) bg.x = FlxG.width + marginX - bg.width;
    if (bg.x > -marginX) bg.x = -marginX;
    if (bg.y > -marginY) bg.y = -marginY;

    add(bg);
  }

  /**
   * Waveform de la música actual, vertical y semitransparente.
   * Se sincroniza con `FlxG.sound.music.time` en cada frame.
   */
  function buildWaveform():Void
  {
    var music = FlxG.sound.music;
    if (music == null) return;

    try
    {
      waveform = new WaveformSprite(music.waveformData, WaveformOrientation.VERTICAL, WAVE_COLOR, WAVE_DURATION);
      waveform.x = WAVE_X;
      waveform.y = 0;
      waveform.width = WAVE_WIDTH;
      waveform.height = FlxG.height;
      waveform.amplitude = WAVE_AMPLITUDE;
      waveform.minWaveformSize = 2;
      waveform.scrollFactor.set(PARALLAX_WAVE, PARALLAX_WAVE);
      add(waveform);
    }
    catch (e:Dynamic)
    {
      trace('[NewMainMenu] No se pudo crear el waveform: ' + e);
      waveform = null;
    }
  }

  /**
   * BF y GF (un solo atlas) con su animación de baile en loop, abajo a la izquierda.
   * El atlas trae 16 frames (8 poses x2), prefijo "caramel".
   */
  function buildCharacters():Void
  {
    characters = new FlxSprite();
    characters.frames = Paths.getSparrowAtlas('newmenu/Caramel');
    characters.animation.addByPrefix('dance', 'caramel', CHAR_FPS, true);
    characters.animation.play('dance');
    characters.antialiasing = true;
    characters.scrollFactor.set(PARALLAX_CHARS, PARALLAX_CHARS);

    // Escala fija (no crece con la pantalla). En pantallas anchas se mueven a la derecha una fracción del ancho extra.
    characters.scale.set(CHAR_SCALE, CHAR_SCALE);
    characters.updateHitbox();
    characters.x = CHAR_X + wideShiftX * CHAR_WIDE_SHIFT;
    characters.y = FlxG.height - characters.height - CHAR_BOTTOM_MARGIN + 20;

    add(characters);
  }

  /**
   * Parallax: la cámara se desplaza un poco hacia donde apunta el mouse (PC) o el dedo (móvil).
   * Como cada capa tiene su propio scrollFactor, se mueven a distinta velocidad.
   * En móvil, sin dedo en pantalla, la cámara hace un vaivén lento para que el efecto se note siempre.
   */
  function updateParallax(elapsed:Float):Void
  {
    parTime += elapsed;

    var nx:Float = 0;
    var ny:Float = 0;

    if (FlxG.onMobile)
    {
      // Con el dedo sobre un botón se congela: así el botón no se mueve bajo el dedo y el tap no se cancela.
      if (touchBtn != null) return;

      var t = TouchUtil.touch;
      if (TouchUtil.pressed && t != null)
      {
        nx = (t.screenX / FlxG.width - 0.5) * 2;
        ny = (t.screenY / FlxG.height - 0.5) * 2;
      }
      else if (PARALLAX_IDLE_SWAY)
      {
        nx = Math.sin(parTime * PARALLAX_IDLE_SPEED) * PARALLAX_IDLE_AMOUNT;
        ny = Math.cos(parTime * PARALLAX_IDLE_SPEED * 0.7) * PARALLAX_IDLE_AMOUNT;
      }
    }
    else
    {
      // Se lee la posición directamente del stage (ventana) en vez de FlxG.mouse,
      // porque FlxG.mouse puede no actualizarse mientras el cursor del juego está oculto.
      nx = (FlxG.stage.mouseX / FlxG.stage.stageWidth - 0.5) * 2;
      ny = (FlxG.stage.mouseY / FlxG.stage.stageHeight - 0.5) * 2;
    }

    nx = Math.min(Math.max(nx, -1), 1);
    ny = Math.min(Math.max(ny, -1), 1);

    var smoothing:Float = 1 - Math.exp(-PARALLAX_SMOOTH * elapsed);
    var cam = FlxG.camera;
    var newX:Float = cam.scroll.x + (nx * parMaxX - cam.scroll.x) * smoothing;
    var newY:Float = cam.scroll.y + (ny * parMaxY - cam.scroll.y) * smoothing;
    cam.scroll.set(newX, newY);
  }

  /** Bop de cámara: el zoom salta en cada beat de la música. */
  override function beatHit():Bool
  {
    var result:Bool = super.beatHit();

    // Sin bop mientras corre la intro o el outro (el zoom lo controlan ellos).
    if (!introPlaying && !outroStarted) bopAdd = BOP_ZOOM;

    return result;
  }

  /**
   * Crea un emisor de partículas (nieve u hojas) con un pool fijo de `maxActive` sprites.
   * Las partículas caen desde la esquina superior derecha, en diagonal hacia la izquierda.
   * Se dibujan detrás del fondo de los botones, así que solo se ven al salir por su borde izquierdo.
   */
  function createEmitter(cfg:Dynamic, parallax:Float):Dynamic
  {
    var atlas = Paths.getSparrowAtlas(cfg.atlas);

    var e:Dynamic = {
      cfg: cfg,
      pool: [],
      baseVX: [],
      phase: [],
      swaySpeed: [],
      roundTimer: cfg.startDelay, // cuenta atrás hasta la próxima ronda
      pending: 0,                 // partículas que faltan por soltar de la ronda actual
      spawnTimer: 0               // cuenta atrás hasta soltar la siguiente
    };

    for (i in 0...cfg.maxActive)
    {
      var p:FlxSprite = new FlxSprite();
      p.frames = atlas;
      p.scrollFactor.set(parallax, parallax);
      p.antialiasing = true;
      p.exists = false; // inactiva hasta que le toque salir
      add(p);

      e.pool.push(p);
      e.baseVX.push(0.0);
      e.phase.push(FlxG.random.float(0, 6.28));
      e.swaySpeed.push(FlxG.random.float(1.0, 2.5));
    }

    return e;
  }

  /** Suelta una partícula del pool (si hay alguna libre) en el borde superior o derecho. */
  function spawnParticle(e:Dynamic):Bool
  {
    var cfg:Dynamic = e.cfg;
    var index:Int = -1;
    for (i in 0...e.pool.length)
    {
      if (!e.pool[i].exists)
      {
        index = i;
        break;
      }
    }
    if (index == -1) return false; // tope alcanzado

    var p:FlxSprite = e.pool[index];
    p.exists = true;
    p.animation.frameIndex = FlxG.random.int(0, p.frames.frames.length - 1);

    var s:Float = FlxG.random.float(cfg.scaleMin, cfg.scaleMax);
    p.scale.set(s, s);
    p.updateHitbox();

    p.alpha = FlxG.random.float(cfg.alphaMin, cfg.alphaMax);
    p.angle = FlxG.random.float(0, 360);
    p.angularVelocity = FlxG.random.float(-cfg.spin, cfg.spin);

    if (cfg.vertical)
    {
      // Cualquier punto del borde superior, a lo ancho de toda la pantalla.
      p.x = FlxG.random.float(0, FlxG.width - p.width);
      p.y = -p.height - FlxG.random.float(0, 30);
    }
    // 60% nace por arriba (zona derecha), 40% por el borde derecho (mitad superior).
    else if (FlxG.random.bool(60))
    {
      p.x = FlxG.random.float(FlxG.width * 0.5, FlxG.width + 40);
      p.y = -p.height - FlxG.random.float(0, 40);
    }
    else
    {
      p.x = FlxG.width + FlxG.random.float(10, 60);
      p.y = FlxG.random.float(-20, FlxG.height * 0.5);
    }

    e.baseVX[index] = FlxG.random.float(cfg.vxMin, cfg.vxMax);
    p.velocity.x = e.baseVX[index];
    p.velocity.y = FlxG.random.float(cfg.vyMin, cfg.vyMax);
    return true;
  }

  function updateEmitter(e:Dynamic, elapsed:Float):Void
  {
    var cfg:Dynamic = e.cfg;

    // Nueva ronda: se encolan unas pocas partículas.
    e.roundTimer -= elapsed;
    if (e.roundTimer <= 0)
    {
      e.pending += FlxG.random.int(cfg.batchMin, cfg.batchMax);
      e.roundTimer = FlxG.random.float(cfg.intervalMin, cfg.intervalMax);
    }

    // Las partículas de la ronda salen una a una, no todas de golpe.
    if (e.pending > 0)
    {
      e.spawnTimer -= elapsed;
      if (e.spawnTimer <= 0)
      {
        if (spawnParticle(e))
        {
          e.pending -= 1;
          e.spawnTimer = FlxG.random.float(cfg.staggerMin, cfg.staggerMax);
        }
        else
        {
          e.spawnTimer = 0.25; // pool lleno: reintenta en un momento
        }
      }
    }

    // Movimiento y reciclaje.
    for (i in 0...e.pool.length)
    {
      var p:FlxSprite = e.pool[i];
      if (!p.exists) continue;

      // Vaivén lateral suave.
      p.velocity.x = e.baseVX[i] + Math.sin(particleTime * e.swaySpeed[i] + e.phase[i]) * cfg.sway;

      // Fuera de pantalla (izquierda o abajo): vuelve al pool.
      if (p.x < -p.width - 20 || p.y > FlxG.height + 20)
      {
        p.exists = false;
      }
    }
  }

  /** Fondo del panel de botones: alto completo de pantalla, pegado al borde derecho. */
  function buildButtonsBackground():Void
  {
    buttonsBG = new FlxSprite().loadGraphic(Paths.image('newmenu/buttonsBG'));
    buttonsBG.scrollFactor.set(PARALLAX_PANEL, PARALLAX_PANEL);

    // 4% de sobreescala y 20 px de margen a la derecha para que el parallax no deje huecos.
    var fitScale:Float = FlxG.height / buttonsBG.frameHeight * 1.04;
    buttonsBG.scale.set(fitScale, fitScale);
    buttonsBG.updateHitbox();
    buttonsBG.x = FlxG.width - buttonsBG.width + 20 + PANEL_SHIFT_X;
    buttonsBG.y = -(buttonsBG.height - FlxG.height) / 2;

    add(buttonsBG);
  }

  /**
   * Crea todos los botones del menú. Para agregar uno nuevo: copia la línea de Story con su etiqueta
   * del atlas ('freeplay', 'website', 'credits', 'exit'...), su posición/caja y su acción.
   */
  function buildButtons():Void
  {
    addLockedButton('shop', 'shop', SHOP_X, SHOP_Y, SHOP_BOUNDS);

    // Story ya no entra directo: tras la animación "confirm" abre la selección de modo (sin outro; el outro se hace al elegir).
    storyBtn = addMenuButton('story', 'storymode', STORY_X, STORY_Y, STORY_BOUNDS, openStorySelect);
    storyBtn.outro = false;

    var freeplayBtn:Dynamic = addMenuButton('freeplay', 'freeplay', FREEPLAY_X, FREEPLAY_Y, FREEPLAY_BOUNDS, openFreeplay);
    freeplayBtn.outro = false; // Freeplay se abre como substate con su propia transición: sin outro

    addLockedButton('website', 'website', WEBSITE_X, WEBSITE_Y, WEBSITE_BOUNDS);

    addMenuButton('options', 'options', OPTIONS_X, OPTIONS_Y, OPTIONS_BOUNDS, function() {
      // OptionsState al salir hace switchState(new MainMenuState()): el redirect nos devuelve a este menú.
      FlxG.switchState(new OptionsState());
    });

    addMenuButton('credits', 'credits', CREDITS_X, CREDITS_Y, CREDITS_BOUNDS, function() {
      // CreditsState también vuelve con switchState(new MainMenuState()).
      FlxG.switchState(new CreditsState());
    });

    addLockedButton('awards', 'awards', AWARDS_X, AWARDS_Y, AWARDS_BOUNDS);

    addMenuButton('exit', 'exit', EXIT_X, EXIT_Y, EXIT_BOUNDS, function() {
      // Exit = volver a la pantalla de título (lo mismo que hace BACK en el menú original).
      Cursor.hide();
      FlxG.switchState(new NewTitleState());
    });

    if (OST_ENABLED) buildOstRow();
  }

  /**
   * Botón OST (atlas Sparrow: "soundtrack basic" = idle, "soundtrack white" = select, "soundtrack press" = confirm),
   * la línea (escala X casi 0) y los botones sociales (invisibles hasta que se abre la fila).
   * Orden de dibujo: línea -> sociales -> OST (el OST queda encima del arranque de la línea).
   */
  function buildOstRow():Void
  {
    var ostSprite:FlxSprite = new FlxSprite();
    ostSprite.frames = Paths.getSparrowAtlas(OST_ATLAS);
    ostSprite.animation.addByPrefix('basic', 'soundtrack basic', OST_IDLE_FPS, true);
    ostSprite.animation.addByPrefix('white', 'soundtrack white', OST_SELECT_FPS, true);
    ostSprite.animation.addByPrefix('press', 'soundtrack press', OST_PRESS_FPS, false);
    ostSprite.antialiasing = true;
    ostSprite.scrollFactor.set(PARALLAX_PANEL, PARALLAX_PANEL);
    ostSprite.scale.set(OST_SCALE, OST_SCALE);

    // Caja de clic = tamaño del frame idle (158x134) escalado, centrada en OST_CENTER.
    var hw:Float = 158 * OST_SCALE / 2;
    var hh:Float = 134 * OST_SCALE / 2;

    // ---- Línea (marca el progreso; invisible por defecto): origen en su borde DERECHO (lado del OST),
    // así al crecer en X se estira hacia la izquierda ----
    var lineRight:Float = OST_CENTER_X - hw - LINES_GAP;
    socialLines = new FlxSprite().loadGraphic(Paths.image(LINES_IMAGE));
    socialLines.antialiasing = true;
    socialLines.scrollFactor.set(PARALLAX_PANEL, PARALLAX_PANEL);
    socialLines.origin.set(socialLines.frameWidth, socialLines.frameHeight / 2); // (sin updateHitbox: rompería este origen)
    socialLines.scale.set(LINES_START_SCALE_X, LINES_SCALE_Y);
    socialLines.x = lineRight - socialLines.frameWidth;
    socialLines.y = OST_CENTER_Y - socialLines.frameHeight / 2;
    socialLines.visible = LINES_VISIBLE;
    add(socialLines);

    // ---- Botones sociales: en la misma línea horizontal que el OST, hacia la izquierda ----
    var n:Int = SOCIAL_LIST.length;
    var socialAtlas = Paths.getSparrowAtlas(SOCIAL_ATLAS);
    for (i in 0...n)
    {
      var entry:Dynamic = SOCIAL_LIST[i];
      var sp:FlxSprite = new FlxSprite();
      sp.frames = socialAtlas;
      sp.animation.addByPrefix('idle', entry.prefix, 1, false);
      sp.animation.play('idle');
      sp.antialiasing = true;
      sp.scrollFactor.set(PARALLAX_PANEL, PARALLAX_PANEL);
      sp.centerOrigin();
      sp.scale.set(SOCIAL_SCALE, SOCIAL_SCALE);
      sp.updateHitbox();
      sp.alpha = 0;
      sp.visible = false;
      add(sp);

      socialItems.push({
        sprite: sp,
        url: entry.url,
        cx: OST_CENTER_X - SOCIAL_FIRST_DX - SOCIAL_SPACING * i,
        cy: OST_CENTER_Y,
        index: i,
        hoverK: 0.0
      });
    }

    add(ostSprite);

    ostBtn = {
      id: 'ost',
      isOst: true,
      sprite: ostSprite,
      cx: OST_CENTER_X,
      cy: OST_CENTER_Y,
      left: OST_CENTER_X - hw,
      top: OST_CENTER_Y - hh,
      right: OST_CENTER_X + hw,
      bottom: OST_CENTER_Y + hh,
      hovered: false,
      locked: false,
      pressing: false,
      shake: 0.0,
      outro: true,
      onConfirm: null
    };
    playBtn(ostBtn, 'idle');
    buttons.push(ostBtn);

    updateSocial(0); // deja todo en el estado "cerrado"
  }

  /** Reproduce un estado ('idle' | 'select' | 'confirm') en un botón, sea del atlas de Animate o el OST (Sparrow). */
  function playBtn(btn:Dynamic, state:String):Void
  {
    if (btn.isOst == true)
    {
      // Mientras corre "press" no se interrumpe con hover/idle (al terminar, updateOst decide cuál toca).
      if (btn.pressing && state != 'confirm') return;

      var anim:String = state == 'confirm' ? 'press' : (state == 'select' ? 'white' : 'basic');
      btn.pressing = (state == 'confirm');
      btn.sprite.animation.play(anim, true);

      // Los frames de cada animación tienen distinto tamaño: se recentra para que el botón no "salte".
      btn.sprite.updateHitbox();
      btn.sprite.centerOrigin();
      btn.sprite.x = btn.cx - btn.sprite.width / 2;
      btn.sprite.y = btn.cy - btn.sprite.height / 2;
      return;
    }

    btn.sprite.anim.play(btn.id + '_' + state, true);
  }

  /** Clic en OST: sonido confirm + animación press + abre (o recoge) la fila de redes. No bloquea el menú. */
  function pressOst(btn:Dynamic):Void
  {
    FunkinSound.playOnce(Paths.sound('confirmMenu'));
    playBtn(btn, 'confirm');
    if (FlxG.onMobile) btn.hovered = false; // en móvil no hay hover al terminar el press

    if (socialTarget >= 1 && OST_TOGGLE) socialTarget = 0;
    else socialTarget = 1;
  }

  /** Al terminar "press" vuelve a select (si el mouse sigue encima) o idle. */
  function updateOst(elapsed:Float):Void
  {
    if (ostBtn == null) return;

    if (ostBtn.pressing && ostBtn.sprite.animation.finished)
    {
      ostBtn.pressing = false;
      playBtn(ostBtn, ostBtn.hovered ? 'select' : 'idle');
    }
  }

  /**
   * Abre/cierra la fila. socialT va de 0 a 1 en SOCIAL_DURATION segundos (manual, sin FlxTween).
   * La línea crece en X de LINES_START_SCALE_X a LINES_SCALE_X; cada botón social tiene su ventana de entrada
   * (según su posición en la fila) donde se desliza desde la izquierda y aparece. El último (Amazon) termina con la línea.
   */
  function updateSocial(elapsed:Float):Void
  {
    if (socialLines == null) return;

    if (socialT != socialTarget)
    {
      var step:Float = elapsed / SOCIAL_DURATION;
      if (socialT < socialTarget) socialT = Math.min(socialT + step, socialTarget);
      else socialT = Math.max(socialT - step, socialTarget);
    }

    var e:Float = FlxEase.cubeOut(socialT);

    socialLines.scale.x = LINES_START_SCALE_X + (LINES_SCALE_X - LINES_START_SCALE_X) * e;

    var n:Int = socialItems.length;
    for (item in socialItems)
    {
      var start:Float = item.index / n;                       // el botón entra cuando la línea llega a su slot
      var win:Float = Math.min(SOCIAL_WINDOW, 1 - start);     // el último termina justo al final
      var q:Float = Math.min(Math.max((e - start) / win, 0), 1);
      var k:Float = FlxEase.quadOut(q);

      var sp:FlxSprite = item.sprite;
      sp.alpha = k;
      sp.visible = q > 0;
      sp.x = item.cx - sp.width / 2 + SOCIAL_SLIDE * (1 - k); // viene desde el lado del OST
      sp.y = item.cy - sp.height / 2;
    }
  }

  /** ¿Está el puntero (mouse en PC, dedo en móvil) dentro de la caja? Compensa parallax y zoom como isMouseOver. */
  function pointerOver(l:Float, t:Float, r:Float, b:Float):Bool
  {
    var p = null;
    if (FlxG.onMobile)
    {
      var tt = TouchUtil.touch;
      if (tt == null) return false;
      p = tt.getWorldPosition(FlxG.camera);
    }
    else
    {
      p = FlxG.mouse.getWorldPosition(FlxG.camera);
    }
    var mx:Float = p.x + FlxG.camera.scroll.x * (PARALLAX_PANEL - 1);
    var my:Float = p.y + FlxG.camera.scroll.y * (PARALLAX_PANEL - 1);
    p.put();
    return mx >= l && mx <= r && my >= t && my <= b;
  }

  /**
   * Botones sociales ya abiertos: hover (crecen un poco + cursor Pointer) y clic/toque = abre su url.
   * Solo responden con la fila completamente abierta y sin otro botón confirmado / intro / outro.
   */
  function updateSocialClicks(elapsed:Float):Void
  {
    if (socialItems.length == 0) return;

    var active:Bool = !busy && !introPlaying && !outroStarted && socialT >= 1 && socialTarget >= 1;
    var anyHover:Bool = false;
    var pressed:Bool = FlxG.onMobile ? TouchUtil.justPressed : FlxG.mouse.justPressed;

    for (item in socialItems)
    {
      var sp:FlxSprite = item.sprite;
      var hw:Float = sp.width / 2;
      var hh:Float = sp.height / 2;
      var over:Bool = active && pointerOver(item.cx - hw, item.cy - hh, item.cx + hw, item.cy + hh);

      if (over)
      {
        anyHover = true;
        if (item.hoverK == 0 && !FlxG.onMobile) FunkinSound.playOnce(Paths.sound('scrollMenu'));
        if (pressed)
        {
          FunkinSound.playOnce(Paths.sound('confirmMenu'));
          FlxG.openURL(item.url);
        }
      }

      // Crecimiento suave con el hover (escala alrededor del centro, sin tocar la posición).
      var target:Float = over ? 1.0 : 0.0;
      item.hoverK += (target - item.hoverK) * Math.min(elapsed * 14, 1);
      if (Math.abs(target - item.hoverK) < 0.01) item.hoverK = target;
      var sc:Float = SOCIAL_SCALE * (1 + SOCIAL_HOVER_SCALE * item.hoverK);
      sp.scale.set(sc, sc);
    }

    // Sobrescribe el cursor que dejó updateButtons (solo PC).
    if (anyHover && !FlxG.onMobile) Cursor.cursorMode = CursorMode.Pointer;
  }

  /**
   * Ya no hace nada: la redirección de MainMenuState -> este menú la hace NewMainMenuModule (onStateChangeEnd),
   * para todas las entradas al menú original (Options, Credits, Freeplay, Story, canciones...).
   * Se deja la función para no tocar los botones que la llaman.
   */
  function debugRedirect():Void
  {
    if (!canInteract) return;

    #if FEATURE_DEBUG_MENU
    if (PlayerSettings.player1.controls.DEBUG_MENU)
    {
      persistentUpdate = false;
      FlxG.state.openSubState(new DebugMenuSubState());
    }
    #end
  }

  // ---------------------------------------------------------------------------
  // SELECCIÓN DE MODO (Story): AM Take = StoryMenuState vanilla | Animania = StoryMenuCustom
  // ---------------------------------------------------------------------------

  /**
   * Crea (oculto) todo lo de la selección: cámara propia, capa oscura y los 2 bloques (basic + white cada uno).
   * La cámara va entre el menú y las barras de la intro/outro. Los bloques son sprites estáticos (basic y white por separado,
   * se alterna la visibilidad) para que el cambio de tamaño entre frames no haga saltar nada.
   */
  function buildStorySelect():Void
  {
    selectCam = new FlxCamera();
    selectCam.bgColor = 0x00000000; // transparente
    FlxG.cameras.add(selectCam, false);

    // La capa oscura es mucho más grande que la pantalla: sigue cubriéndola aunque la cámara gire/haga zoom en el outro.
    selectDim = new FlxSprite().makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.BLACK);
    selectDim.x = -FlxG.width;
    selectDim.y = -FlxG.height;
    selectDim.scrollFactor.set(0, 0);
    selectDim.cameras = [selectCam];
    selectDim.alpha = 0;
    selectDim.visible = false;
    add(selectDim);

    var atlas = Paths.getSparrowAtlas(SELECT_ATLAS);
    var cy:Float = FlxG.height / 2 + SELECT_DY;

    var leftBasic:FlxSprite = makeSelectSprite(atlas, 'amtake basic', FlxG.width / 2 + SELECT_LEFT_DX, cy);
    var rightBasic:FlxSprite = makeSelectSprite(atlas, 'animania basic', FlxG.width / 2 + SELECT_RIGHT_DX, cy);
    // Los white van después: al hacer hover quedan por encima del vecino (crecen ~2%).
    var leftWhite:FlxSprite = makeSelectSprite(atlas, 'amtake white', FlxG.width / 2 + SELECT_LEFT_DX, cy);
    var rightWhite:FlxSprite = makeSelectSprite(atlas, 'animania white', FlxG.width / 2 + SELECT_RIGHT_DX, cy);

    selectPanels = [];
    selectPanels.push({
      id: 'amtake',
      basic: leftBasic,
      white: leftWhite,
      bx: leftBasic.x, by: leftBasic.y,
      wx: leftWhite.x, wy: leftWhite.y,
      shape: SELECT_AMTAKE_SHAPE,
      slideDir: -1,
      hovered: false,
      onConfirm: function() {
        // AM Take -> StoryMenuState vanilla del juego.
        setStoryRedirect(true);
        FlxG.signals.preStateSwitch.addOnce(function() {
          FunkinMemory.clearFreeplay();
          FunkinMemory.purgeCache();
        });
        FlxG.switchState(new StoryMenuState());
      }
    });
    selectPanels.push({
      id: 'animania',
      basic: rightBasic,
      white: rightWhite,
      bx: rightBasic.x, by: rightBasic.y,
      wx: rightWhite.x, wy: rightWhite.y,
      shape: SELECT_ANIMANIA_SHAPE,
      slideDir: 1,
      hovered: false,
      onConfirm: function() {
        // Animania -> tu StoryMenuCustom.
        setStoryRedirect(false);
        FlxG.signals.preStateSwitch.addOnce(function() {
          FunkinMemory.clearFreeplay();
          FunkinMemory.purgeCache();
        });
        FlxG.switchState(new StoryMenuCustom());
      }
    });
  }

  /** Un frame del atlas como sprite estático, escalado y centrado en (cx, cy). Empieza oculto. */
  function makeSelectSprite(atlas:Dynamic, prefix:String, cx:Float, cy:Float):FlxSprite
  {
    var spr:FlxSprite = new FlxSprite();
    spr.frames = atlas;
    spr.animation.addByPrefix('f', prefix, 24, false);
    spr.animation.play('f');
    spr.antialiasing = true;
    spr.scrollFactor.set(0, 0);
    spr.cameras = [selectCam];
    spr.scale.set(SELECT_SCALE, SELECT_SCALE);
    spr.updateHitbox();
    spr.x = cx - spr.width / 2;
    spr.y = cy - spr.height / 2;
    spr.alpha = 0;
    spr.visible = false;
    add(spr);
    return spr;
  }

  /**
   * Le dice al módulo StoryMenuStickerRedirect a qué Story vamos: vanilla = true deja que el regreso de una week
   * (ResultState / GameOver / Pause) vuelva al StoryMenuState original; false = lo redirige a StoryMenuCustom (como antes).
   */
  function setStoryRedirect(vanilla:Bool):Void
  {
    var m:Dynamic = ModuleHandler.getModule('storyMenuStickerRedirect');
    if (m != null) m.setUseVanilla(vanilla);
  }

  /** Acción del botón Story (tras su animación "confirm"): abre la selección. `busy` ya está en true desde confirmButton. */
  function openStorySelect():Void
  {
    if (selectOpen) return;

    selectOpen = true;
    selectClosing = false;
    selectChosen = false;
    selectT = 0;
    selectTouchPanel = null;

    selectDim.visible = true;
    for (p in selectPanels)
    {
      p.hovered = false;
      p.basic.visible = true;
      p.white.visible = false;
    }

    applySelectAnim();
  }

  /** Cierra la selección y devuelve el control al menú (BACK / BackButton). */
  function closeStorySelect():Void
  {
    if (!selectOpen || selectClosing || selectChosen) return;

    selectClosing = true;
    selectTouchPanel = null;
    FunkinSound.playOnce(Paths.sound('cancelMenu'));
    Cursor.cursorMode = CursorMode.Default;
  }

  function finishCloseStorySelect():Void
  {
    selectOpen = false;
    selectClosing = false;
    selectT = 0;

    selectDim.visible = false;
    for (p in selectPanels)
    {
      p.hovered = false;
      p.basic.visible = false;
      p.white.visible = false;
    }
    setSelectBlur(0);

    // Devuelve el menú a como estaba: botón Story en reposo y entrada habilitada.
    busy = false;
    if (storyBtn != null)
    {
      storyBtn.hovered = false;
      playBtn(storyBtn, 'idle');
    }
    if (FlxG.onMobile && backButton != null) backButton.enabled = true;
  }

  /** Pone la animación de apertura/cierre según selectT (0..1): capa oscura, deslizamiento + fundido de los bloques y blur. */
  function applySelectAnim():Void
  {
    var e:Float = FlxEase.cubeOut(selectT);

    selectDim.alpha = SELECT_DIM_ALPHA * e;

    for (p in selectPanels)
    {
      var dx:Float = p.slideDir * SELECT_SLIDE * (1 - e);
      p.basic.x = p.bx + dx;
      p.white.x = p.wx + dx;

      // El bloque no elegido se queda atenuado: no se le pisa el alpha una vez elegido.
      if (selectChosen && !p.hovered) continue;
      p.basic.alpha = e;
      p.white.alpha = e;
    }

    setSelectBlur(SELECT_BLUR * e);
  }

  /** Blur del menú de fondo (solo la cámara principal: los bloques van en otra cámara y quedan nítidos). */
  function setSelectBlur(amount:Float):Void
  {
    if (SELECT_BLUR <= 0 || amount < 0.05)
    {
      FlxG.camera.filters = [];
      return;
    }
    FlxG.camera.filters = [new BlurFilter(amount, amount, 1)];
  }

  /** ¿El punto (mx, my) (coordenadas de selectCam) está dentro de la silueta del bloque? Interpola los bordes inclinados. */
  function panelContains(p:Dynamic, mx:Float, my:Float):Bool
  {
    var lx:Float = (mx - p.bx) / SELECT_SCALE;
    var ly:Float = (my - p.by) / SELECT_SCALE;

    if (ly < 0 || ly > SELECT_SHAPE_H) return false;

    var t:Float = ly / SELECT_SHAPE_H;
    var shape:Array<Float> = p.shape;
    var minX:Float = shape[0] + (shape[1] - shape[0]) * t;
    var maxX:Float = shape[2] + (shape[3] - shape[2]) * t;
    return lx >= minX && lx <= maxX;
  }

  /** Hover = se muestra el frame white. */
  function setPanelHover(p:Dynamic, over:Bool, withSound:Bool):Void
  {
    if (p.hovered == over) return;

    p.hovered = over;
    p.basic.visible = !over;
    p.white.visible = over;

    if (over && withSound) FunkinSound.playOnce(Paths.sound('scrollMenu'));
  }

  /** Se eligió un bloque: sonido + el otro se atenúa + (tras SELECT_CONFIRM_WAIT) outro y cambio de state. */
  function confirmStoryPanel(p:Dynamic):Void
  {
    if (selectChosen || selectClosing) return;

    selectChosen = true;
    selectTouchPanel = null;
    Cursor.cursorMode = CursorMode.Default;

    if (FlxG.onMobile && backButton != null) backButton.enabled = false;

    FunkinSound.playOnce(Paths.sound('confirmMenu'));
    setPanelHover(p, true, false);

    for (o in selectPanels)
    {
      if (o == p) continue;
      setPanelHover(o, false, false);
      o.basic.alpha = SELECT_OTHER_ALPHA;
      o.white.alpha = SELECT_OTHER_ALPHA;
    }

    var action:Dynamic = p.onConfirm;
    new FlxTimer().start(SELECT_CONFIRM_WAIT, function(_) {
      playOutro(action);
    });
  }

  function updateStorySelect(elapsed:Float):Void
  {
    if (!selectOpen) return;

    // Apertura / cierre a mano (sin FlxTween).
    var target:Float = selectClosing ? 0.0 : 1.0;
    if (selectT != target)
    {
      var step:Float = Math.min(elapsed, 0.05) / SELECT_ANIM_TIME;
      if (selectT < target) selectT = Math.min(selectT + step, target);
      else selectT = Math.max(selectT - step, target);

      applySelectAnim();

      if (selectClosing && selectT <= 0)
      {
        finishCloseStorySelect();
        return;
      }
    }

    // Sin input mientras se abre/cierra, tras elegir o durante el outro.
    if (selectT < 1 || selectClosing || selectChosen || outroStarted) return;

    // Móvil: BackButton visible y activo mientras la selección está abierta (busy está en true y el update normal no lo toca).
    if (FlxG.onMobile && backButton != null)
    {
      backButton.visible = true;
      backButton.enabled = true;
    }

    if (FlxG.onMobile)
    {
      updateSelectTouch();
      return;
    }

    var p = FlxG.mouse.getWorldPosition(selectCam);
    var mx:Float = p.x;
    var my:Float = p.y;
    p.put();

    var anyOver:Bool = false;
    var clicked:Dynamic = null;

    for (pn in selectPanels)
    {
      var over:Bool = panelContains(pn, mx, my);
      // Solo uno a la vez (la silueta de uno nunca toca la del otro, pero por si se solapan al crecer).
      if (over && anyOver) over = false;
      if (over) anyOver = true;

      setPanelHover(pn, over, true);

      if (over && FlxG.mouse.justPressed) clicked = pn;
    }

    Cursor.cursorMode = anyOver ? CursorMode.Pointer : CursorMode.Default;

    if (clicked != null) confirmStoryPanel(clicked);
  }

  /** (móvil) Apoyar el dedo en un bloque = hover; soltar sobre él = elegir; soltar fuera lo cancela. */
  function updateSelectTouch():Void
  {
    var justPressed:Bool = TouchUtil.justPressed;
    var justReleased:Bool = TouchUtil.justReleased;
    var pressed:Bool = TouchUtil.pressed;

    var t = TouchUtil.touch;
    var over:Bool = false;
    var hit:Dynamic = null;

    if (t != null)
    {
      var p = t.getWorldPosition(selectCam);
      for (pn in selectPanels)
      {
        if (panelContains(pn, p.x, p.y))
        {
          hit = pn;
          break;
        }
      }
      p.put();
    }

    if (justPressed && selectTouchPanel == null && hit != null)
    {
      selectTouchPanel = hit;
      setPanelHover(hit, true, true);
      return;
    }

    if (selectTouchPanel == null) return;

    over = (hit == selectTouchPanel);

    if (justReleased || !pressed)
    {
      var tapped:Dynamic = selectTouchPanel;
      selectTouchPanel = null;

      if (over && justReleased) confirmStoryPanel(tapped);
      else setPanelHover(tapped, false, false);
      return;
    }

    setPanelHover(selectTouchPanel, over, false);
  }

  /**
   * Abre Freeplay igual que el MainMenuState original (como substate encima de este menú).
   * OJO: el FreeplayState de V-Slice, al salir, solo hace close() si su padre es exactamente MainMenuState;
   * con cualquier otro padre hace switchState(new MainMenuState()). Por eso, si al volver cae en el menú
   * original, lo redirigimos a este menú nuevo en cuanto cambie el state.
   */
  function openFreeplay():Void
  {
    persistentDraw = true;
    persistentUpdate = false;

    // Freeplay tiene su propia transición.
    FlxTransitionableState.skipNextTransIn = true;
    FlxTransitionableState.skipNextTransOut = true;

    // CUTOUT_WIDTH es estático: se actualiza antes de cargar Freeplay (igual que el menú original).
    FreeplayState.CUTOUT_WIDTH = FullScreenScaleMode.gameCutoutSize.x / 1.5;


    // La cámara de las barras se dibuja encima de todo, incluido el substate de Freeplay: la ocultamos.
    if (introCam != null) introCam.visible = false;

    #if mobile
    // (móvil) el BackButton vive en otra cámara que también se dibuja encima de Freeplay.
    if (backButton != null) backButton.visible = false;
    #end

    openSubState(new FreeplayState({
      character: FreeplayState.rememberedCharacterId
    }));
  }

  /**
   * Botón bloqueado: se dibuja el botón en reposo oscurecido + el candado animado encima, centrado.
   * El oscurecido NO es un rectángulo: se tiñe el propio sprite del botón (color gris al 50%), así que
   * conserva exactamente su forma (bordes, esquinas, transparencias). Visualmente equivale a un negro
   * con alpha LOCK_DIM_ALPHA justo encima del botón, pero solo sobre sus píxeles.
   * No hace hover ni confirm; al hacer click suena 'cancelMenu' y el candado tiembla un momento.
   */
  function addLockedButton(id:String, label:String, x:Float, y:Float, bounds:Array<Float>):Dynamic
  {
    var btn:Dynamic = addMenuButton(id, label, x, y, bounds, null);
    btn.locked = true;

    var w:Float = btn.right - btn.left;
    var h:Float = btn.bottom - btn.top;

    // Render a textura: el atlas se compone entero y luego se tiñe de una sola vez (sin costuras entre capas).
    btn.sprite.useRenderTexture = true;
    var v:Int = Std.int(255 * (1 - LOCK_DIM_ALPHA));
    btn.sprite.color = 0xFF000000 | (v << 16) | (v << 8) | v;

    // Candado (Sparrow, 17 frames "buttons lock0000"...) en loop.
    var lock:FlxSprite = new FlxSprite();
    lock.frames = Paths.getSparrowAtlas(LOCK_ATLAS);
    lock.animation.addByPrefix('idle', 'buttons lock', LOCK_FPS, true);
    lock.animation.play('idle');
    lock.antialiasing = true;
    lock.scrollFactor.set(PARALLAX_PANEL, PARALLAX_PANEL);
    lock.scale.set(BTN_SCALE, BTN_SCALE);
    lock.updateHitbox();
    lock.x = btn.left + (w - lock.width) / 2;
    lock.y = btn.top + (h - lock.height) / 2;
    add(lock);

    btn.lock = lock;
    btn.lockBaseX = lock.x;
    btn.shake = 0.0;
    return btn;
  }

  /**
   * Un botón del atlas. Etiquetas usadas (ver Animation.json): "basic <label>", "white <label>", "confirm <label>".
   *  - basic   = reposo (loop)
   *  - white   = "select": mouse encima (loop)
   *  - confirm = click (una sola vez)
   */
  function addMenuButton(id:String, label:String, x:Float, y:Float, bounds:Array<Float>, onConfirm:Dynamic):Dynamic
  {
    // Recentra según BTN_SCALE (el layout está medido a escala 1.0) y aplica el desplazamiento global.
    // wideShiftX: en pantallas anchas el panel (anclado a la derecha) se corre, y los botones con él.
    x = x + (bounds[2] - bounds[0]) * (1 - BTN_SCALE) / 2 + BTN_SHIFT_X + wideShiftX;
    y = y + (bounds[3] - bounds[1]) * (1 - BTN_SCALE) / 2 + BTN_SHIFT_Y;

    // applyStageMatrix: el sprite se dibuja con las posiciones originales del stage de Animate (0,0 = esquina del sprite).
    var sprite:FunkinSprite = new FunkinSprite(0, 0);
    sprite.loadTextureAtlas(BTN_ATLAS, null, {swfMode: true, applyStageMatrix: true});

    sprite.anim.addByFrameLabel(id + '_idle', 'basic ' + label, BTN_FPS, true);
    sprite.anim.addByFrameLabel(id + '_select', 'white ' + label, BTN_FPS, true);
    sprite.anim.addByFrameLabel(id + '_confirm', 'confirm ' + label, BTN_FPS, false);
    sprite.anim.play(id + '_idle', true);

    sprite.antialiasing = true;
    sprite.scrollFactor.set(PARALLAX_PANEL, PARALLAX_PANEL); // se mueve junto al panel
    sprite.scale.set(BTN_SCALE, BTN_SCALE);
    sprite.origin.set(0, 0); // escala desde la esquina, así: pantalla = posición + escala * punto del stage
    sprite.x = x - bounds[0] * BTN_SCALE;
    sprite.y = y - bounds[1] * BTN_SCALE;
    add(sprite);

    var btn:Dynamic = {
      id: id,
      sprite: sprite,
      left: x,
      top: y,
      right: x + (bounds[2] - bounds[0]) * BTN_SCALE,
      bottom: y + (bounds[3] - bounds[1]) * BTN_SCALE,
      hovered: false,
      locked: false,
      shake: 0.0,
      outro: true, // false = al confirmar no hace el outro (Freeplay)
      onConfirm: onConfirm
    };
    buttons.push(btn);
    return btn;
  }

  /** ¿Está el mouse sobre la caja del botón? Compensa el scroll (parallax) y el zoom (bop) de la cámara. */
  function isMouseOver(btn:Dynamic):Bool
  {
    var p = FlxG.mouse.getWorldPosition(FlxG.camera);
    // getWorldPosition asume scrollFactor 1; los botones usan PARALLAX_PANEL.
    var mx:Float = p.x + FlxG.camera.scroll.x * (PARALLAX_PANEL - 1);
    var my:Float = p.y + FlxG.camera.scroll.y * (PARALLAX_PANEL - 1);
    p.put();
    return mx >= btn.left && mx <= btn.right && my >= btn.top && my <= btn.bottom;
  }

  /** Hover (select) y click (confirm) de todos los botones. */
  function updateButtons(elapsed:Float):Void
  {
    // Durante la intro la cámara está rotada: el cálculo del mouse no sería válido, así que no hay hover/click.
    if (busy || introPlaying) return;

    // Móvil: el mouse no existe, se usan los toques (el flujo de PC de abajo queda intacto).
    if (FlxG.onMobile)
    {
      updateButtonsTouch(elapsed);
      return;
    }

    var anyHovered:Bool = false;

    for (btn in buttons)
    {
      var over:Bool = isMouseOver(btn);

      if (btn.locked)
      {
        // Bloqueado: sin hover ni confirm. Click = sonido de error + temblor del candado.
        if (over && FlxG.mouse.justPressed)
        {
          FunkinSound.playOnce(Paths.sound('cancelMenu'));
          btn.shake = 0.3;
        }
        if (btn.shake > 0)
        {
          btn.shake -= elapsed;
          btn.lock.x = btn.lockBaseX + (btn.shake > 0 ? Math.sin(btn.shake * 70) * 6 * (btn.shake / 0.3) : 0);
        }
        continue;
      }

      if (over) anyHovered = true;

      if (over && !btn.hovered)
      {
        btn.hovered = true;
        playBtn(btn, 'select');
        FunkinSound.playOnce(Paths.sound('scrollMenu'));
      }
      else if (!over && btn.hovered)
      {
        btn.hovered = false;
        playBtn(btn, 'idle');
      }

      if (over && FlxG.mouse.justPressed) confirmButton(btn);
    }

    Cursor.cursorMode = anyHovered ? CursorMode.Pointer : CursorMode.Default;
  }

  /** (móvil) ¿Está el dedo sobre la caja del botón? Misma compensación de scroll/zoom que isMouseOver. */
  function isTouchOver(btn:Dynamic):Bool
  {
    var t = TouchUtil.touch;
    if (t == null) return false;

    var p = t.getWorldPosition(FlxG.camera);
    var mx:Float = p.x + FlxG.camera.scroll.x * (PARALLAX_PANEL - 1);
    var my:Float = p.y + FlxG.camera.scroll.y * (PARALLAX_PANEL - 1);
    p.put();
    return mx >= btn.left && mx <= btn.right && my >= btn.top && my <= btn.bottom;
  }

  /**
   * (móvil) Equivalente táctil de updateButtons:
   *  - apoyar el dedo en un botón  = select (animación blanca + sonido), igual que el hover del mouse
   *  - mover el dedo fuera         = vuelve a idle; si regresa, vuelve a select
   *  - soltar sobre el botón       = confirm; soltar fuera lo cancela
   *  - botón bloqueado             = sonido de error + temblor del candado al tocarlo
   */
  function updateButtonsTouch(elapsed:Float):Void
  {
    var justPressed:Bool = TouchUtil.justPressed;
    var justReleased:Bool = TouchUtil.justReleased;
    var pressed:Bool = TouchUtil.pressed;

    for (btn in buttons)
    {
      if (!btn.locked) continue;

      if (justPressed && isTouchOver(btn))
      {
        FunkinSound.playOnce(Paths.sound('cancelMenu'));
        btn.shake = 0.3;
      }
      if (btn.shake > 0)
      {
        btn.shake -= elapsed;
        btn.lock.x = btn.lockBaseX + (btn.shake > 0 ? Math.sin(btn.shake * 70) * 6 * (btn.shake / 0.3) : 0);
      }
    }

    // Nuevo toque: ¿sobre qué botón (no bloqueado) cayó?
    if (justPressed && touchBtn == null)
    {
      for (btn in buttons)
      {
        if (btn.locked || !isTouchOver(btn)) continue;

        touchBtn = btn;
        btn.hovered = true;
        playBtn(btn, 'select');
        FunkinSound.playOnce(Paths.sound('scrollMenu'));
        break;
      }
    }

    if (touchBtn == null) return;

    var over:Bool = isTouchOver(touchBtn);

    if (justReleased || !pressed)
    {
      var tapped:Dynamic = touchBtn;
      touchBtn = null;

      if (over && justReleased)
      {
        confirmButton(tapped);
      }
      else
      {
        tapped.hovered = false;
        playBtn(tapped, 'idle');
      }
      return;
    }

    // Dedo todavía apoyado: sigue el select mientras esté encima del botón.
    if (over && !touchBtn.hovered)
    {
      touchBtn.hovered = true;
      playBtn(touchBtn, 'select');
    }
    else if (!over && touchBtn.hovered)
    {
      touchBtn.hovered = false;
      playBtn(touchBtn, 'idle');
    }
  }

  function confirmButton(btn:Dynamic):Void
  {
    // OST no cambia de state: solo abre la fila de redes (no bloquea el menú).
    if (btn.isOst == true)
    {
      pressOst(btn);
      return;
    }

    busy = true;

    // Móvil: el BackButton ya no responde mientras se ve la animación de confirm.
    if (FlxG.onMobile && backButton != null)
    {
      backButton.enabled = false;
    }
    FunkinSound.playOnce(Paths.sound('confirmMenu'));
    playBtn(btn, 'confirm');

    var action:Dynamic = btn.onConfirm;
    var useOutro:Bool = btn.outro != false;
    new FlxTimer().start(BTN_CONFIRM_WAIT, function(_) {
      // Tras la animación "confirm": outro y, cuando termina, la acción del botón (cambio de state).
      if (useOutro) playOutro(action);
      else action();
    });
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    Conductor.instance.update();

    var music = FlxG.sound.music;
    if (waveform != null && music != null)
    {
      waveform.time = music.time / 1000;
    }

    updateIntro(elapsed);
    updateOutro(elapsed);
    debugRedirect();

    // El bop vuelve suavemente a 0 entre beats; el zoom final combina bop + intro/outro.
    bopAdd = bopAdd * Math.exp(-BOP_DECAY * elapsed);
    FlxG.camera.zoom = (1.0 + bopAdd) * transZoom;

    // La cámara de la selección sigue el giro/zoom del outro (sin el bop) para que los bloques salgan igual que el resto.
    if (selectOpen && selectCam != null)
    {
      selectCam.angle = FlxG.camera.angle;
      selectCam.zoom = transZoom;
    }

    // (móvil) el BackButton no se muestra ni responde mientras corre la intro.
    if (FlxG.onMobile && backButton != null && !busy)
    {
      backButton.visible = !introPlaying;
      backButton.enabled = !introPlaying;
    }

    updateParallax(elapsed);
    updateButtons(elapsed);
    updateOst(elapsed);
    updateSocial(elapsed);
    updateSocialClicks(elapsed);
    updateStorySelect(elapsed);

    particleTime += elapsed;
    for (e in emitters) updateEmitter(e, elapsed);

    if (!busy && !introPlaying && !outroStarted && PlayerSettings.player1.controls.BACK_P) goBack();
    // Con la selección de modo abierta, BACK la cierra (busy está en true, por eso va aparte).
    else if (selectOpen && !selectClosing && !selectChosen && !outroStarted && PlayerSettings.player1.controls.BACK_P) closeStorySelect();
  }

  function goBack():Void
  {
    // Con la selección de modo abierta, BACK / BackButton solo la cierra (no sale al título).
    if (selectOpen)
    {
      closeStorySelect();
      return;
    }

    if (outroStarted) return; // ya se está saliendo

    FunkinSound.playOnce(Paths.sound('cancelMenu'));
    // Este menú YA es el principal: BACK vuelve al título (igual que el menú original).
    // (Ir a MainMenuState aquí haría que el módulo nos redirija de vuelta a este mismo menú.)
    // Primero el outro; al terminar se cambia de state.
    playOutro(function() {
      Cursor.hide();
      FlxG.switchState(new NewTitleState());
    });
  }
}
