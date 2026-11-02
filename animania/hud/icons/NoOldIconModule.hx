package animania.hud.icons;

import funkin.modding.module.Module;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.play.PlayState;
import flixel.FlxG;

/**
 * NoOldIconModule
 * Desactiva el easter egg de la tecla 9 / tap al icono de BF (HealthIcon.toggleOldIcon)
 * SOLO en los stages de MEGA_ALLOWED_STAGES (la misma lista que usan TimeBarModule,
 * AnimaniaScoreModule, AnimaniaModule, AnimaniaStuff, CurvedHealthBarModule,
 * RatingComboModule y FullComboModule). En cualquier otro stage el easter egg sigue igual.
 *
 * Por que asi: el chequeo de la tecla 9 / toque esta dentro de PlayState.debugKeyShit() (compilado),
 * no se puede cancelar desde script. Entonces dejamos que ocurra y lo deshacemos en
 * FlxG.signals.postUpdate (despues del update, antes del draw), asi que nunca se llega a ver el icono viejo.
 * Para deshacerlo se vuelve a llamar toggleOldIcon(), que es la propia ruta de restauracion del juego.
 */
class NoOldIconModule extends Module
{
  static var MEGA_ALLOWED_STAGES:Array<String> = [
    "mainStageAmTake",
    "serviceEnterance",
    "xMasCityMallAmTake",
    "xMasCityMallAmTakeDark",
    "xMasCityMallNastyAmTake",
    "phoneCallStreet"
  ];

  var postFn = null;
  var trackedIcon = null;
  var lastIconId = "";

  function new()
  {
    super('NoOldIconModule', 1000, {state: PlayState});
  }

  function isAllowedStage():Bool
  {
    var play = PlayState.instance;
    if (play == null || play.currentStage == null) return false;
    return MEGA_ALLOWED_STAGES.indexOf(play.currentStage.id) != -1;
  }

  function attach():Void
  {
    if (postFn != null) return;
    postFn = function()
    {
      guardIcon();
    };
    FlxG.signals.postUpdate.add(postFn);
  }

  function detach():Void
  {
    if (postFn == null) return;
    FlxG.signals.postUpdate.remove(postFn);
    postFn = null;
    trackedIcon = null;
    lastIconId = "";
  }

  function guardIcon():Void
  {
    var play = PlayState.instance;
    if (play == null)
    {
      detach();
      return;
    }

    var icon = play.iconP1;
    if (icon == null) return;

    // Icono nuevo (primer frame o restart): solo memorizamos su id actual.
    if (icon != trackedIcon)
    {
      trackedIcon = icon;
      lastIconId = Std.string(icon.characterId);
      return;
    }

    var id = Std.string(icon.characterId);

    if (isAllowedStage() && id == 'bf-old' && lastIconId != 'bf-old')
    {
      // Alguien (tecla 9 o tap) lo cambio en este frame: lo devolvemos.
      icon.toggleOldIcon();
      id = Std.string(icon.characterId);
    }

    lastIconId = id;
  }

  override function onUpdate(event:UpdateScriptEvent):Void
  {
    super.onUpdate(event);
    attach();
  }

  override function onDestroy(event:ScriptEvent):Void
  {
    super.onDestroy(event);
    detach();
  }
}
