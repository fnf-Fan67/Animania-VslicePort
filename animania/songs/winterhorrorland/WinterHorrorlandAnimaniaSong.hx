package animania.songs.winterhorrorland;

class WinterHorrorlandAnimaniaSong extends Song
{

  var SKIP_COUNTDOWN:Bool = true;

  var OPPONENT_NOTE_DRAIN:Float = 0.0075;
  var OPPONENT_HOLD_DRAIN:Float = 0.05;

  var PLAYER_STRUM_SCALE:Float = 0.95;
  var CENTER_PLAYER_STRUMLINE:Bool = false;

  var HINT_CONTROL:String = "SPACE";

  var INTRO_LENGTH:Float = 7.8;

  var SNOW_ENABLED:Bool = true;
  var SNOW_ZINDEX:Int = 395;
  var SNOW_ZOOM_FACTOR:Float = 0.9;
  var SNOW_LAYERS:Int = 30;
  var SNOW_DEPTH:Float = 0.3;
  var SNOW_BASE_WIDTH:Float = 0.2;
  var SNOW_BASE_SPEED:Float = 0.6;
  var SNOW_BASE_ALPHA:Float = 0.55;
  var SNOW_BASE_COLOR = 0xFFDEADB9;
  var SNOW_RED_COLOR = 0xFFEB6083;

  var ps = null;

  var chromShader = null;
  var chromTween = null;
  var chromaValue:Float = 0;

  var barUp = null;
  var barDown = null;
  var barTween = null;
  var barVis:Float = 160;
  var barW:Float = 1;
  var barH:Float = 1;
  var barBaseScaleX:Float = 1;
  var barBaseScaleY:Float = 1;

  var darkLight = null;
  var blend2 = null;
  var snowman = null;
  var darkLightBaseAlpha:Float = 0;
  var snowmanBaseX:Float = 0;

  var hudStrumY:Float = 0;
  var hudBarY:Float = 0;
  var hudBarBgY:Float = 0;
  var hudScoreY:Float = 0;

  var snowShader = null;
  var snowSpr = null;
  var snowTime:Float = 0;
  var snowTimeSpeed:Float = 1;
  var snowWidth:Float = 0.2;
  var snowBaseScaleX:Float = 1;
  var snowBaseScaleY:Float = 1;
  var snowSpeedTween = null;
  var snowAlphaTween = null;
  var snowWidthTween = null;

  var hintText = null;
  var introBlack = null;
  var cutsceneSound = null;
  var cutsceneBf = null;

  var ass = [];
  var timers = [];

  var seenCutscene:Bool = false;
  var playedCutscene:Bool = false;
  var allowEnd:Bool = false;

  // ---------------------------------------------------------------------------
  // BATTLE MECHANIC (dodge / attack QTE) - ported from battle-mechanic.script
  // Solo se activa en dificultad "hard", igual que el script original.
  // ---------------------------------------------------------------------------
  var MECH_DIFFICULTY:String = "hard";
  var MECH_FINAL_PRE_WINDOW:Float = 0.65;
  var MECH_FINAL_POST_WINDOW:Float = 0.5;
  var MECH_DOT_SPEED:Float = 1.0;
  var MECH_DOT_OFFSET:Float = 180;
  var MECH_DOT_Z:Int = 1650;
  var MECH_STRIPE_Z:Int = 1750;
  var MECH_ICON_FOCUS_MULT:Float = 1.0;
  var MECH_ICON_NORMAL_SIZE:Float = 150;
  var MECH_SUCK_COLOR = 0xFF362B4D;
  var MECH_SUCK_Z:Int = 803;
  var MECH_CAM_ZOOM:Float = 1.4;
  var MECH_CAM_OFFSET_X:Float = 200;
  var MECH_CAM_OFFSET_Y:Float = 200;

  var mechActive:Bool = false;
  var mechMode:String = "dodge";
  var mechTentacleSide:String = "Left";

  var mechIsEventActive:Bool = false;
  var mechEventBeats:Int = 0;
  var mechEventStartBeat:Float = 0;
  var mechCanHitFinal:Bool = false;
  var mechTargetFinalBeat:Float = 0;
  var mechSemiBeatHits:Int = -1;
  var mechHealthSucked:Float = 0;

  var mechSplash = null;
  var mechCross = null;
  var mechHint = null;
  var mechSuckBar = null;
  var mechCrossTween = null;
  var mechDots = [];
  var mechStripes = [];
  var mechSnowmanAlpha:Float = 1;

  // Icono del evento en curso (null fuera de un evento). Los iconos que la mecanica tiene "tomados" viven en mechIcons.
  var mechFocusIcon = null;
  var mechIcons = [];
  var MECH_ICON_TRAVEL:Float = 9 / 24;   // segundos que tarda un icono en ir a la mira (o volver a casa)
  var MECH_ICON_BOP:Float = 0.2;
  // Ajuste fino (px) si el arte de FIGHTING_UI no está centrado en su frame. 0 = centro exacto del frame.
  var MECH_ICON_CROSS_OFFSET_X:Float = 0;
  var MECH_ICON_CROSS_OFFSET_Y:Float = 0;

  // ---------------------------------------------------------------------------
  // MOBILE: zona de toque dedicada para esquivar / atacar.
  // Es una "dead zone" del hitbox de V-Slice (igual que el boton de pausa): un toque dentro de ella NO pulsa ningun
  // carril ni nota, asi que tocar la mira ya no genera ghost-miss. Solo existe mientras dura el evento.
  // ---------------------------------------------------------------------------
  var MECH_MOBILE_BUTTON:Bool = true;
  var MECH_BTN_ZONE_MULT:Float = 1.6;      // area tocable = tamano de la mira * esto
  var MECH_BTN_MIN_SIZE:Float = 0.26;      // minimo, como fraccion del alto de pantalla
  var MECH_BTN_MAX_SIZE:Float = 0.45;      // maximo, para no comerse demasiados carriles
  var MECH_BTN_OFFSET_X:Float = 0;         // mover la zona respecto a la mira (px)
  var MECH_BTN_OFFSET_Y:Float = 0;
  var MECH_MOBILE_POST_BONUS:Float = 0.2;  // beats extra de margen "tarde" en celular (latencia del pulgar)
  var MECH_MOBILE_CROSS_ALPHA:Float = 0.85;
  var mechBtnZone = null;

  // La cruceta (mira + zona de toque) se coloca en un lugar comodo para el pulgar, fuera de los carriles.
  // Lado: Save.instance.modOptions["mechSide"] = "Right" (default) | "Left" | "Center".
  var MECH_MOBILE_ANCHOR_X:Float = 0.88;   // centro de la mira, fraccion del ancho (se invierte si el lado es Left)
  var MECH_MOBILE_ANCHOR_Y:Float = 0.5;    // centro de la mira, fraccion del alto

  var mechCamLocked:Bool = false;
  var mechCamX:Float = 0;
  var mechCamY:Float = 0;
  var mechCamZoom:Float = 1;
  var mechSavedX:Float = 0;
  var mechSavedY:Float = 0;
  var mechSavedZoom:Float = 1;

  public function new()
  {
    super('winter-horrorland-animania');
  }

  override function onCreate(event:ScriptEvent):Void
  {
    super.onCreate(event);

    ps = PlayState.instance;
    if (ps == null) return;

    mechanicInit();

	if (Save.instance.modOptions['shaders'])
	{
		createSnow();
		resetRuntimeState();
		setupChroma();
	}
    styleSubtitles();
    setIntroCamera();

    ps.opponentStrumline.x -= FlxG.width / 1.5;
    ps.opponentStrumline.alpha = 0;

    darkLight = getProp("darkLight");
    blend2 = getProp("blend2");
    snowman = getProp("snowman");
    if (darkLight != null) darkLightBaseAlpha = darkLight.alpha;
    if (snowman != null) snowmanBaseX = snowman.x;

    if (ps.isChartingMode)
    {
      if (darkLight != null) darkLight.alpha = 0;
      return;
    }

    if (blend2 != null) blend2.alpha = .25;
    ps.camHUD.alpha = 0;

    applyPlayerStrumlineMode();
    storeHudBase();
    createBars();
    createHint();

    FunkinMemory.cacheSound(Paths.sound("songs/lemon-intro"));
    FunkinMemory.cacheTexture(Paths.image("stages/xMassCityMallNasty/ha"));
  }

  override function onDestroy(event:ScriptEvent):Void
  {
    super.onDestroy(event);
    ps = null;
  }

  override function onGameOver(event:ScriptEvent):Void
  {
    super.onGameOver(event);
    if (ps == null) return;
    ps.camGame.filters = [];
  }

  override function onSongRetry(event:SongRetryEvent):Void
  {
    super.onSongRetry(event);
    if (ps == null) return;

    allowEnd = false;
    cancelTimers();
    mechanicReset();
	if (Save.instance.modOptions['shaders'])
	{
		chromaEffect(0, 0, null);
		applyChromaFilter();
	    resetSnow();
	}
    setIntroCamera();

    if (ps.isChartingMode) return;

    FlxTween.cancelTweensOf(ps.camHUD);
    ps.camHUD.alpha = 0;

    FlxTween.cancelTweensOf(ps.playerStrumline);
    ps.playerStrumline.y = hudStrumY;
    ps.playerStrumline.alpha = 1;

    FlxTween.cancelTweensOf(ps.healthBar);
    FlxTween.cancelTweensOf(ps.healthBarBG);
    ps.healthBar.y = hudBarY;
    ps.healthBarBG.y = hudBarBgY;
    var st = getScoreText();
    if (st != null)
    {
      FlxTween.cancelTweensOf(st);
      st.y = hudScoreY;
    }

    if (barTween != null) barTween.cancel();
    barTween = null;
    barVis = 160;

    if (darkLight != null)
    {
      FlxTween.cancelTweensOf(darkLight);
      darkLight.alpha = darkLightBaseAlpha;
    }
    if (blend2 != null)
    {
      FlxTween.cancelTweensOf(blend2);
      blend2.alpha = .25;
    }
    if (snowman != null) snowman.x = snowmanBaseX;

    if (hintText != null)
    {
      FlxTween.cancelTweensOf(hintText);
      hintText.alpha = 0;
      hintText.scale.set(1, 1);
    }

    var i = 0;
    while (i < ass.length)
    {
      var ha = ass[i];
      i = i + 1;
      if (ha != null)
      {
        FlxTween.cancelTweensOf(ha);
        ps.currentStage.remove(ha);
        ha.kill();
        ha.destroy();
      }
    }
    ass = [];

    introBlack = makeBlack();
  }

