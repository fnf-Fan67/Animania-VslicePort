package animania.hud.rating;

class RatingComboModule extends Module implements IPlayStateScriptedClass
{
  public function new()
  {
    super("RatingComboModule", 200);
  }

  static var MEGA_ALLOWED_STAGES:Array<String> = [
    "mainStageAmTake",
    "serviceEnterance",
    "xMasCityMallAmTake",
    "xMasCityMallAmTakeDark",
    "xMasCityMallNastyAmTake",
	"phoneCallStreet"
  ];

  function isAllowedStage():Bool
  {
    var play = PlayState.instance;
    if (play == null || play.currentStage == null) return false;
    return MEGA_ALLOWED_STAGES.indexOf(play.currentStage.id) != -1;
  }

  var NUMBERS:Array<String> = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"];
  var SHOW_COMBO_VALUE:Int = 25;
  var SHOW_COMBONUMS_VALUE:Int = 15;
  var comboBlotColors:Array<Int> = [0xFF6666FF, 0xFFFF66CC, 0xFFFFCC99, 0xFF66FF99, 0xFF66FF99];
  var comboBlotColorsMax:Array<Int> = [50, 100, 200, 300];

  public var offsets:Array<Int> = [0, 0];

  public var stageOffsets:Array<Int> = [0, 0];

  public var variation:Bool = true;
  public var previousComboStuff:Array<Array<Dynamic>> = [];

  public var ratingPopUps:FunkinGroup = null;

  public var blot:FunkinSprite = null;

  var popupsInStage:Bool = false;

  /**
   * Emulates the Codename Engine sprite `zoomFactor` (the fork used 0.5 on every popup):
   * 1 = the popup scales with the camera zoom like any other object, 0 = it keeps its original size no matter the zoom.
   */
  public var popupZoomFactor:Float = 0.5;

  var popupStates:Array<Array<Dynamic>> = [];

  var popupPostUpdate:Dynamic = null;

  /**
   * Offset [x, y] applied to the popups on each stage. (was `ratingsOffset`)
   */
  function getStageRatingOffset(stageId:String):Array<Int>
  {
    return switch (stageId)
    {
      case "mainStageAmTake": [-35, 100];
      case "xMasCityMallAmTake": [-450, -150];
	  case "xMasCityMallAmTakeDark": [-450, -150];
      case "xMasCityMallNastyAmTake": [-730, -725];
	  case "phoneCallStreet": [180, 500];
      default: [0, 0];
    }
  }

  /**
   * zIndex of the popups inside the stage. (was `popupZIndex`)
   * `null` = not inside the stage, they're drawn on top of it like before.
   */
  function getStagePopupZIndex(stageId:String):Dynamic
  {
    return switch (stageId)
    {
	  case "serviceEnterance": 20;
      case "xMasCityMallNastyAmTake": 118;
      default: null;
    }
  }

  override function onStateChangeEnd(event:StateChangeScriptEvent):Void
  {
    super.onStateChangeEnd(event);
    if (Std.isOfType(event.targetState, PlayState))
    {
      if (isAllowedStage()) setup();
      else teardown();
    }
  }

  override function onSubStateOpenEnd(event:SubStateScriptEvent):Void
  {
    super.onSubStateOpenEnd(event);
    if (Std.isOfType(event.targetState, PlayState))
    {
      if (isAllowedStage()) setup();
      else teardown();
    }
  }

  override function onDestroy(event:ScriptEvent):Void
  {
    super.onDestroy(event);
    teardown();
  }

  function setup():Void
  {
    var play = PlayState.instance;
    if (play == null)
      return;

    previousComboStuff = [];
    popupStates = [];
    variation = true;

    destroyPopupGroup();

    var stageId:String = (play.currentStage != null) ? play.currentStage.id : "";
    stageOffsets = getStageRatingOffset(stageId);
    var popupZ:Dynamic = getStagePopupZIndex(stageId);

    ratingPopUps = new FunkinGroup();
    ratingPopUps.customChildUpdate = true;

    if (popupZ != null && play.currentStage != null)
    {
      ratingPopUps.zIndex = popupZ;
      play.currentStage.add(ratingPopUps);
      play.currentStage.refresh();
      popupsInStage = true;
    }
    else
    {
      play.add(ratingPopUps);
      popupsInStage = false;
    }

    ratingPopUps.cameras = [play.camGame];

    if (play.comboPopUps != null)
      play.comboPopUps.visible = false;

    removePostUpdateHook();
    popupPostUpdate = applyPopupTransforms;
    FlxG.signals.postUpdate.add(popupPostUpdate);
  }

