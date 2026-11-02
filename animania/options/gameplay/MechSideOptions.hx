package animania.options.gameplay;

import funkin.modding.module.Module;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEvent.StateChangeScriptEvent;
import funkin.save.Save;
import funkin.ui.options.OptionsState;
import haxe.ds.StringMap;

/**
 * MechSideOptions
 * Agrega a Options > Preferences la opcion "mechanics side" (SOLO MOBILE).
 *
 *   Center = en medio de la pantalla (no es la posicion de PC)
 *   Left   = extremo izquierdo de la pantalla
 *   Right  = extremo derecho de la pantalla (default)
 *
 * Guarda en Save.instance.modOptions['mechSide'] como String, que es exactamente
 * lo que ya lee mechSide() / mechPlaceMobile() en WinterHorrorlandAnimaniaSong.
 * En PC el modulo no hace nada (la cruceta de PC queda donde esta).
 */
class MechSideOptions extends Module
{
  var save = null;
  var optionsState = null;
  var preferences = null;

  function new()
  {
    super('MechSideOptions', 1000, {state: OptionsState});
  }

  override function onCreate(event:ScriptEvent):Void
  {
    super.onCreate(event);

    #if mobile
    save = Save.instance;
    if (save.modOptions['mechSide'] == null)
    {
      save.modOptions['mechSide'] = 'Right';
      save.flush();
    }
    #end
  }

  function getSide():String
  {
    if (save == null) save = Save.instance;
    var v = save.modOptions['mechSide'];
    if (v == null) return 'Right';
    v = Std.string(v);
    if (v == 'Left' || v == 'Center' || v == 'Right') return v;
    return 'Right';
  }

  function buildOptions():Void
  {
    optionsState = OptionsState.instance;
    save = Save.instance;
    preferences = optionsState.optionsCodex.pages.get('preferences');
    if (preferences == null) return;

    var values = new StringMap();
    values.set('Center', 'Center');
    values.set('Left', 'Left');
    values.set('Right', 'Right');

    @:privateAccess
    preferences.createPrefItemEnum(
      'mechanics side',
      'Where the mechanics button (crosshair) appears on mobile. Center = middle of the screen, Left/Right = screen edges',
      values,
      function(key:String, value:String):Void
      {
        save.modOptions['mechSide'] = value;
        save.flush();
      },
      getSide()
    );
  }

  override function onStateChangeEnd(event:StateChangeScriptEvent):Void
  {
    super.onStateChangeEnd(event);

    #if mobile
    if (Std.isOfType(event.targetState, OptionsState)) buildOptions();
    #end
  }
}