  override function onUpdate(event:UpdateScriptEvent):Void
  {
    super.onUpdate(event);
    if (ps == null) return;

    layoutBars();
    updateSnow(event.elapsed);
    drainOnOpponentHolds(event.elapsed);
    mechanicUpdate(event.elapsed);
  }

  override function onCountdownStart(event:CountdownScriptEvent):Void
  {
    super.onCountdownStart(event);
    if (ps == null) return;

    var charting = ps.isChartingMode;

    if (!playedCutscene && !charting && !seenCutscene)
    {
      playedCutscene = true;
      event.cancel();
      startCutscene();
      return;
    }

    if (seenCutscene)
    {
      ps.tweenCameraZoom(1.6, 0, false);

      var black = introBlack;
      if (black == null) black = makeBlack();
      introBlack = null;
      fadeOutBlack(black, 1.8, FlxEase.backOut);
      ps.refresh();
    }

    seenCutscene = true;
    ps.isInCutscene = false;
    chromaEffect(.05, 2, "sineInOut");

    FlxTimer.wait(0, () -> Countdown.skipCountdown());
  }

  function startCutscene()
  {
    ps.isInCutscene = true;
    chromaEffect(.1, 0, "sineOut");

    var black = makeBlack();
    moveBars(60, 0, null, 0);

    var bf = ps.currentStage.getBoyfriend();
    var dad = ps.currentStage.getDad();

    cutsceneSound = FunkinSound.load(Paths.sound("songs/lemon-intro"), 1, false, true, false);

    cutsceneBf = new FunkinSprite(bf.x + 592, bf.y + 208, Paths.animateAtlas("stages/xMassCityMallNasty/intro-cutscene", "shared"), {useRenderTexture: true});
    cutsceneBf.zIndex = bf.zIndex + 15;
    bf.visible = false;
    cutsceneBf.animation.onFinish.add(function(name)
    {
      cutsceneBf.visible = false;
      bf.visible = true;
    });

    var colorShader = new AdjustColorShader();
    colorShader.hue = -10;
    colorShader.saturation = -20;
    colorShader.contrast = 0;
    colorShader.brightness = 0;
    cutsceneBf.shader = colorShader;
    ps.currentStage.add(cutsceneBf);

    if (snowman != null) snowman.x = snowmanBaseX + 350;
    ps.currentStage.refresh();
    ps.refresh();

    later(.15, function(_)
    {
      if (cutsceneSound != null) cutsceneSound.play(true);
      cutsceneBf.animation.play("spritemap", true);
      fadeOutBlack(black, .5, FlxEase.sineOut);

      ps.tweenCameraZoom(2, 0, false);
      ps.tweenCameraZoom(1.8, .75, false, FlxEase.cubeOut);
    });

    later(.15 + 33 / 24, function(_)
    {
      ps.tweenCameraZoom(1.7, 13 / 24, false, FlxEase.quadInOut);
      ps.tweenCameraToPosition(ps.cameraFollowPoint.x + 120, ps.cameraFollowPoint.y - 50, 13 / 24, FlxEase.quadInOut);
      chromaEffect(0, .15, "sineOut");
      moveBars(85, 1.1, FlxEase.backOut, 0);
    });

    later(.15 + 90 / 24, function(_)
    {
      ps.tweenCameraZoom(.9, 26 / 24, false, FlxEase.quadInOut);
      ps.tweenCameraToPosition(-250, -500, 26 / 24, FlxEase.quadInOut);
      moveBars(35, 1.1, FlxEase.backOut, 0);
    });

    later(.15 + 97 / 24, function(_)
    {
      moveBars(80, .35, FlxEase.backOut, .6);
      if (dad != null)
      {
        dad.playAnimation("trans");
        dad.animation.onFinish.addOnce(function(name)
        {
          dad.playAnimation("singRIGHT-alt");
          ps.tweenCameraZoom(1.1, .35, false, FlxEase.backOut);
          moveBars(80, .35, FlxEase.backOut, .6);
        });
      }
    });

    later(.15 + 114 / 24, function(_)
    {
      chromaEffect(.25, .15, "sineOut");
      ps.camGame.shake(0.0025, 15 / 25);
      if (darkLight != null)
      {
        darkLight.alpha = .5;
        FlxTween.tween(darkLight, {alpha: .6}, 24 / 24, {ease: FlxEase.bounceIn});
        FlxTween.tween(darkLight, {alpha: .9}, 25 / 24, {startDelay: 1, ease: FlxEase.quadOut});
      }
      later(1, function(_)
      {
        chromaEffect(0.05, 1, "cubeOut");
      });
    });

    later(INTRO_LENGTH, function(_)
    {
      ps.startCountdown();
    });
  }

  override function onSongStart(event:ScriptEvent):Void
  {
    super.onSongStart(event);
    FlxG.sound.music.volume = 0;
    FlxG.sound.music.fadeOut(1, 1);
  }

  override function onSongEnd(event:ScriptEvent):Void
  {
    super.onSongEnd(event);
    if (ps == null) return;

    if (!allowEnd)
    {
      allowEnd = true;
      event.cancel();
      later(1, function(_)
      {
        ps.endSong();
      });
    }
  }

  override function onSongEvent(event:SongEventScriptEvent):Void
  {
    super.onSongEvent(event);

    var data = event.eventData;
    if (data == null) return;

    // Mientras la cámara está bloqueada por un "dodge", ignorar los focus/zoom del chart.
    if (mechCamLocked && (data.eventKind == "FocusCamera" || data.eventKind == "ZoomCamera"))
    {
      event.cancelEvent();
      return;
    }

    if (data.eventKind != "Blank") return;

    var v1 = data.getString("value1");
    if (v1 == null) return;
    var kind = v1.toLowerCase();

    if (kind == "chroma")
    {
      var strength = data.getFloat("value2");
      var time = data.getFloat("value3");
      if (strength == null) strength = 0;
      if (time == null) time = 0;
      chromaEffect(strength, time, data.getString("value4"));
    }
    else if (kind == "dodge" || kind == "attack")
    {
      var beats = data.getInt("value2");
      if (beats == null) beats = 1;
      mechanicTrigger(kind == "dodge", beats + 1, kind == "dodge" && data.getString("value3") == "yah");
    }
  }

  override function onNoteHit(event:HitNoteScriptEvent):Void
  {
    super.onNoteHit(event);
    if (ps == null || event.note == null || event.note.noteData == null) return;

    if (Math.floor(event.note.noteData.data / 4) != 1) return;

    if (ps.health > .1) ps.health = ps.health - OPPONENT_NOTE_DRAIN;
  }

  function drainOnOpponentHolds(elapsed)
  {
    if (ps.isInCutscene || ps.opponentStrumline == null) return;

    var members = ps.opponentStrumline.holdNotes.members;
    var i = 0;
    while (i < members.length)
    {
      var h = members[i];
      i = i + 1;
      if (h == null || !h.alive) continue;

      if (h.hitNote && !h.missedNote && h.sustainLength > 0 && ps.health > .1)
      {
        ps.health = ps.health - OPPONENT_HOLD_DRAIN * elapsed;
      }
    }
  }

  override function onBeatHit(event:SongTimeScriptEvent):Void
  {
    super.onBeatHit(event);
    if (ps == null) return;

    snowBeat(event.beat);
    mechanicBeat();

    if (ps.isChartingMode) return;

    var beat = event.beat;

    if (beat == 8)
    {
      chromaEffect(.35, 0, "sineOut");
      chromaEffect(.15, 41 / 24, "cubeOut");

      if (darkLight != null)
      {
        darkLight.alpha = .4;
        FlxTween.tween(darkLight, {alpha: .7}, 41 / 24, {ease: FlxEase.cubeOut});
      }
      if (blend2 != null)
      {
        blend2.alpha = 1;
        FlxTween.tween(blend2, {alpha: .6}, 41 / 24, {ease: FlxEase.cubeOut});
      }

      moveBars(110, 1.1, FlxEase.backOut, 0);

      if (snowman != null) snowman.x = snowmanBaseX;

      if (hintText != null && hintText.visible)
      {
        FlxTween.tween(hintText, {"scale.x": 1.1, "scale.y": 1.1, alpha: 1}, 1.25, {ease: FlxEase.cubeOut});
      }
    }
    else if (beat == 16)
    {
      if (hintText != null && hintText.visible)
      {
        FlxTween.tween(hintText, {"scale.x": 0.9, "scale.y": 0.9, alpha: 0}, 2.25, {ease: FlxEase.sineIn});
      }
    }
    else if (beat == 22)
    {
      tweenAlpha(darkLight, .85, 15 / 24, FlxEase.linear);
      FlxTween.tween(ps.camHUD, {alpha: 1}, 1.25, {ease: FlxEase.backOut});
      hudIntro();
      chromaEffect(.075, 3, "sineOut");
    }
    else if (beat == 24)
    {
      moveBars(-190, 1.1, FlxEase.backOut, 0);
    }
    else if (beat == 40)
    {
      tweenAlpha(darkLight, 1, 25 / 24, FlxEase.quadInOut);
    }
    else if (beat == 56)
    {
      tweenAlpha(darkLight, .6, 30 / 24, FlxEase.quadInOut);
    }
    else if (beat == 72)
    {
      tweenAlpha(darkLight, 1, 56 / 24, FlxEase.linear);
    }
    else if (beat == 84)
    {
      tweenAlpha(darkLight, 0, 12 / 24, FlxEase.cubeOut);
      createHahaha(-800, -800);
    }
    else if (beat == 85)
    {
      createHahaha(-1150, -665);
    }
    else if (beat == 86)
    {
      createHahaha(-1350, -1115);
    }
    else if (beat == 87)
    {
      createHahaha(-850, -1150);
    }
    else if (beat == 88)
    {
      if (blend2 != null)
      {
        blend2.alpha = 1;
        FlxTween.tween(blend2, {alpha: .7}, 18 / 24, {ease: FlxEase.cubeOut});
      }

      var i = 0;
      while (i < ass.length)
      {
        fadeHahaha(ass[i]);
        i = i + 1;
      }
      ass = [];
    }
    else if (beat == 386)
    {
      var screen = makeBlack();
      screen.alpha = 0;
      FlxTween.tween(screen, {alpha: 1}, 1.5, {ease: FlxEase.sineOut});
    }
  }

