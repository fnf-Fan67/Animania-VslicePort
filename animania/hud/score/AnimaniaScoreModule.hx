package animania.hud.score;

class AnimaniaScoreModule extends Module
{
  static var ATLAS_KEY:String = 'ui/ratings/GAMEPLAY_UI_ASSETS';
  static var ATLAS_LIBRARY:String = 'shared';
  static var NUMBERS:Array<String> = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'];
  static var MAX_DIGITS:Int = 9;

  static var WOBBLE_START_SCORE:Float = 10000;
  static var WOBBLE_SATURATE_SCORE:Float = 100000;

  public var scoreLabel:FunkinSprite = null;
  public var scoreDigits:Array<FunkinSprite>;
  public var scoreDigitBaseScale:Array<Float>;

  public var lastShownScore:Int = -1;
  public var usingScoreUI:Bool = false;

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

  public function new()
  {
    super('AnimaniaScoreModule', 200);
    scoreDigits = [];
    scoreDigitBaseScale = [];
  }

  public override function onCreate(event:ScriptEvent):Void
  {
    usingScoreUI = false;
  }

  public override function onStateChangeEnd(event:StateChangeScriptEvent):Void
  {
    usingScoreUI = false;

    if (Std.isOfType(event.targetState, PlayState))
    {
      if (isAllowedStage()) setupScoreUI();
      else disableScoreUI();
    }
  }

  public override function onSongRetry(event:SongRetryEvent):Void
  {
    if (isAllowedStage()) setupScoreUI();
    else disableScoreUI();
  }

  function disableScoreUI():Void
  {
    destroyScoreUI();

    var game:PlayState = PlayState.instance;
    if (game != null && game.scoreText != null) game.scoreText.alpha = 1;

    usingScoreUI = false;
  }

  function setupScoreUI():Void
  {
    var game:PlayState = PlayState.instance;
    if (game == null)
    {
      usingScoreUI = false;
      return;
    }

    destroyScoreUI();

    if (game.scoreText != null) game.scoreText.alpha = 0;

    var isDownscroll:Bool = AmScroll.isPref();
    var prefix:String = isDownscroll ? 'downscroll ' : '';
	var pauseButton:PlayState = game.pauseButton;

    var atlas = Paths.getSparrowAtlas(ATLAS_KEY, ATLAS_LIBRARY);

	scoreLabel = new FunkinSprite();
    scoreLabel.frames = atlas;
    scoreLabel.animation.addByPrefix('idle', prefix + 'score', 1, false);
    scoreLabel.animation.play('idle', true);
    scoreLabel.scale.set(0.55, 0.55);
    scoreLabel.updateHitbox();
    scoreLabel.x = FlxG.width - scoreLabel.width - 5;
    scoreLabel.y = isDownscroll ? 64 : (FlxG.height - scoreLabel.height - 62);
    scoreLabel.angle = isDownscroll ? -3.25 : 0;
    scoreLabel.scrollFactor.set();
    scoreLabel.cameras = [game.camHUD];
    scoreLabel.zIndex = 900;
    game.add(scoreLabel);

    scoreDigits = [];
    scoreDigitBaseScale = [];

    var prevDigit:FunkinSprite = null;

    for (i in 0...MAX_DIGITS)
    {
      var digit:FunkinSprite = new FunkinSprite();
      digit.frames = atlas;

      for (n in 0...NUMBERS.length)
      {
        digit.animation.addByPrefix(Std.string(n), prefix + NUMBERS[n], 1, false);
      }
      digit.animation.play('0', true);

      var scale:Float = (prevDigit == null) ? 0.75 : (scoreDigitBaseScale[i - 1] * 0.8825);
      digit.scale.set(scale, scale);
      digit.updateHitbox();

      if (prevDigit == null)
      {
        digit.x = FlxG.width - digit.width - 5;
      }
      else
      {
        digit.x = prevDigit.x - digit.width + 10;
      }
      digit.y = isDownscroll ? 5 : (FlxG.height - digit.height - 5);
      digit.angle = isDownscroll ? -3 : 0;
      digit.scrollFactor.set();
      digit.cameras = [game.camHUD];
      digit.zIndex = 899 - i;

      digit.visible = (i == 0);

      game.add(digit);
      scoreDigits.push(digit);
      scoreDigitBaseScale.push(scale);
      prevDigit = digit;
    }

    game.refresh();

    lastShownScore = -1;
    usingScoreUI = true;
    updateScoreDisplay(true);
  }