  function removePostUpdateHook():Void
  {
    if (popupPostUpdate != null)
    {
      FlxG.signals.postUpdate.remove(popupPostUpdate);
      popupPostUpdate = null;
    }
  }

  function teardown():Void
  {
    removePostUpdateHook();
    clearRatingStuff();
    destroyPopupGroup();

    var play = PlayState.instance;
    if (play != null && play.comboPopUps != null)
      play.comboPopUps.visible = true;
  }

  /**
   * True while the group can still be used. Stage.onDestroy() destroys everything inside the stage,
   * and FunkinGroup.destroy() sets `children` to null, so touching it afterwards would crash.
   */
  function isPopupGroupAlive():Bool
  {
    return ratingPopUps != null && ratingPopUps.children != null;
  }

  function destroyPopupGroup():Void
  {
    if (ratingPopUps == null)
      return;

    if (isPopupGroupAlive())
    {
      var play = PlayState.instance;
      if (play != null)
      {
        if (popupsInStage && play.currentStage != null)
          play.currentStage.remove(ratingPopUps);
        else
          play.remove(ratingPopUps);
      }
      ratingPopUps.destroy();
    }

    ratingPopUps = null;
    popupsInStage = false;
  }

  function clearRatingStuff():Void
  {
    if (!isPopupGroupAlive())
    {
      previousComboStuff = [];
      popupStates = [];
      return;
    }

    for (shit in previousComboStuff)
    {
      if (shit == null)
        continue;

      var spr:FunkinSprite = shit[0];
      if (spr == null)
        continue;

      FlxTween.cancelTweensOf(spr);
      ratingPopUps.remove(spr);
      spr.destroy();
    }

    previousComboStuff = [];
    popupStates = [];
  }

  function getRatingOffset(curRating:String):Array<Int>
  {
    return switch (curRating)
    {
      case "good": [-10, -10];
      default: [0, 0];
    }
  }