  override function onStepHit(event:SongTimeScriptEvent):Void
  {
    super.onStepHit(event);
    if (ps == null || !mechActive) return;

    if (!mechIsEventActive || mechFocusIcon == null || mechCross == null) return;

    if (event.step % 4 == 2 && mechSemiBeatHits > 0)
    {
      var snd = FunkinSound.playOnce(Paths.sound('mechanics/cowbell'));
      if (snd != null) snd.pitch = 1.25;

      if (mechMode == "dodge") mechTentacleTick();
      mechSemiBeatHits = mechSemiBeatHits - 1;
    }
  }

  // ---------------------------------------------------------------------------
  // BATTLE MECHANIC
  // ---------------------------------------------------------------------------

  function mechanicClearRefs()
  {
    mechSplash = null;
    mechCross = null;
    mechHint = null;
    mechSuckBar = null;
    mechCrossTween = null;
    mechBtnZone = null;
    mechDots = [];
    mechStripes = [];
    mechFocusIcon = null;
    mechIcons = [];
    mechIsEventActive = false;
    mechCanHitFinal = false;
    mechCamLocked = false;
    mechSemiBeatHits = -1;
    mechTentacleSide = "Left";
    mechHealthSucked = 0;
    mechSnowmanAlpha = 1;
    mechBarModule = null;
  }

  function mechanicInit()
  {
    mechanicClearRefs();

    mechActive = (ps.currentDifficulty == MECH_DIFFICULTY);
    if (!mechActive) return;

    var sn = getProp("snowman");
    if (sn != null) mechSnowmanAlpha = sn.alpha;

    var dad = ps.currentStage.getDad();
    if (dad != null) dad.ignoreExclusionPref = ["hit"];

    mechHealthSucked = 1;
    createMechanicUI();
  }

  function createMechanicUI()
  {
    var down = AmScroll.isDown();

    mechSplash = new FunkinSprite();
    mechSplash.cameras = [ps.camHUD];
    mechSplash.zIndex = 1700;
    mechSplash.frames = Paths.getSparrowAtlas("mechanincs/fighting_splash");
    mechSplash.animation.addByPrefix("y", "splash", 24, false);
    mechSplash.animation.play("y", true);
    mechSplash.screenCenter(0x01);
    mechSplash.x -= 5;
    mechSplash.y = down ? 0 : FlxG.height * 0.65;
    mechSplash.animation.onFinish.add(function(name)
    {
      mechSplash.visible = false;
    });
    mechSplash.visible = false;
    ps.add(mechSplash);

    mechHint = new FlxText(0, 0, ps.playerStrumline.width, "3", 48);
    mechHint.scrollFactor.set();
    mechHint.cameras = [ps.camHUD];
    mechHint.zIndex = 9999;
    mechHint.font = Paths.font("Blueprint.ttf");
    mechHint.alignment = "center";
    mechHint.y = down ? 550 : 150;
    mechHint.x = ps.playerStrumline.x;
    mechHint.alpha = 0;
    ps.add(mechHint);

    mechCross = new FunkinSprite();
    mechCross.cameras = [ps.camHUD];
    mechCross.zIndex = 2000;
    mechCross.loadGraphic(Paths.image("mechanincs/FIGHTING_UI"));
    mechCross.x = mechSplash.x + 35;
    mechCross.y = mechSplash.y + 35;
    mechCross.alpha = 0;
    ps.add(mechCross);

    mechPlaceMobile();

    ps.refresh();
  }

  // ---- MOBILE: posicion de la cruceta ----

  function mechSide():String
  {
    var side = "Right";
    try
    {
      var v = Save.instance.modOptions["mechSide"];
      if (v != null) side = Std.string(v);
    }
    catch (e:Dynamic) {}
    return side;
  }

  // Mueve mira + splash a un lado de la pantalla, a media altura: lejos de los carriles y facil de alcanzar con el pulgar.
  function mechPlaceMobile()
  {
    #if mobile
    if (!MECH_MOBILE_BUTTON || mechCross == null || mechSplash == null) return;

    var side = mechSide();
    var fx = MECH_MOBILE_ANCHOR_X;
    if (side == "Left") fx = 1 - MECH_MOBILE_ANCHOR_X;
    else if (side == "Center") fx = 0.5;

    var dx = FlxG.width * fx - (mechCross.x + mechCross.width / 2);
    var dy = FlxG.height * MECH_MOBILE_ANCHOR_Y - (mechCross.y + mechCross.height / 2);
    mechCross.x += dx;
    mechCross.y += dy;
    mechSplash.x += dx;
    mechSplash.y += dy;
    #end
  }

  // El contador (3, 2, 1, TAP) pasa a verse encima de la mira en vez de encima del strumline.
  function mechPlaceHint()
  {
    #if mobile
    if (!MECH_MOBILE_BUTTON || mechCross == null || mechHint == null) return;
    mechHint.fieldWidth = 240;
    mechHint.x = mechCross.x + mechCross.width / 2 - 120;
    mechHint.y = mechCross.y - 70;
    #end
  }

  // Barra de "vida robada": oscurece la parte izquierda de TU barra curva (CurvedHealthBarModule).
  var mechBarModule = null;

  function mechModuleField(id, field)
  {
    var m = mechBarModule;
    if (m == null)
    {
      m = ModuleHandler.getModule(id);
      mechBarModule = m;
    }
    if (m == null) return null;
    var v = null;
    try
    {
      v = m.scriptGet(field);
    }
    catch (e:Dynamic)
    {
      v = null;
    }
    return v;
  }

  function mechEnsureSuckBar()
  {
    if (mechSuckBar != null) return;

    var red = mechModuleField("CurvedHealthBarModule", "redBar");
    if (red == null) return;

    mechSuckBar = new FlxSprite();
    mechSuckBar.loadGraphic(Paths.image("ui/healthbar/WHITEBAR"));
    mechSuckBar.scrollFactor.set(0, 0);
    mechSuckBar.cameras = [ps.camHUD];
    mechSuckBar.zIndex = MECH_SUCK_Z;
    mechSuckBar.color = MECH_SUCK_COLOR;
    mechSuckBar.flipY = AmScroll.isDown();
    mechSuckBar.clipRect = FlxRect.get(0, 0, 0, mechSuckBar.frameHeight);
    ps.add(mechSuckBar);
    ps.refresh();
  }

  function mechUpdateSuckBar()
  {
    mechEnsureSuckBar();
    if (mechSuckBar == null) return;

    var red = mechModuleField("CurvedHealthBarModule", "redBar");
    if (red == null) return;

    var fw = mechModuleField("CurvedHealthBarModule", "fillWidth");
    var fh = mechModuleField("CurvedHealthBarModule", "fillHeight");
    if (fw == null || fw <= 0) fw = mechSuckBar.frameWidth;
    if (fh == null || fh <= 0) fh = mechSuckBar.frameHeight;

    mechSuckBar.x = red.x;
    mechSuckBar.y = red.y;

    var r = mechSuckBar.clipRect;
    if (r == null) r = FlxRect.get(0, 0, 0, fh);
    r.x = 0;
    r.y = 0;
    r.width = (fw / 2) * mechHealthSucked;
    r.height = fh;
    mechSuckBar.clipRect = r;
  }

  function mechKeyName():String
  {
    var k = "SPACE";
    #if mobile
    k = "TAP";
    #end
    return k;
  }

  function mechPressed():Bool
  {
    if (FlxG.keys.justPressed.SPACE) return true;

    #if mobile
    if (mechBtnZone != null && mechBtnZone.exists && FlxG.touches != null)
    {
      var cam = (ps.camControls != null) ? ps.camControls : ps.camHUD;
      var touches = FlxG.touches.list;
      var i = 0;
      while (i < touches.length)
      {
        var t = touches[i];
        i = i + 1;
        if (t != null && t.justPressed && t.overlaps(mechBtnZone, cam))
        {
          mechBtnFeedback();
          return true;
        }
      }
    }
    #end

    return false;
  }

  // ---- MOBILE: zona de toque ----

  function mechBuildBtnZone()
  {
    #if mobile
    mechBtnZone = new FunkinSprite();
    mechBtnZone.makeSolidColor(8, 8, FlxColor.TRANSPARENT);
    mechBtnZone.scrollFactor.set(0, 0);
    mechBtnZone.cameras = [(ps.camControls != null) ? ps.camControls : ps.camHUD];
    mechBtnZone.x = -10000;
    mechBtnZone.y = -10000;
    #end
  }

  // Registra la zona como dead zone de cada carril del hitbox (misma tecnica que PlayState usa con pauseButton).
  // Es idempotente: se puede llamar en cada evento por si otro modulo reconstruyo el hitbox.
  function mechBtnSync()
  {
    #if mobile
    if (ps == null || ps.hitbox == null) return;
    if (mechBtnZone == null || !mechBtnZone.exists) mechBuildBtnZone();

    var z = mechBtnZone;
    ps.hitbox.forEachAlive(function(h)
    {
      if (h.deadZones.indexOf(z) < 0) h.deadZones.push(z);
    });
    #end
  }

