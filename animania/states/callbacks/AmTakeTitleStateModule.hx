import funkin.modding.module.Module;
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
class NewTitleStateModule extends Module
{
  function new()
  {
    super('NewTitleStateModule');
  }

  override function onStateChangeEnd(event:StateChangeScriptEvent):Void
  {
    super.onStateChangeEnd(event);

    var target = event.targetState;

    if (Std.isOfType(target, TitleState))
    {
      FlxG.switchState(new NewTitleState());
    }
  }

  function redirect(playIntro:Bool):Void
  {
    // NewMainMenuState consume esta bandera en create(): true = sin intro.
    FlxTransitionableState.skipNextTransIn = !playIntro;
  }
}
