package animania.modules;

import funkin.modding.module.Module;
import funkin.modding.events.ScriptEvent;
import funkin.play.PlayState;
import funkin.save.Save;
import funkin.audio.FunkinSound;
import funkin.Paths;
import flixel.FlxG;
import Reflect;

class GameplayOptionsModule extends Module
{
  var MOD_OPTIONS_ID:String = 'animania';

  public function new()
  {
    super('GameplayOptionsModule', 10000);
  }

  function opt(key:String, defaultValue:Dynamic):Dynamic
  {
    var o = Save.instance.getModOptions(MOD_OPTIONS_ID);
    if (o == null) return defaultValue;
    var v = Reflect.field(o, key);
    if (v == null) return defaultValue;
    return v;
  }

  public override function onUpdate(event:UpdateScriptEvent):Void
  {
    super.onUpdate(event);

    var ps = PlayState.instance;
    if (ps == null) return;

    if (ModuleHandler.getModule('RatingComboModule').ratingPopUps != null) ModuleHandler.getModule('RatingComboModule').ratingPopUps.visible = opt('showJudges', true);

    var splashes:Bool = opt('noteSplashes', true);
    if (ps.playerStrumline != null) ps.playerStrumline.showNotesplash = splashes;
    if (ps.opponentStrumline != null) ps.opponentStrumline.showNotesplash = splashes;

    if (!opt('cameraShake', true))
    {
      killShake(ps.camGame);
      killShake(ps.camHUD);
      killShake(ps.camCutscene);
    }
  }

  function killShake(cam:Dynamic):Void
  {
    if (cam == null) return;
    try
    {
      cam.stopShake();
    }
    catch (e:Dynamic)
    {
      cam.shake(0, 0);
    }
  }

  function playMissSound():Void
  {
    var vol:Float = Std.parseFloat(Std.string(opt('missVolume', 0.2)));
    if (Math.isNaN(vol)) vol = 0.2;
    if (vol > 0) FunkinSound.playOnce(Paths.soundRandom('missnote', 1, 3), vol);
  }

  function muteVocals(ps:Dynamic, opponentToo:Bool):Void
  {
    var vocals = ps.vocals;
    if (vocals == null) return;

    var tempVocals:Bool = false;
    if (ps.currentStage != null)
    {
      var bf = ps.currentStage.getBoyfriend();
      if (bf != null) tempVocals = bf.tempVocals;
    }

    if (!tempVocals) vocals.playerVolume = 0;
    if (opponentToo && vocals.legacyVoiceSystem && !vocals.legacyVoiceUsesPlayer) vocals.opponentVolume = 0;
  }

  public override function onNoteMiss(event:NoteScriptEvent):Void
  {
    super.onNoteMiss(event);

    var ps = PlayState.instance;
    if (event.eventCanceled || ps == null || ps.isBotPlayMode || !event.playSound) return;

    event.playSound = false;
    muteVocals(ps, false);
    playMissSound();
  }

  public override function onNoteGhostMiss(event:GhostMissNoteScriptEvent):Void
  {
    super.onNoteGhostMiss(event);

    var ps = PlayState.instance;
    if (event.eventCanceled || ps == null || !event.playSound) return;

    event.playSound = false;
    muteVocals(ps, false);
    playMissSound();
  }

  public override function onNoteHoldDrop(event:HoldNoteScriptEvent):Void
  {
    super.onNoteHoldDrop(event);

    var ps = PlayState.instance;
    if (event.eventCanceled || ps == null || !event.playSound) return;

    event.playSound = false;
    muteVocals(ps, true);
    playMissSound();
  }
}