  // on = true: coloca la zona sobre la mira. on = false: la manda fuera de pantalla (los carriles vuelven a la normalidad).
  function mechBtnArm(on)
  {
    #if mobile
    if (!MECH_MOBILE_BUTTON) return;
    mechBtnSync();
    if (mechBtnZone == null) return;

    if (on && mechCross != null)
    {
      var d = Math.max(mechCross.width * MECH_BTN_ZONE_MULT, FlxG.height * MECH_BTN_MIN_SIZE);
      d = Math.min(d, FlxG.height * MECH_BTN_MAX_SIZE);
      mechBtnZone.width = d;
      mechBtnZone.height = d;
      mechBtnZone.x = mechCross.x + mechCross.width / 2 - d / 2 + MECH_BTN_OFFSET_X;
      mechBtnZone.y = mechCross.y + mechCross.height / 2 - d / 2 + MECH_BTN_OFFSET_Y;
    }
    else
    {
      mechBtnZone.x = -10000;
      mechBtnZone.y = -10000;
    }
    #end
  }

  function mechBtnFeedback()
  {
    #if mobile
    if (mechCross != null && (mechCrossTween == null || mechCrossTween.finished))
    {
      mechCross.scale.set(.82, .82);
      FlxTween.tween(mechCross.scale, {x: 1, y: 1}, .14, {ease: FlxEase.backOut});
    }
    // Requiere `import funkin.util.HapticUtil;` en import.hx; si no esta, el try lo ignora.
    try
    {
      HapticUtil.vibrate(0, 0.04, 0.6, 0.5);
    }
    catch (e:Dynamic) {}
    #end
  }

  function mechHintsEnabled():Bool
  {
    var h = Save.instance.modOptions["hints"];
    return h == null || h == true;
  }

  function mechanicUpdate(elapsed)
  {
    if (!mechActive) return;

    mechUpdateSuckBar();

    // La vida máxima baja mientras haya "vida robada".
    var maxHealth = Constants.HEALTH_MAX - mechHealthSucked;
    if (ps.health > maxHealth) ps.health = maxHealth;
    if (ps.health < 0) ps.health = 0;

    if (mechIsEventActive)
    {
      if (mechCanHitFinal && mechPressed())
      {
        if (mechWithinFinalWindow()) mechHitFinalBeat();
      }
      mechCheckTimeout();
    }

    mechUpdateCamera(elapsed);
    mechIconsUpdate(elapsed);
  }

  function mechanicTrigger(isDodge, beatReserve, skipCamera)
  {
    if (!mechActive || mechIsEventActive || mechCross == null) return;

    mechMode = isDodge ? "dodge" : "attack";
    if (isDodge) mechTentacleSide = FlxG.random.bool(50) ? "Left" : "Right";

    mechEventBeats = Std.int(beatReserve);
    mechSemiBeatHits = (mechEventBeats == 2) ? 1 : -1;

    mechHint.x = ps.playerStrumline.x;
    mechHint.fieldWidth = ps.playerStrumline.width;
    mechPlaceHint();
    FlxTween.cancelTweensOf(mechHint, ['alpha']);
    if (mechHintsEnabled())
    {
      FlxTween.tween(mechHint, {alpha: .9}, .5, {ease: FlxEase.cubeOut});
      mechHint.text = Std.string(mechEventBeats - 1);
      mechHint.color = FlxColor.WHITE;
    }
    else
    {
      mechHint.alpha = 0;
    }

    if (isDodge)
    {
      if (!skipCamera) mechCamLock();

      var sn = getProp("snowman");
      if (sn != null)
      {
        FlxTween.cancelTweensOf(sn);
        FlxTween.tween(sn, {alpha: .4}, .25, {ease: FlxEase.backOut});
      }
    }

    mechIsEventActive = true;
    mechEventStartBeat = Conductor.instance.currentBeat;
    mechCanHitFinal = false;

    mechSetupCross(true);
    mechIconFocus(isDodge ? ps.iconP1 : ps.iconP2);
  }

  function mechanicBeat()
  {
    if (!mechActive) return;

    mechIconBop();

    if (!mechIsEventActive || mechFocusIcon == null || mechCross == null) return;

    var beatsPassed = Math.floor(Conductor.instance.currentBeat - mechEventStartBeat);

    if (beatsPassed >= 0 && beatsPassed < mechEventBeats)
    {
      var snd = FunkinSound.playOnce(Paths.sound('mechanics/cowbell'));
      if (snd != null)
      {
        if (mechMode == "attack") snd.pitch = 1.1;
        if (mechSemiBeatHits > 0) snd.pitch = 1.25;
      }

      if (mechMode == "dodge") mechTentacleTick();

      mechTickHint(mechEventBeats - beatsPassed - 1, null);

      if (beatsPassed < mechEventBeats - 1)
      {
        mechSpawnDotPair();
      }
      else
      {
        // beat final
        if (mechMode == "attack") mechPlay(ps.currentStage.getBoyfriend(), "pre attack", true, true);
        mechSpawnFinalStripes();
        mechCanHitFinal = true;
        mechTickHint(mechKeyName(), 0xffFF6D96);
      }
    }
  }

  function mechTentacleTick()
  {
    var t = getProp("tentacle" + mechTentacleSide);
    if (t == null) return;
    t.alpha = 1;
    t.animation.play("tick", true);
  }

  function mechTickHint(text, color)
  {
    if (!mechHintsEnabled())
    {
      mechHint.alpha = 0;
      return;
    }

    if (color == null) color = FlxColor.WHITE;
    FlxTween.cancelTweensOf(mechHint, ['scale.x', 'scale.y']);
    mechHint.scale.set(1.2, 1.2);
    mechHint.color = color;
    FlxTween.tween(mechHint, {"scale.x": 1, "scale.y": 1}, .25, {ease: FlxEase.cubeOut});
    mechHint.text = Std.string(text);
  }

  function mechPlay(ch, name, restart, ignoreOther)
  {
    if (ch == null) return;
    if (!ch.hasAnimation(name))
    {
      trace("[winter-horrorland-animania] falta la animación '" + name + "' en " + ch.characterId);
      return;
    }
    ch.playAnimation(name, restart, ignoreOther);
  }

  // ---- dots / stripes ----

  function mechSpawnMover(asset, z, startX, cx, cy, flip, alphaTo, fadeTime, duration, list)
  {
    var s = new FunkinSprite();
    s.cameras = [ps.camHUD];
    s.zIndex = z;
    s.loadGraphic(Paths.image(asset));
    s.x = startX;
    s.y = cy - s.height / 2;
    s.flipX = flip;
    s.alpha = 0;
    ps.add(s);
    list.push(s);

    FlxTween.tween(s, {alpha: alphaTo}, fadeTime, {ease: FlxEase.quadOut});
    FlxTween.tween(s, {x: cx - s.width / 2, y: cy - s.height / 2}, duration, {
      ease: FlxEase.linear,
      onComplete: function(t)
      {
        mechDisposeMover(s, list);
      }
    });
  }

  function mechDisposeMover(s, list)
  {
    list.remove(s);
    if (ps != null) ps.remove(s, true);
    s.destroy();
  }

  function mechClearMovers(list)
  {
    while (list.length > 0)
    {
      var s = list.pop();
      FlxTween.cancelTweensOf(s);
      if (ps != null) ps.remove(s, true);
      s.destroy();
    }
  }

  function mechSpawnDotPair()
  {
    if (mechCross == null) return;

    var cx = mechCross.x + mechCross.width / 2;
    var cy = mechCross.y + mechCross.height / 2;
    var dur = (60 / Conductor.instance.bpm) * MECH_DOT_SPEED;

    mechSpawnMover("mechanincs/beat-dot", MECH_DOT_Z, cx - MECH_DOT_OFFSET * 2.0, cx, cy, false, .5, .15, dur, mechDots);
    mechSpawnMover("mechanincs/beat-dot", MECH_DOT_Z, cx + MECH_DOT_OFFSET * 1.8, cx, cy, false, .5, .15, dur, mechDots);
    ps.refresh();
  }

  function mechSpawnFinalStripes()
  {
    if (mechCross == null) return;

    var cx = mechCross.x + mechCross.width / 2;
    var cy = mechCross.y + mechCross.height / 2;
    var dur = (60 / Conductor.instance.bpm) * (MECH_DOT_SPEED * 0.9);

    mechSpawnMover("mechanincs/beat-stripe", MECH_STRIPE_Z, cx - MECH_DOT_OFFSET * 2.3, cx, cy, false, 1, .1, dur, mechStripes);
    mechSpawnMover("mechanincs/beat-stripe", MECH_STRIPE_Z, cx + MECH_DOT_OFFSET * 2.1, cx, cy, true, 1, .1, dur, mechStripes);

    mechTargetFinalBeat = Conductor.instance.currentBeatTime + 1.0;
    mechCanHitFinal = true;
    mechBtnArm(true);

    ps.refresh();
  }

  // ---- hit / miss ----

  function mechWithinFinalWindow():Bool
  {
    if (!mechCanHitFinal) return false;
    var diff = Conductor.instance.currentBeatTime - mechTargetFinalBeat;
    var post = MECH_FINAL_POST_WINDOW;
    #if mobile
    post = post + MECH_MOBILE_POST_BONUS;
    #end
    return (diff >= -MECH_FINAL_PRE_WINDOW && diff <= post);
  }

  function mechHitFinalBeat()
  {
    if (!mechCanHitFinal || !mechWithinFinalWindow()) return;

    mechCanHitFinal = false;

    var beatDiff = Conductor.instance.currentBeatTime - mechTargetFinalBeat;
    var noteDiff = Std.int(beatDiff * Conductor.instance.beatLengthMs);
    var rating = Scoring.judgeNote(noteDiff);

    mechSplash.angle = FlxG.random.float(-50, 50);
    mechSplash.animation.play("y", true);
    mechSplash.visible = true;

    mechClearMovers(mechStripes);

    mechEndEvent(true, rating);
  }

