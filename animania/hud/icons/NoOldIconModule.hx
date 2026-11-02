package animania.hud.icons;

import funkin.modding.module.Module;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.play.PlayState;
import funkin.play.components.HealthIcon;
import funkin.util.TouchUtil;
import flixel.FlxG;

/**
 * NoOldIconModule
 * Desactiva el easter egg de la tecla 9 / tap al icono de BF (HealthIcon.toggleOldIcon)
 * SOLO en los stages de MEGA_ALLOWED_STAGES (la misma lista que usan TimeBarModule,
 * AnimaniaScoreModule, AnimaniaModule, AnimaniaStuff, CurvedHealthBarModule,
 * RatingComboModule y FullComboModule). En cualquier otro stage el easter egg sigue igual.
 *
 * Por que asi: el chequeo de la tecla 9 / toque esta dentro de PlayState.debugKeyShit() (compilado),
 * no se puede cancelar desde script.
 *
 * ANTES: se dejaba que el toggle ocurriera y se deshacia llamando toggleOldIcon() otra vez. Pero esa ruta
 * de vuelta (initHealthIcon -> configure -> loadCharacter) recarga el icono desde cero: borra las animaciones
 * que agrega AnimaniaStuff (death, toDeath...), resetea size / iconOffset / escala y recoloca el icono con la
 * formula de la barra de vida (por eso "se ponia mas arriba"). Ese estado roto se arrastraba y, por ejemplo,
 * en winter horrorland el icono se centraba mas a la izquierda en la cruceta.
 *
 * AHORA: el toggle nunca toca al icono real. En PlayState.update() los modulos reciben onUpdate ANTES de
 * debugKeyShit(), asi que en el frame en que se presiona 9 (o se toca el icono) se cambia temporalmente
 * PlayState.iconP1 por un icono señuelo (no esta en pantalla). debugKeyShit() hace el toggle sobre el señuelo y
 * en postUpdate se devuelve el icono real. El icono real no se mueve, no se recarga y no pierde nada.
 * Si por algun motivo el cambio no se pudo hacer, queda la ruta vieja (toggle de vuelta) como respaldo.
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

  // icono señuelo que recibe el toggle en lugar del icono real
  var decoyIcon = null;
  var realIcon = null;
  var swapped:Bool = false;

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
      swapOut();
      guardIcon();
    };
    FlxG.signals.postUpdate.add(postFn);
  }

  function detach():Void
  {
    swapOut();
    if (postFn == null) return;
    FlxG.signals.postUpdate.remove(postFn);
    postFn = null;
    trackedIcon = null;
    lastIconId = "";
  }

  // Misma condicion que usa PlayState.debugKeyShit(): tecla 9, o toque justo sobre el icono de BF.
  function togglePressed(icon):Bool
  {
    if (FlxG.keys.justPressed.NINE) return true;

    try
    {
      if (TouchUtil.justPressed && TouchUtil.overlapsComplex(icon)) return true;
    }
    catch (e:Dynamic) {}

    return false;
  }

  // Antes de debugKeyShit(): si este frame se va a disparar el toggle, que le caiga al señuelo.
  function swapIn():Void
  {
    if (swapped || !isAllowedStage()) return;

    var play = PlayState.instance;
    if (play == null) return;

    var icon = play.iconP1;
    if (icon == null || !togglePressed(icon)) return;

    try
    {
      if (decoyIcon == null) decoyIcon = new HealthIcon('bf', 0);
      // siempre 'bf' para que el toggle tome la rama simple (carga bf-old) y nunca toque nada del juego
      decoyIcon.characterId = 'bf';
      decoyIcon.autoUpdate = false;

      realIcon = icon;
      play.iconP1 = decoyIcon;
      swapped = true;
    }
    catch (e:Dynamic)
    {
      realIcon = null;
      swapped = false;
    }
  }

  // Despues del update: devolver el icono real.
  function swapOut():Void
  {
    if (!swapped) return;

    var play = PlayState.instance;
    if (play != null && realIcon != null) play.iconP1 = realIcon;

    realIcon = null;
    swapped = false;
  }

  // Respaldo: si el icono real llego a cambiar a bf-old, se devuelve con el toggle del propio juego.
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
      icon.toggleOldIcon();
      id = Std.string(icon.characterId);
    }

    lastIconId = id;
  }

  override function onUpdate(event:UpdateScriptEvent):Void
  {
    super.onUpdate(event);
    attach();
    swapIn();
  }

  override function onDestroy(event:ScriptEvent):Void
  {
    super.onDestroy(event);
    detach();

    if (decoyIcon != null)
    {
      decoyIcon.kill();
      decoyIcon.destroy();
      decoyIcon = null;
    }
  }
}
