package animania.options.performance;

class QualityOptions extends Module
{
    var save:Save;
    var optionsState:OptionsState;
    var preferences:Dynamic;

    function new()
    {
        super('QualityOptions', {state: OptionsState});
    }

    override function onCreate():Void
    {
        super.onCreate();

        save = Save.instance;

        if (save.modOptions['shaders'] == null)
        {
            save.modOptions['shaders'] = true;
            save.flush();
        }

        if (save.modOptions['lowQuality'] == null)
        {
            save.modOptions['lowQuality'] = false;
            save.flush();
        }
    }

    function getShaders():Bool
    {
        if (save == null) save = Save.instance;
        var v = save.modOptions['shaders'];
        return (v == null) ? true : (v == true);
    }

    function getLowQuality():Bool
    {
        if (save == null) save = Save.instance;
        var v = save.modOptions['lowQuality'];
        return (v == null) ? false : (v == true);
    }

    function buildOptions():Void
    {
        optionsState = OptionsState.instance;
        save = Save.instance;
        preferences = optionsState.optionsCodex.pages.get('preferences');

        preferences.createPrefItemCheckbox(
            'animania shaders',
            'If on, custom shaders are used. Turn off to improve performance',
            function(value:Bool):Void
            {
                save.modOptions['shaders'] = value;
                save.flush();
            },
            getShaders()
        );

        preferences.createPrefItemCheckbox(
            'low quality animania',
            'If on, heavy effects are disabled to improve performance',
            function(value:Bool):Void
            {
                save.modOptions['lowQuality'] = value;
                save.flush();
            },
            getLowQuality()
        );
    }

    override function onStateChangeEnd(event:StateChangeScriptEvent):Void
    {
        var targetState = event.targetState;
        super.onStateChangeEnd(event);

        if (Std.isOfType(targetState, OptionsState))
        {
            buildOptions();
        }
    }
}