  function mechCheckTimeout()
  {
    if (!mechCanHitFinal) return;

    var beatsPassed = Math.floor(Conductor.instance.currentBeat - mechEventStartBeat);
    if (beatsPassed >= mechEventBeats + 1)
    {
      mechCanHitFinal = false;
      mechEndEvent(false, "miss");
    }
  }

  function mechEndEvent(success, rating)
  {
    var bf = ps.currentStage.getBoyfriend();
    var dad = ps.currentStage.getDad();

    FlxTween.cancelTweensOf(mechHint, ['alpha']);
    if (mechHintsEnabled()) FlxTween.tween(mechHint, {alpha: 0}, .5, {ease: FlxEase.cubeOut});
    else mechHint.alpha = 0;

    mechCamRelease();
    mechBtnArm(false);

    var sn = getProp("snowman");
    if (sn != null) FlxTween.tween(sn, {alpha: mechSnowmanAlpha}, .25, {ease: FlxEase.backOut, startDelay: .8});

    if (rating == "miss") success = false;

    mechSpawnRating(success ? rating : "missed");

    mechIsEventActive = false;
    mechCanHitFinal = false;

    mechSetupCross(false);
    mechIconUnfocus();

    mechClearMovers(mechDots);
    mechClearMovers(mechStripes);

    if (success)
    {
      if (mechMode == "dodge")
      {
        var tent = getProp("tentacle" + mechTentacleSide);
        if (tent != null)
        {
          tent.alpha = 1;
          tent.animation.play("attack", true);
        }

        if (ps.health > .5)
        {
          FunkinSound.playOnce(Paths.sound('mechanics/dodge'));
          FunkinSound.playOnce(Paths.sound('mechanics/tentacle ' + FlxG.random.int(1, 2)));

          if (mechTentacleSide == "Left") mechPlay(bf, "dodge" + (FlxG.random.bool(50) ? 1 : 2), true, true);
          else mechPlay(bf, "dodge" + (FlxG.random.bool(50) ? 1 : 3), true, false);

          mechDodgeFlash(bf);
        }
        else
        {
          FunkinSound.playOnce(Paths.sound('mechanics/parry'));
          FunkinSound.playOnce(Paths.sound('mechanics/tentacle ' + FlxG.random.int(1, 2)));
          mechPlay(bf, "parry", true, true);
          later(.5, function(_)
          {
            ps.health = ps.health + .45;
          });
        }
      }
      else
      {
        var snd = FunkinSound.playOnce(Paths.sound('mechanics/attack'));
        if (snd != null) snd.pitch = FlxG.random.float(.9, 1.1);

        FunkinSound.playOnce(Paths.sound('mechanics/success'), .8);

        var loseSuck = 0;
        if (rating == "sick") loseSuck = .5;
        else if (rating == "good") loseSuck = .335;
        else if (rating == "shit") loseSuck = .15;
        else if (rating == "bad") loseSuck = .05;

        if (bf != null) bf.canPlayOtherAnims = true;
        mechPlay(bf, "attack", true, true);
        FunkinSound.playOnce(Paths.sound('mechanics/attack'));

        later(.15, function(_)
        {
          mechPlay(dad, "hit", true, true);
          ps.camGame.shake(.005, .15);
          var from = mechHealthSucked;
          var to = Math.max(0, from - loseSuck);
          FlxTween.num(from, to, .25, {ease: FlxEase.sineInOut}, function(v)
          {
            mechHealthSucked = v;
          });
        });
        later(.5, function(_)
        {
          if (bf != null) bf.canPlayOtherAnims = true;
        });
        later(.45, function(_)
        {
          if (dad != null) dad.canPlayOtherAnims = true;
        });

        later(.15, function(_)
        {
          mechFlickerIcon(ps.iconP2);
        });

        ps.health = ps.health + .35;
      }
    }
    else
    {
      if (mechMode == "dodge")
      {
        var tent2 = getProp("tentacle" + mechTentacleSide);
        if (tent2 != null)
        {
          tent2.alpha = 1;
          tent2.animation.play("attack", true);
        }

        FunkinSound.playOnce(Paths.sound('mechanics/bfhit'));
        FunkinSound.playOnce(Paths.sound('mechanics/tentacle ' + FlxG.random.int(1, 2)));
        mechPlay(bf, mechTentacleSide.toLowerCase() + " hit", true, true);

        later(.15, function(_)
        {
          if (bf != null) FlxFlicker.flicker(bf, 1, 1 / 30, true, true, function(f)
          {
            FlxFlicker.flicker(bf, 0.5, 1 / 60, true, true, null);
          });
          mechFlickerIcon(ps.iconP1);
        });

        later(.1, function(_)
        {
          ps.camGame.shake(.005, .15);
        });

        ps.health = ps.health - .4;
      }
      else
      {
        FunkinSound.playOnce(Paths.sound('mechanics/failed'));
        mechPlay(bf, "singLEFTmiss", true, true);
      }
    }
  }

  function mechFlickerIcon(icon)
  {
    if (icon == null) return;
    FlxFlicker.flicker(icon, 1, 1 / 30, true, true, function(f)
    {
      FlxFlicker.flicker(icon, 0.5, 1 / 60, true, true, null);
    });
  }

  // Reemplazo del FunkinTrail original (no existe en V-Slice y FlxTrail no copia atlas de Animate):
  // destello cian que vuelve a blanco. Se omite en lowQuality.
  function mechDodgeFlash(bf)
  {
    if (bf == null || Save.instance.modOptions["lowQuality"]) return;
    FlxTween.cancelTweensOf(bf, ['color']);
    bf.color = 0xFF66FFFF;
    FlxTween.color(bf, .45, 0xFF66FFFF, FlxColor.WHITE, {ease: FlxEase.cubeOut});
  }

  function mechSpawnRating(rating)
  {
    var rat = new FunkinSprite();
    rat.frames = Paths.getSparrowAtlas("mechanincs/ratings");
    rat.animation.addByPrefix("y", rating, 24, false);
    rat.animation.play("y", true);
    rat.screenCenter();
    #if mobile
    if (MECH_MOBILE_BUTTON) rat.x = mechCross.x + mechCross.width / 2 - rat.width / 2;
    #end
    rat.cameras = [ps.camHUD];
    rat.zIndex = 2100;
    rat.y = mechCross.y - rat.height - 10;
    if (AmScroll.isDown()) rat.y = mechCross.y + mechCross.height + 10;

    rat.acceleration.y = 550;
    rat.velocity.y -= FlxG.random.int(140, 175);
    rat.velocity.x -= FlxG.random.int(0, 10);
    rat.angle = FlxG.random.int(-5, 5);
    rat.angularVelocity = FlxG.random.int(-5, 5);

    var baseX = rat.scale.x;
    var baseY = rat.scale.y;
    rat.scale.set(baseX * 0.85, baseY * 0.85);

    var beatSec = Conductor.instance.beatLengthMs * 0.001;
    FlxTween.tween(rat, {"scale.x": baseX, "scale.y": baseY}, beatSec / 2, {ease: FlxEase.bounceOut});
    FlxTween.tween(rat, {alpha: 0, angle: FlxG.random.int(-8, 8)}, 0.1, {
      startDelay: beatSec,
      onComplete: function(t)
      {
        if (ps != null) ps.remove(rat, true);
        rat.destroy();
      }
    });

    ps.add(rat);
    ps.refresh();
  }

  function mechSetupCross(show)
  {
    if (mechCrossTween != null) mechCrossTween.cancel();
    if (show)
    {
      mechCross.angle = -55;
      mechCross.scale.set(1.5, 1.5);
      mechCross.alpha = 0;
      var crossAlpha = .6;
      #if mobile
      crossAlpha = MECH_MOBILE_CROSS_ALPHA;
      #end
      mechCrossTween = FlxTween.tween(mechCross, {angle: 0, "scale.x": 1, "scale.y": 1, alpha: crossAlpha}, 18 / 24, {ease: FlxEase.cubeOut});
    }
    else
    {
      mechCross.scale.set(.9, .9);
      mechCrossTween = FlxTween.tween(mechCross, {"scale.x": 1.4, "scale.y": 1.4, alpha: 0}, 7 / 24, {startDelay: 1 / 24, ease: FlxEase.quartOut});
    }
  }

  // ---- iconos (AnimaniaStuff reposiciona los iconos cada frame, así que se "toma" el icono) ----

  function mechTakeAmEntry(icon)
  {
    var am = ModuleHandler.getModule("AnimaniaStuff");
    if (am == null) return null;

    var list = null;
    try
    {
      list = am.scriptGet("amTakeIcons");
    }
    catch (e:Dynamic)
    {
      list = null;
    }
    if (list == null) return null;

    var i = 0;
    while (i < list.length)
    {
      var entry = list[i];
      if (entry != null && entry.icon == icon)
      {
        list.splice(i, 1);
        return entry;
      }
      i = i + 1;
    }
    return null;
  }

  function mechGiveAmEntry(entry)
  {
    if (entry == null) return;

    var am = ModuleHandler.getModule("AnimaniaStuff");
    if (am == null) return;

    var list = null;
    try
    {
      list = am.scriptGet("amTakeIcons");
    }
    catch (e:Dynamic)
    {
      list = null;
    }
    if (list != null && list.indexOf(entry) == -1) list.push(entry);
  }

  // AnimaniaModule (si su HUD está activo) es quien dimensiona los iconos: su tamaño base es la referencia.
  function mechAmModule()
  {
    var am = ModuleHandler.getModule("AnimaniaModule");
    if (am == null) return null;

    var active = false;
    try
    {
      active = am.scriptGet("usingAmTakeUI") == true;
    }
    catch (e:Dynamic)
    {
      active = false;
    }
    return active ? am : null;
  }