  function constructComboSprite(rating:FunkinSprite, frames):FunkinSprite
  {
    var comboSpr:FunkinSprite = new FunkinSprite();
    comboSpr.frames = frames;
    comboSpr.animation.addByPrefix("combo", "combo", 24, false);
    comboSpr.animation.play("combo");
    comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.55));
    comboSpr.updateHitbox();
    if (rating != null)
      comboSpr.setPosition((rating.x + rating.width) - comboSpr.width / 1.5, rating.y + rating.height);
    return comboSpr;
  }

  function constructComboNumberSprite(currentNumber:String, frames):FunkinSprite
  {
    var num:FunkinSprite = new FunkinSprite();
    num.frames = frames;
    num.animation.addByPrefix(currentNumber, currentNumber, 24, false);
    num.animation.play(currentNumber);
    return num;
  }

  function createRatingImg(rat:String):Void
  {
    var play = PlayState.instance;
    if (play == null || !isPopupGroupAlive())
      return;

    if (rat == null)
      rat = "good";

    var ratingsFrames = Paths.getSparrowAtlas("ui/ratings/GAMEPLAY_UI_ASSETS", "shared");
    var daRating:String = rat;
    var combo:Int = Highscore.tallies.combo;
    var dissapearTimeMult:Float = 1;

    if (daRating == "fuck up")
      dissapearTimeMult = 1.25;

    clearRatingStuff();

    blot = new FunkinSprite();
    blot.frames = ratingsFrames;
    blot.animation.addByPrefix('blot1', "blot0", 24, false);
    blot.animation.addByPrefix('blot2', "blot 2", 24, false);
    blot.x = (FlxG.width * 0.474) + offsets[0] + stageOffsets[0];
    blot.y = (FlxG.camera.height * 0.45 - 60) + offsets[1] + stageOffsets[1];
    blot.setGraphicSize(Std.int(blot.width * 0.6));
    blot.updateHitbox();
    blot.offset.x += 15;
    previousComboStuff.push([blot, true]);
    variation = !variation;
    blot.animation.play("blot" + (variation ? 1 : 2));
    if (blot.animation.curAnim.name == "blot2")
      blot.offset.y += 15;
    blot.origin.set(blot.frameWidth * .4, blot.frameHeight * .4);
    blot.angle = FlxG.random.float(-15, 15);

    if (daRating != "fuck up")
    {
      var currentColorPoint:Int = 0;
      for (i in 0...comboBlotColorsMax.length - 1)
      {
        currentColorPoint = i;
        if (combo < comboBlotColorsMax[i])
          break;
      }

      var prevMax:Int = currentColorPoint > 0 ? comboBlotColorsMax[currentColorPoint - 1] : comboBlotColorsMax[currentColorPoint];
      var cfv:Int = comboBlotColorsMax[currentColorPoint] - prevMax;
      blot.color = FlxColor.interpolate(comboBlotColors[currentColorPoint], comboBlotColors[currentColorPoint + 1],
        (combo - cfv) / (comboBlotColorsMax[currentColorPoint] - cfv));
    }
    else
      blot.color = FlxColor.GRAY;

	ModuleHandler.getModule('TimeBarModule').bar.color = blot.color;

    var rating:FunkinSprite = new FunkinSprite();
    rating.frames = ratingsFrames;
    rating.animation.addByPrefix(daRating, daRating, 24, false);
    rating.setPosition(blot.x - 100, blot.y + 35);
    rating.setGraphicSize(Std.int(rating.width * 0.55));
    rating.updateHitbox();
    previousComboStuff.push([rating, true]);
    rating.animation.play(daRating);
    var offss:Array<Int> = getRatingOffset(daRating);
    rating.offset.set(offss[0], offss[1]);

    var comboSpr:FunkinSprite = null;
    if (combo >= SHOW_COMBO_VALUE)
    {
      comboSpr = constructComboSprite(rating, ratingsFrames);
      if (daRating == "fuck up")
        comboSpr.color = FlxColor.GRAY;
      previousComboStuff.push([comboSpr, true]);
    }

    if (combo >= SHOW_COMBONUMS_VALUE)
    {
      var seperatedScore:Array<Int> = [];
      var tempCombo:Int = combo;

      while (tempCombo != 0)
      {
        seperatedScore.push(tempCombo % 10);
        tempCombo = Std.int(tempCombo / 10);
      }
      while (seperatedScore.length < 3)
        seperatedScore.push(0);

      seperatedScore.reverse();

      var daLoop:Int = 0;
      var previousNumber:FunkinSprite = null;
      for (i in seperatedScore)
      {
        var cnumber:FunkinSprite = constructComboNumberSprite(NUMBERS[i], ratingsFrames);
        var currentScale:Float = .45 + (daLoop * .1);
        cnumber.scale.set(currentScale, currentScale);
        cnumber.updateHitbox();
        cnumber.setPosition(blot.x + blot.width * .65, blot.y + blot.height * 1.25 - cnumber.height / 2 * cnumber.scale.y);
        if (previousNumber != null)
        {
          cnumber.x = previousNumber.x + previousNumber.frameWidth * .75 * previousNumber.scale.x;
          cnumber.y = previousNumber.y + (previousNumber.height / 2 * previousNumber.scale.y) - (cnumber.height / 1.725 * cnumber.scale.y);
        }

        cnumber.angularVelocity = FlxG.random.int(-15, 15);

        previousNumber = cnumber;
        if (daRating == "fuck up")
          cnumber.color = FlxColor.GRAY;
        previousComboStuff.push([cnumber, true]);
        daLoop++;
      }
    }
    else
    {
      rating.x += 50;
      rating.y += 50 - blot.offset.y / 2;
    }

    var comboColors:Array<Int> = null;
    if (Highscore.tallies.sick == Highscore.tallies.totalNotesHit && Highscore.tallies.missed == 0)
      comboColors = FlxColor.gradient(blot.color, FlxColor.WHITE, 5, FlxEase.linear);

    for (shit in previousComboStuff)
    {
      var baseShit:FunkinSprite = shit[0];
      if (baseShit == null)
        continue;

      if (shit[1])
      {
        baseShit.scrollFactor.set(.85, .85);
        baseShit.antialiasing = true;
        baseShit.angle = FlxG.random.int(-5, 5);
        baseShit.angularVelocity += FlxG.random.int(-5, 5);

        popupStates.push([
          baseShit,
          baseShit.x,
          baseShit.y,
          -FlxG.random.int(0, 10),
          -FlxG.random.int(160, 175),
          650,
          baseShit.scale.x,
          baseShit.scale.y,
          0.0
        ]);

        if (comboColors != null && baseShit != blot)
        {
          baseShit.color = comboColors[3];
          FlxTween.color(baseShit, Conductor.instance.beatLengthMs * 0.001 * dissapearTimeMult, comboColors[3], comboColors[1], {ease: FlxEase.sineOut});
        }
      }

      baseShit.cameras = [play.camGame];
      ratingPopUps.add(baseShit);

      startFade(baseShit, dissapearTimeMult);
    }

    applyPopupTransforms();
  }

  override function onUpdate(event:UpdateScriptEvent):Void
  {
    super.onUpdate(event);

    for (st in popupStates)
      st[8] = st[8] + event.elapsed;
  }

  /**
   * Moves/scales every popup for the current frame, emulating Codename's `zoomFactor`.
   *
   * Codename scales what it draws around the center of the camera by lerp(1 / zoom, 1, zoomFactor), which makes the
   * effective zoom of the sprite lerp(1, zoom, zoomFactor). Vanilla has no such thing, so the same is done here:
   * the sprite scale gets multiplied by that value and its origin point is moved around the camera center.
   */
  function applyPopupTransforms():Void
  {
    var play = PlayState.instance;
    if (play == null || play.camGame == null || popupStates.length == 0)
      return;

    try
    {
      var cam = play.camGame;
      var zoom:Float = cam.zoom;
      if (zoom <= 0)
        zoom = 1;

      var ratio:Float = 1 / zoom + (1 - 1 / zoom) * popupZoomFactor;
      var cx:Float = cam.width * 0.5;
      var cy:Float = cam.height * 0.5;

      for (st in popupStates)
      {
        var spr:FunkinSprite = st[0];
        if (spr == null || !spr.exists)
          continue;

        var t:Float = st[8];
        var lx:Float = st[1] + st[3] * t;
        var ly:Float = st[2] + st[4] * t + 0.5 * st[5] * t * t;

        var sfx:Float = spr.scrollFactor.x;
        var sfy:Float = spr.scrollFactor.y;

        var ox:Float = lx - cam.scroll.x * sfx - spr.offset.x + spr.origin.x;
        var oy:Float = ly - cam.scroll.y * sfy - spr.offset.y + spr.origin.y;

        ox = cx + (ox - cx) * ratio;
        oy = cy + (oy - cy) * ratio;

        spr.x = ox + cam.scroll.x * sfx + spr.offset.x - spr.origin.x;
        spr.y = oy + cam.scroll.y * sfy + spr.offset.y - spr.origin.y;
        spr.scale.set(st[6] * ratio, st[7] * ratio);
      }
    }
    catch (e:Dynamic)
    {
      trace("[RatingComboModule] applyPopupTransforms failed: " + e);
      popupStates = [];
    }
  }

  /**
   * Fades the sprite out after one beat and kills it when done (stops updating its physics).
   */
  function startFade(spr:FunkinSprite, delayMult:Float):Void
  {
    var beat:Float = Conductor.instance.beatLengthMs * 0.001;

    FlxTween.tween(spr, {
      alpha: 0,
      angle: spr.angle + FlxG.random.float(-16, 16)
    }, beat / 1.5, {
      ease: FlxEase.cubeOut,
      startDelay: beat * delayMult,
      onComplete: function(_:FlxTween):Void
      {
        spr.kill();
      }
    });
  }

  override function onNoteHit(event:HitNoteScriptEvent):Void
  {
    super.onNoteHit(event);
    if (PlayState.instance == null || !isPopupGroupAlive())
      return;
    if (!event.note.noteData.getMustHitNote())
      return;

    if (event.isComboBreak)
    {
      if (event.comboCount > 1)
        createRatingImg("fuck up");
      return;
    }

    createRatingImg(event.judgement);
  }

  override function onNoteMiss(event:NoteScriptEvent):Void
  {
    super.onNoteMiss(event);
    if (PlayState.instance == null || !isPopupGroupAlive())
      return;
    if (!event.note.noteData.getMustHitNote())
      return;

    if (event.comboCount > 1)
      createRatingImg("fuck up");
  }
}
