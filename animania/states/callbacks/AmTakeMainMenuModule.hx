import funkin.modding.module.Module;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.title.TitleState;
import flixel.addons.transition.FlxTransitionableState;
import Reflect;

/**
 * Reemplaza el MainMenuState original del juego por NewMainMenuState.
 *
 * Cada vez que el juego entra al MainMenuState original (desde el título, al salir de Story/Options/Credits/Freeplay,
 * al terminar una canción, etc.) este módulo lo redirige al menú nuevo. Es el ÚNICO sitio que hace esa redirección:
 * NewMainMenuState ya no instala la suya.
 *
 *  - Intro: solo se reproduce al venir de la pantalla de título. En cualquier otra entrada se salta
 *    (NewMainMenuState lee FlxTransitionableState.skipNextTransIn como la señal de "no hacer intro").
 *  - Excepción: el MainMenuState que FreeplayState.build() crea como "host" de Freeplay (al volver de una canción)
 *    NO se redirige hasta que Freeplay se cierra; si no, se rompería esa pantalla.
 *  - Para volver temporalmente al menú original basta con poner ENABLED = false.
 */
class NewMainMenuModule extends Module
{
  var ENABLED:Bool = true;

  // true = la próxima entrada al menú viene del título (o es la primera del juego) y debe llevar intro.
  var cameFromTitle:Bool = true;

  function new()
  {
    super('NewMainMenuModule');
  }

  override function onStateChangeEnd(event:StateChangeScriptEvent):Void
  {
    super.onStateChangeEnd(event);

    var target = event.targetState;

    if (ENABLED && Std.isOfType(target, MainMenuState) && !isFreeplayHost(target))
    {
      redirect(cameFromTitle);
    }

    cameFromTitle = Std.isOfType(target, TitleState);
  }

  /**
   * Freeplay creado desde resultados/PlayState: FreeplayState.build() devuelve un MainMenuState(true) con Freeplay
   * encima. Cuando Freeplay se cierra con ese padre, solo hace close() y dejaría ver el menú original:
   * ahí entra onSubStateCloseEnd.
   */
  function isFreeplayHost(state:Dynamic):Bool
  {
    return Reflect.field(state, 'overrideMusic') == true || state.subState != null;
  }

  override function onSubStateCloseEnd(event:SubStateScriptEvent):Void
  {
    super.onSubStateCloseEnd(event);

    if (!ENABLED) return;
    if (!Std.isOfType(FlxG.state, MainMenuState)) return;
    if (!Std.isOfType(event.targetState, FreeplayState)) return;

    redirect(false);
  }

  function redirect(playIntro:Bool):Void
  {
    // NewMainMenuState consume esta bandera en create(): true = sin intro.
    FlxTransitionableState.skipNextTransIn = !playIntro;
    FlxG.switchState(new NewMainMenuState());
  }
}