  function mechNormalSize()
  {
    var size = MECH_ICON_NORMAL_SIZE;
    var am = mechAmModule();
    if (am != null)
    {
      try
      {
        size = am.scriptGet("ICON_BASE_SIZE");
      }
      catch (e:Dynamic)
      {
        size = MECH_ICON_NORMAL_SIZE;
      }
    }
    return size;
  }

  function mechFocusSize()
  {
    return mechNormalSize() * MECH_ICON_FOCUS_MULT;
  }

  function mechLockModuleIcon(icon, lock)
  {
    var am = mechAmModule();
    if (am == null) return;
    am.scriptCall(lock ? "lockIcon" : "unlockIcon", [icon]);
  }

  function mechApplyIconSize(icon, px)
  {
    var fw = icon.frameWidth;
    var fh = icon.frameHeight;
    if (fw <= 1 || fh <= 1)
    {
      fw = 150;
      fh = 150;
    }
    var s = (fw > fh) ? (px * icon.size.x) / fw : (px * icon.size.y) / fh;
    icon.scale.set(s, s);
    icon.updateHitbox();
  }

  function mechIconHome(icon, isPlayer)
  {
    var am = mechAmModule();
    if (am != null)
    {
      var pos = am.scriptCall("getIconHome", [icon, isPlayer]);
      if (pos != null) return pos;
    }

    var bar = ps.healthBar;
    var barPercent = FlxMath.remapToRange(bar.value, 0, 2, 100, 0) * 0.01;
    var x = 0.0;
    if (isPlayer) x = bar.x + (bar.width * barPercent - 26);
    else x = bar.x + (bar.width * barPercent) - (icon.width - 26);
    var y = bar.y - (icon.height / 2);
    return [x, y];
  }

  // ---------------------------------------------------------------------------
  // CONTROLADOR DE ICONOS (por frame)
  //
  // Cada icono que la mecanica toma tiene un estado {p, target}: p (0..1) se acerca a target a velocidad fija y la
  // pose (posicion, tamano, angulo, rebote) se CALCULA en cada frame a partir de p. No hay tweens sobre el icono ni
  // posiciones de origen guardadas, asi que si llega otro evento (o se spamea) a mitad de camino solo cambia el
  // destino: el icono siempre termina llegando a la mira o volviendo a casa, sin importar el orden de los eventos.
  // El control se entrega a AnimaniaModule/AnimaniaStuff unicamente cuando p llega a 0.
  // ---------------------------------------------------------------------------

  function mechIconState(icon)
  {
    var i = 0;
    while (i < mechIcons.length)
    {
      var st = mechIcons[i];
      i = i + 1;
      if (st.icon == icon) return st;
    }
    return null;
  }

  function mechIconSetTarget(st, t)
  {
    if (st.target == t) return;
    st.target = t;
    st.icon.zIndex = (t == 1) ? 1800 : 850;
    ps.refresh();
  }

  function mechIconAcquire(icon)
  {
    var st = {
      icon: icon,
      isPlayer: (icon == ps.iconP1),
      p: 0,
      target: 1,
      bop: 0,
      angle0: icon.angle,
      wasAuto: icon.autoUpdate,
      bopEvery: icon.bopEvery,
      offX: icon.iconOffset.x,
      offY: icon.iconOffset.y,
      entry: null
    };

    icon.autoUpdate = false;
    icon.bopEvery = 0;
    if (icon.bopTween != null) icon.bopTween.cancel();
    FlxTween.cancelTweensOf(icon.scale);

    st.entry = mechTakeAmEntry(icon);
    mechLockModuleIcon(icon, true);

    // Mientras la mecanica controla el icono se ignora su iconOffset, para que su CENTRO quede en el centro de la mira.
    icon.iconOffset.set(0, 0);
    icon.zIndex = 1800;
    ps.refresh();

    mechIcons.push(st);
    return st;
  }

  function mechIconRelease(st)
  {
    var icon = st.icon;
    mechIcons.remove(st);
    if (icon == null) return;

    icon.angle = 0;
    icon.iconOffset.set(st.offX, st.offY);
    FlxTween.cancelTweensOf(icon.scale);
    if (mechAmModule() != null) mechApplyIconSize(icon, mechNormalSize());
    else
    {
      icon.updateHitbox();
      icon.snapToTargetSize();
    }

    var home = mechIconHome(icon, st.isPlayer);
    icon.x = home[0];
    icon.y = home[1];

    mechLockModuleIcon(icon, false);
    icon.bopEvery = st.bopEvery;
    icon.autoUpdate = st.wasAuto;
    icon.zIndex = 850;
    mechGiveAmEntry(st.entry);
    st.entry = null;
    ps.refresh();
  }

  // El evento nuevo manda su icono a la mira; cualquier otro que siguiera fuera de casa vuelve a casa.
  function mechIconFocus(icon)
  {
    if (icon == null) return;

    var i = 0;
    while (i < mechIcons.length)
    {
      var other = mechIcons[i];
      i = i + 1;
      if (other.icon != icon) mechIconSetTarget(other, 0);
    }

    var st = mechIconState(icon);
    if (st == null) st = mechIconAcquire(icon);
    else mechIconSetTarget(st, 1);

    mechFocusIcon = icon;
  }

  function mechIconUnfocus()
  {
    var i = 0;
    while (i < mechIcons.length)
    {
      mechIconSetTarget(mechIcons[i], 0);
      i = i + 1;
    }
    mechFocusIcon = null;
  }

  function mechIconsUpdate(elapsed)
  {
    if (mechIcons.length == 0 || mechCross == null) return;

    var dt = Math.min(elapsed, 0.1);
    var step = dt / MECH_ICON_TRAVEL;
    var normal = mechNormalSize();
    var focus = mechFocusSize();
    var cx = mechCross.x + mechCross.width / 2 + MECH_ICON_CROSS_OFFSET_X;
    var cy = mechCross.y + mechCross.height / 2 + MECH_ICON_CROSS_OFFSET_Y;

    var i = mechIcons.length - 1;
    while (i >= 0)
    {
      var st = mechIcons[i];
      i = i - 1;

      var icon = st.icon;
      if (icon == null || !icon.exists)
      {
        mechIcons.remove(st);
        continue;
      }

      // Red de seguridad: si no hay evento activo ningun icono debe seguir yendo hacia la mira.
      if (!mechIsEventActive && st.target == 1) mechIconSetTarget(st, 0);

      if (st.p < st.target) st.p = Math.min(st.target, st.p + step);
      else if (st.p > st.target) st.p = Math.max(st.target, st.p - step);

      if (st.target == 0 && st.p <= 0)
      {
        mechIconRelease(st);
        continue;
      }

      var p = st.p;
      var e = (p < .5) ? 2 * p * p : 1 - 2 * (1 - p) * (1 - p);

      mechApplyIconSize(icon, normal + (focus - normal) * e);

      var home = mechIconHome(icon, st.isPlayer);
      var hx = home[0] - st.offX;
      var hy = home[1] - st.offY;
      var tx = cx - icon.width / 2;
      var ty = cy - icon.height / 2;
      icon.x = hx + (tx - hx) * e;
      icon.y = hy + (ty - hy) * e;
      icon.angle = st.angle0 * (1 - e);

      if (st.bop > 0)
      {
        st.bop = Math.max(0, st.bop - dt / 0.2);
        var k = 1 + MECH_ICON_BOP * st.bop;
        icon.scale.set(icon.scale.x * k, icon.scale.y * k);
      }
    }
  }

  // Rebote del icono en cada beat, solo cuando ya esta sobre la mira.
  function mechIconBop()
  {
    if (!mechIsEventActive || mechFocusIcon == null) return;
    var st = mechIconState(mechFocusIcon);
    if (st == null || st.p < 1) return;
    st.bop = 1;
  }

  // ---- cámara (reemplaza forceFocusedPos/Zoom y neededZoom del fork) ----

  function mechCamLock()
  {
    var bf = ps.currentStage.getBoyfriend();
    if (bf == null) return;

    mechSavedX = ps.cameraFollowPoint.x;
    mechSavedY = ps.cameraFollowPoint.y;
    mechSavedZoom = ps.currentCameraZoom;

    ps.cancelCameraFollowTween();
    ps.cancelCameraZoomTween();
    ps.resetCamera(false, false, false);

    var fp = bf.cameraFocusPoint;
    mechCamX = fp.x + MECH_CAM_OFFSET_X;
    mechCamY = fp.y + MECH_CAM_OFFSET_Y;
    mechCamZoom = MECH_CAM_ZOOM * ps.stageZoom;

    mechCamLocked = true;
  }

  function mechUpdateCamera(elapsed)
  {
    if (!mechCamLocked) return;

    // Si algo (otro módulo) arrancó un tween de cámara, se cancela y se vuelve a seguir el punto.
    ps.cancelCameraFollowTween();
    ps.cancelCameraZoomTween();
    if (FlxG.camera.target == null) ps.resetCamera(false, false, false);

    ps.cameraFollowPoint.setPosition(mechCamX, mechCamY);
    ps.currentCameraZoom = MathUtil.smoothLerpPrecision(ps.currentCameraZoom, mechCamZoom, elapsed, 0.35, 0.01);
  }

  function mechCamRelease()
  {
    if (!mechCamLocked) return;
    mechCamLocked = false;

    ps.tweenCameraToPosition(mechSavedX, mechSavedY, 0.7, FlxEase.cubeOut);
    ps.tweenCameraZoom(mechSavedZoom / FlxCamera.defaultZoom, 0.7, true, FlxEase.cubeOut);
  }

  // ---- reset (retry) ----