  function updateScoreDisplay(force:Bool = false):Void
  {
    var game:PlayState = PlayState.instance;
    if (game == null || scoreDigits.length == 0) return;

    var scoreInt:Int = Std.int(Math.max(0, game.songScore));
    if (!force && scoreInt == lastShownScore) return;
    lastShownScore = scoreInt;

    var chars:Array<String> = Std.string(scoreInt).split('');
    chars.reverse();

    for (i in 0...scoreDigits.length)
    {
      if (i < chars.length)
      {
        scoreDigits[i].visible = true;
        scoreDigits[i].animation.play(chars[i], true);
      }
      else
      {
        scoreDigits[i].visible = false;
      }
    }
  }

  public override function onUpdate(event:UpdateScriptEvent):Void
  {
    if (!usingScoreUI) return;

    var game:PlayState = PlayState.instance;
    if (game == null) return;

    updateScoreDisplay();

    var mdTime:Float = Conductor.instance.songPosition * 0.001;
    var scoreValue:Float = Math.max(0, lastShownScore - WOBBLE_START_SCORE);
    var t:Float = scoreValue / (WOBBLE_SATURATE_SCORE - WOBBLE_START_SCORE);
    var intensity:Float = Math.min(1.5, t);

    if (intensity <= 0) return;

    var isDownscroll:Bool = AmScroll.isPref();

	/*
    for (i in 0...scoreDigits.length)
    {
      var spr:FunkinSprite = scoreDigits[i];
      if (spr == null || !spr.visible) continue;

      var phase:Float = i * 0.55;

	  spr.offset.x = -Math.cos(mdTime * 2.0 + phase) * (0.12 + intensity * 0.55) + 40;
      spr.offset.y = -Math.sin(mdTime * 2.6 + phase) * (0.25 + intensity * 1.2) + 20;

      var scale:Float = scoreDigitBaseScale[i] + Math.sin(mdTime * 3.2 + phase) * (0.002 + intensity * 0.010);
      spr.scale.set(scale, scale);

      spr.angle = (isDownscroll ? -3 : 0) + Math.sin(mdTime * 1.8 + phase) * (0.2 + intensity * 0.8);
    }
	*/

	/*
    if (scoreLabel != null)
    {
      scoreLabel.offset.x = -Math.cos(mdTime * 1.7) * (0.08 + intensity * 0.35) + 75;
      scoreLabel.offset.y = Math.sin(mdTime * 2.0) * (0.15 + intensity * 0.65) + 45;
      scoreLabel.angle = (isDownscroll ? -3.25 : 0) + Math.sin(mdTime * 1.4) * (0.15 + intensity * 0.5);
    }
	*/
  }

  function destroyScoreUI():Void
  {
    var game:PlayState = PlayState.instance;

    if (scoreLabel != null)
    {
      if (game != null) game.remove(scoreLabel, true);
      scoreLabel.destroy();
      scoreLabel = null;
    }

    for (digit in scoreDigits)
    {
      if (digit == null) continue;
      if (game != null) game.remove(digit, true);
      digit.destroy();
    }
    scoreDigits = [];
    scoreDigitBaseScale = [];
  }

  public override function onDestroy(event:ScriptEvent):Void
  {
    usingScoreUI = false;

    if (PlayState.instance != null && PlayState.instance.scoreText != null)
    {
      PlayState.instance.scoreText.alpha = 1;
    }

    destroyScoreUI();
  }
}
