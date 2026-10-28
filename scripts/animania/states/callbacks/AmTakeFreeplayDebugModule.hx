import funkin.modding.module.Module;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.ui.MusicBeatState;
import Reflect;

/**
 * TEMPORAL (solo para probar el Freeplay AmTake mientras se construye por capas).
 * Estando en el menú principal nuevo, F6 abre AmTakeFreeplayState. Cuando el Freeplay esté terminado se borra
 * y el botón Freeplay del menú apunta directo a él.
 */
class AmTakeFreeplayDebugModule extends Module
{
  public function new()
  {
    super('amTakeFreeplayDebugModule');
  }

  public override function onUpdate(event:UpdateScriptEvent):Void
  {
    super.onUpdate(event);

    if (!FlxG.keys.justPressed.F1) return;

    var st:Dynamic = FlxG.state;
    if (st == null || !Std.isOfType(st, MusicBeatState)) return;

    if (FlxG.state.subState != null) return;

    FlxG.switchState(new AmTakeFreeplayState());
  }
}