  function mechanicReset()
  {
    if (ps == null || !mechActive) return;

    mechIsEventActive = false;
    mechCanHitFinal = false;
    mechSemiBeatHits = -1;
    mechTentacleSide = "Left";
    mechCamLocked = false;

    mechClearMovers(mechDots);
    mechClearMovers(mechStripes);
    mechBtnArm(false);

    // Iconos: devolverle el control a AnimaniaStuff de inmediato.
    while (mechIcons.length > 0) mechIconRelease(mechIcons[0]);
    mechFocusIcon = null;

    if (mechCrossTween != null) mechCrossTween.cancel();
    mechCrossTween = null;
    if (mechCross != null)
    {
      FlxTween.cancelTweensOf(mechCross);
      mechCross.alpha = 0;
      mechCross.angle = 0;
      mechCross.scale.set(1, 1);
    }
    if (mechSplash != null) mechSplash.visible = false;
    if (mechHint != null)
    {
      FlxTween.cancelTweensOf(mechHint);
      mechHint.alpha = 0;
      mechHint.scale.set(1, 1);
    }

    mechHealthSucked = 1;
    if (mechSuckBar != null) mechUpdateSuckBar();

    var bf = ps.currentStage.getBoyfriend();
    if (bf != null)
    {
      FlxFlicker.stopFlickering(bf);
      bf.visible = true;
      FlxTween.cancelTweensOf(bf, ['color']);
      bf.color = FlxColor.WHITE;
    }
    if (ps.iconP1 != null) FlxFlicker.stopFlickering(ps.iconP1);
    if (ps.iconP2 != null) FlxFlicker.stopFlickering(ps.iconP2);

    var sn = getProp("snowman");
    if (sn != null)
    {
      FlxTween.cancelTweensOf(sn, ['alpha']);
      sn.alpha = mechSnowmanAlpha;
    }

    var tl = getProp("tentacleLeft");
    if (tl != null) tl.alpha = 0;
    var tr = getProp("tentacleRight");
    if (tr != null) tr.alpha = 0;
  }

  function createHahaha(xx, yy)
  {
    var ha = new FunkinSprite(xx, yy);
    ha.loadTexture("stages/xMassCityMallNasty/ha");
    ha.zIndex = 10000;
    ha.angle = FlxG.random.float(-10, 10);
    ps.currentStage.add(ha);
    ha.scrollFactor.set(1, 1);
    ps.currentStage.refresh();
    ass[ass.length] = ha;

    ha.scale.set(.9, .9);
    FlxTween.tween(ha, {"scale.x": 1.1, "scale.y": 1.1, angle: ha.angle + FlxG.random.float(-7, 7)}, .15, {ease: FlxEase.cubeOut});
  }

  function fadeHahaha(ha)
  {
    if (ha == null) return;
    FlxTween.tween(ha, {"scale.x": .5, "scale.y": .5, angle: ha.angle + FlxG.random.float(-10, 10), alpha: 0}, .25, {
      ease: FlxEase.cubeOut,
      onComplete: function(_)
      {
        if (ps != null && ps.currentStage != null) ps.currentStage.remove(ha);
        ha.kill();
        ha.destroy();
      }
    });
  }

  function hudIntro()
  {
    var d = ps.playerStrumline.isDownscroll ? 25 : -25;

    ps.playerStrumline.y = hudStrumY + d;
    ps.playerStrumline.alpha = 0;
    FlxTween.tween(ps.playerStrumline, {y: hudStrumY, alpha: 1}, .5, {ease: FlxEase.cubeOut});

    ps.healthBar.y = hudBarY - d;
    ps.healthBarBG.y = hudBarBgY - d;
    FlxTween.tween(ps.healthBar, {y: hudBarY}, .5, {ease: FlxEase.cubeOut});
    FlxTween.tween(ps.healthBarBG, {y: hudBarBgY}, .5, {ease: FlxEase.cubeOut});

    var st = getScoreText();
    if (st != null)
    {
      st.y = hudScoreY - d;
      FlxTween.tween(st, {y: hudScoreY}, .5, {ease: FlxEase.cubeOut});
    }
  }

  function createBars()
  {
    barW = Math.max(FlxG.width, ps.camGame.width) * 1.5;
    barH = FlxG.height * 1.25;
    barBaseScaleX = barW / 2;
    barBaseScaleY = barH / 2;

    barUp = makeBar();
    barDown = makeBar();
    barVis = 160;
    layoutBars();
  }

  function makeBar()
  {
    var bar = new FunkinSprite();
    bar.makeSolidColor(Std.int(barW), Std.int(barH), FlxColor.BLACK);
    bar.scrollFactor.set(0, 0);
    bar.zIndex = 5000;
    ps.add(bar);
    ps.refresh();
    return bar;
  }

  function layoutBars()
  {
    if (barUp == null || barDown == null || ps == null) return;

    var cam = ps.camGame;
    var z = cam.zoom;
    if (z < 0.05) z = 0.05;

    var cx = cam.width / 2;
    var cy = cam.height / 2;
    var w = barW / z;
    var h = barH / z;

    barUp.scale.set(barBaseScaleX / z, barBaseScaleY / z);
    barUp.updateHitbox();
    barUp.x = cx - w / 2;
    barUp.y = (cy + (barVis - cy) / z) - h;

    barDown.scale.set(barBaseScaleX / z, barBaseScaleY / z);
    barDown.updateHitbox();
    barDown.x = cx - w / 2;
    barDown.y = cy + ((cam.height - barVis) - cy) / z;
  }

  function moveBars(target, time, ease, delay)
  {
    if (delay > 0)
    {
      later(delay, function(_)
      {
        moveBars(target, time, ease, 0);
      });
      return;
    }

    if (barTween != null) barTween.cancel();
    barTween = null;

    if (time <= 0)
    {
      barVis = target;
      return;
    }

    barTween = FlxTween.num(barVis, target, time, {ease: ease}, function(v)
    {
      barVis = v;
    });
  }

  function setupChroma()
  {
	if (Save.instance.modOptions['shaders'])
	{
		try
		{
			chromShader = new FlxRuntimeShader(Assets.getText(Paths.frag("chromaticAbberation")));
			chromShader.setFloat("strength", 0);
			applyChromaFilter();
		}
		catch (e:Dynamic)
		{
			chromShader = null;
	      trace("[winter-horrorland-animania] No se pudo crear el shader de aberración cromática: " + e);
		}
	}
  }

  function applyChromaFilter()
  {
    if (Save.instance.modOptions['shaders'] && chromShader == null || ps == null) return;
    ps.camGame.filters = [new ShaderFilter(chromShader)];
  }

  function chromaEffect(strength, time, easeStr)
  {
    if (!Save.instance.modOptions['shaders'] && chromShader == null) return;

    if (chromTween != null) chromTween.cancel();
    chromTween = null;

    if (time <= 0)
    {
      chromaValue = strength;
      chromShader.setFloat("strength", strength);
    }
    else
    {
      chromTween = FlxTween.num(chromaValue, strength, time, {ease: getEase(easeStr)}, function(v)
      {
        chromaValue = v;
        chromShader.setFloat("strength", v);
      });
    }
  }

  function getEase(name)
  {
    var f = null;
    if (name != null)
    {
      try
      {
        f = Reflect.field(FlxEase, name);
      }
      catch (e:Dynamic)
      {
        f = null;
      }
    }
    if (f == null) f = FlxEase.smootherStepOut;
    return f;
  }

  var SNOW_FRAG:String = "
#pragma header

uniform float iTime;
uniform int iLayers;
uniform float iDepth;
uniform float iWidth;
uniform float iSpeed;

const vec2 EFFECT_SCALE = vec2(6.0, 4.0);

float snowing(in vec2 uv)
{
    const mat3 p = mat3(13.323122, 23.5112, 21.71123,
                        21.1212, 28.7312, 11.9312,
                        21.8112, 14.7212, 61.3934);
    uv.y = 1.0 - uv.y;
    float depth = iDepth;
    float width = iWidth;
    float speed = iSpeed;
    float acc = 0.0;
    float dof = 5.0 * sin(iTime * 0.1);

    float angle = iTime * 2.0;
    float s = sin(angle);
    float c = cos(angle);
    const float cos1 = 0.5403023058681398;
    const float sin1 = 0.8414709848078965;

    for (int fi = 0; fi < iLayers; fi++)
    {
        float fi_f = float(fi);
        vec2 q = uv * (1.0 + fi_f * depth);
        float w = width * fract(fi_f * 7.238917) - width * 0.1 * s;
        q += vec2(q.y * w, speed * iTime / (1.0 + fi_f * depth * 0.03));

        vec3 n = vec3(floor(q), 31.189 + fi_f);
        vec3 m = floor(n) * 0.00001 + fract(n);

        vec3 pm = vec3(dot(p[0], m), dot(p[1], m), dot(p[2], m));
        vec3 r = fract((31415.9 + m) / fract(pm));

        vec2 s_xy = abs(mod(q, 1.0) - 0.5 + 0.9 * r.xy - 0.45);
        s_xy += 0.01 * abs(2.0 * fract(10.0 * q.yx) - 1.0);
        float d = 0.6 * max(s_xy.x - s_xy.y, s_xy.x + s_xy.y) + max(s_xy.x, s_xy.y) - 0.01;
        float edge = 0.05 + 0.05 * min(0.5 * abs(fi_f - 5.0 - dof), 1.0);
        acc += smoothstep(edge, -edge, d) * (r.x / (1.0 + 0.02 * fi_f * depth));

        float new_s = s * cos1 + c * sin1;
        float new_c = c * cos1 - s * sin1;
        s = new_s;
        c = new_c;
    }
    return (acc + acc * acc) / 1.75;
}

void main()
{
    vec4 texColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
    float alpha = snowing(openfl_TextureCoordv.xy * EFFECT_SCALE) * 1.25;
    vec3 flakeColor = texColor.rgb;
    gl_FragColor = vec4(flakeColor * alpha, alpha * texColor.a);
}";

