import funkin.modding.module.Module;
import funkin.modding.events.ScriptEvent;
import funkin.ui.ScriptedMusicBeatState;
import funkin.ui.story.StoryMenuState;
import funkin.ui.transition.stickers.StickerSubState;
import Reflect;

/**
 * Redirige el regreso de una week (ResultState / GameOver / Pause) a StoryMenuCustom
 * en vez del StoryMenuState original, sin tocar el source.
 *
 * Como funciona:
 *  - Cada vez que se abre un StickerSubState, el juego avisa a los modulos (SUBSTATE_OPEN_BEGIN).
 *  - Aqui se envuelve su funcion privada `targetState`: si el state al que iba a ir es el
 *    StoryMenuState original, se devuelve StoryMenuCustom (con el mismo sticker). Cualquier
 *    otro destino (Freeplay, etc.) queda igual.
 *
 * Va en  scripts/  junto a StoryMenuCustom.hxc.
 */
class StoryMenuStickerRedirect extends Module
{
  var CUSTOM_MENU_CLASS:String = 'StoryMenuCustom';

  // Stickers ya envueltos (para no envolver dos veces el mismo).
  var patched:Array<Dynamic> = [];

  public function new()
  {
    super('storyMenuStickerRedirect', 1);
  }

  public override function onSubStateOpenBegin(event:ScriptEvent):Void
  {
    var sub:Dynamic = event.targetState;
    if (sub == null) return;

    if (!Std.isOfType(sub, StickerSubState)) return;
    if (patched.indexOf(sub) != -1) return;

    try
    {
      // `targetState` es privado en StickerSubState: se lee/escribe con Reflect.
      var original:Dynamic = Reflect.field(sub, 'targetState');
      if (original == null) return;

      var customClass:String = CUSTOM_MENU_CLASS;

      Reflect.setField(sub, 'targetState', function(stk:Dynamic):Dynamic
      {
        var next:Dynamic = original(stk);

        if (next != null && Std.isOfType(next, StoryMenuState))
        {
          var custom:Dynamic = ScriptedMusicBeatState.scriptInit(customClass, stk);
          if (custom != null) return custom;
        }

        return next;
      });

      patched.push(sub);
    }
    catch (e:Dynamic)
    {
      trace('[StoryMenuStickerRedirect] No se pudo redirigir el sticker: ' + e);
    }
  }
}
