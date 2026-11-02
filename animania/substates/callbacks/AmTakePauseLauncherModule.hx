package animania.substates.callbacks;

import animania.substates.NewPauseSubState;
import funkin.modding.module.Module;
import funkin.modding.events.ScriptEvent;
import funkin.play.PlayState;
import funkin.play.PauseSubState;
import funkin.ui.ScriptedMusicBeatSubState;

class NewPauseLauncherModule extends Module
{
  var opening:Bool = false;

  public function new()
  {
    super('NewPauseLauncherModule', 1);
  }

  public override function onSubStateOpenBegin(event:ScriptEvent):Void
  {
    if (opening) return;

    var target = event.targetState;
    if (!Std.isOfType(target, PauseSubState)) return;

    var ps = PlayState.instance;
    if (ps == null) return;

    if (ps.isInCutscene || ps.currentConversation != null || ps.isChartingMode) return;

    event.cancelEvent();

    opening = true;
    var sub = new NewPauseSubState();
    sub.camera = ps.camPause;
    ps.openSubState(sub);
    opening = false;
  }
}