  function createSnow()
  {
    if (!SNOW_ENABLED || !Save.instance.modOptions["shaders"]) return;

    try
    {
      snowShader = new FlxRuntimeShader(SNOW_FRAG);
    }
    catch (e:Dynamic)
    {
      snowShader = null;
      trace("[winter-horrorland-animania] No se pudo crear el shader de nieve: " + e);
      return;
    }

    snowShader.setFloat("iTime", 0);
    snowShader.setInt("iLayers", SNOW_LAYERS);
    snowShader.setFloat("iDepth", SNOW_DEPTH);
    snowShader.setFloat("iWidth", SNOW_BASE_WIDTH);
    snowShader.setFloat("iSpeed", SNOW_BASE_SPEED);

    snowSpr = new FunkinSprite();
    snowSpr.makeSolidColor(Std.int(FlxG.width * 4), Std.int(FlxG.height * 4), FlxColor.WHITE);
    snowSpr.zIndex = SNOW_ZINDEX;
    ps.currentStage.add(snowSpr);
    ps.currentStage.refresh();
    snowSpr.scrollFactor.set(1.5, 1.5);
    snowSpr.screenCenter();
    snowSpr.x -= 1200;
    snowSpr.y -= 1100;
    snowSpr.shader = snowShader;
    snowSpr.color = SNOW_BASE_COLOR;
    snowSpr.alpha = SNOW_BASE_ALPHA;

    snowBaseScaleX = snowSpr.scale.x;
    snowBaseScaleY = snowSpr.scale.y;
  }

  function updateSnow(elapsed)
  {
    if (snowShader == null || snowSpr == null) return;

    snowTime = snowTime + elapsed * snowTimeSpeed;
    snowShader.setFloat("iTime", snowTime);

    var z = ps.camGame.zoom;
    if (z < 0.05) z = 0.05;
    var m = (1 / z) * (1 - SNOW_ZOOM_FACTOR) + SNOW_ZOOM_FACTOR;
    snowSpr.scale.set(snowBaseScaleX * m, snowBaseScaleY * m);
  }

  function resetSnow()
  {
    if (snowSpeedTween != null) snowSpeedTween.cancel();
    if (snowAlphaTween != null) snowAlphaTween.cancel();
    if (snowWidthTween != null) snowWidthTween.cancel();
    snowSpeedTween = null;
    snowAlphaTween = null;
    snowWidthTween = null;

    snowTime = 0;
    snowTimeSpeed = 1;
    snowWidth = SNOW_BASE_WIDTH;

    if (snowShader == null || snowSpr == null) return;

    snowShader.setFloat("iTime", 0);
    snowShader.setFloat("iWidth", SNOW_BASE_WIDTH);
    snowShader.setFloat("iSpeed", SNOW_BASE_SPEED);
    snowSpr.alpha = SNOW_BASE_ALPHA;
    snowSpr.color = SNOW_BASE_COLOR;
  }

  function tweenSnowSpeed(target, time)
  {
    if (snowSpeedTween != null) snowSpeedTween.cancel();
    snowSpeedTween = FlxTween.num(snowTimeSpeed, target, time, {ease: FlxEase.sineInOut}, function(v)
    {
      snowTimeSpeed = v;
    });
  }

  function tweenSnowAlpha(from, to, time)
  {
    if (snowAlphaTween != null) snowAlphaTween.cancel();
    snowAlphaTween = FlxTween.num(from, to, time, {ease: FlxEase.sineInOut}, function(v)
    {
      if (snowSpr != null) snowSpr.alpha = v;
    });
  }

  function tweenSnowWidth(target, time)
  {
    if (snowWidthTween != null) snowWidthTween.cancel();
    snowWidthTween = FlxTween.num(snowWidth, target, time, {ease: FlxEase.sineInOut}, function(v)
    {
      snowWidth = v;
      if (snowShader != null) snowShader.setFloat("iWidth", v);
    });
  }

  function snowBeat(beat)
  {
    if (snowShader == null || snowSpr == null) return;

    if (beat == 85)
    {
      snowSpr.alpha = 0;
      snowSpr.color = SNOW_RED_COLOR;
    }
    else if (beat == 86)
    {
      snowShader.setFloat("iSpeed", 0.9);
    }
    else if (beat == 87)
    {
      tweenSnowAlpha(0.0, 1.0, 1.6);
      tweenSnowSpeed(5, 1.6);
      tweenSnowWidth(0.9, 1.6);
    }
    else if (beat == 120)
    {
      tweenSnowSpeed(4.3, 1);
    }
    else if (beat == 152)
    {
      tweenSnowSpeed(3.8, 1);
    }
    else if (beat == 184)
    {
      tweenSnowSpeed(5.7, .3);
    }
    else if (beat == 216)
    {
      tweenSnowSpeed(.4, .3);
      tweenSnowAlpha(1.0, .6, 1);
    }
    else if (beat == 240)
    {
      tweenSnowSpeed(3.2, 3);
      tweenSnowAlpha(.6, 1, 3);
    }
    else if (beat == 264)
    {
      tweenSnowSpeed(.3, 3);
    }
    else if (beat == 280)
    {
      tweenSnowSpeed(5, 3);
    }
    else if (beat == 312)
    {
      tweenSnowSpeed(2.4, 3);
    }
    else if (beat == 344)
    {
      tweenSnowSpeed(7, 4);
    }
  }

  function resetRuntimeState()
  {
    seenCutscene = false;
    playedCutscene = false;
    allowEnd = false;
    chromShader = null;
    chromTween = null;
    chromaValue = 0;
    snowShader = null;
    snowSpr = null;
    snowTime = 0;
    snowTimeSpeed = 1;
    snowWidth = SNOW_BASE_WIDTH;
    snowBaseScaleX = 1;
    snowBaseScaleY = 1;
    snowSpeedTween = null;
    snowAlphaTween = null;
    snowWidthTween = null;
    barUp = null;
    barDown = null;
    barTween = null;
    barVis = 160;
    hintText = null;
    introBlack = null;
    cutsceneSound = null;
    cutsceneBf = null;
    darkLight = null;
    blend2 = null;
    snowman = null;
    ass = [];
    timers = [];
  }

  function getProp(name)
  {
    if (ps == null || ps.currentStage == null) return null;
    return ps.currentStage.getNamedProp(name);
  }

  function getScoreText()
  {
    var st = null;
    try
    {
      st = ps.scoreText;
    }
    catch (e:Dynamic)
    {
      st = null;
    }
    return st;
  }

  function storeHudBase()
  {
    hudStrumY = ps.playerStrumline.y;
    hudBarY = ps.healthBar.y;
    hudBarBgY = ps.healthBarBG.y;
    var st = getScoreText();
    if (st != null) hudScoreY = st.y;
  }

  function applyPlayerStrumlineMode()
  {
    if (AmMlpc.playerStrum())
    {
    ps.playerStrumline.strumlineScale.set(PLAYER_STRUM_SCALE, PLAYER_STRUM_SCALE);
    }
    if (CENTER_PLAYER_STRUMLINE) ps.playerStrumline.x = (FlxG.width - ps.playerStrumline.width) / 2;
  }

  function setIntroCamera()
  {
    if (ps.startTimestamp > 10) return;
    if (ps.currentStage == null) return;

    var bf = ps.currentStage.getBoyfriend();
    if (bf == null) return;

    var camPos = bf.cameraFocusPoint;
    ps.tweenCameraToPosition(camPos.x + 450, camPos.y + 300, 0);
  }

  function styleSubtitles()
  {
    if (ps.subtitles == null) return;

    var members = ps.subtitles.members;
    var i = 0;
    while (i < members.length)
    {
      var m = members[i];
      i = i + 1;
      if (m != null && Std.isOfType(m, FlxText))
      {
        m.font = Paths.font("RuthlessSketch.ttf");
        m.alpha = .8;
        m.size = 26;
      }
    }
  }

  function createHint()
  {
    var keyName = HINT_CONTROL;
    try
    {
      keyName = PlayerSettings.player1.controls.getDialogueNameFromToken(HINT_CONTROL, true);
    }
    catch (e:Dynamic)
    {
      keyName = HINT_CONTROL;
    }

    var hintMsg = "PRESS <M>" + keyName + "<M> to dodge or attack";
    #if mobile
    hintMsg = "TAP THE <M>CROSSHAIR<M> to dodge or attack";
    #end
    hintText = new FlxText(0, 0, FlxG.width, hintMsg.toUpperCase(), 32);
    hintText.scrollFactor.set();
    hintText.cameras = [ps.camCutscene];
    hintText.font = Paths.font("Blueprint.ttf");
    hintText.alignment = "center";
    hintText.y = FlxG.height - 65;
    hintText.color = FlxColor.PINK;
    hintText.visible = ps.currentDifficulty == "hard";
    hintText.alpha = 0;

    var marker = new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFD11B36), "<M>");
    hintText.applyMarkup(hintText.text, [marker]);
    ps.add(hintText);
  }

  function makeBlack()
  {
    var b = new FunkinSprite();
    b.makeSolidColor(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.BLACK);
    b.scrollFactor.set(0, 0);
    b.x = -FlxG.width;
    b.y = -FlxG.height;
    b.cameras = [ps.camCutscene];
    ps.add(b);
    return b;
  }

  function fadeOutBlack(b, time, ease)
  {
    FlxTween.tween(b, {alpha: 0}, time, {
      ease: ease,
      onComplete: function(_)
      {
        if (ps != null) ps.remove(b, true);
        b.destroy();
      }
    });
  }

  function tweenAlpha(obj, value, time, ease)
  {
    if (obj == null) return;
    FlxTween.tween(obj, {alpha: value}, time, {ease: ease});
  }

  function later(seconds, fn)
  {
    var t = new FlxTimer();
    t.start(seconds, fn);
    timers[timers.length] = t;
    return t;
  }

  function cancelTimers()
  {
    var i = 0;
    while (i < timers.length)
    {
      var t = timers[i];
      i = i + 1;
      if (t != null) t.cancel();
    }
    timers = [];
  }
}
