package animania.events;

class SetPropertySongEvent extends SongEvent
{
  var cameraSpeedMult:Float = 1.0;

  public function new()
  {
    super('SetProperty', {processOldEvents: true});
  }

  override public function handleEvent(data:SongEventData):Void
  {
    var pf = PlayState.instance;
    if (pf == null) return;

    var target = data.getString('target');
    var rawValue = data.getString('value');
    if (target == null || target == '') return;
    if (rawValue == null) rawValue = '';

    var value = parseValue(rawValue);

    if (target == 'currentCameraSpeed' || target == 'cameraSpeed')
    {
      if (isNumeric(StringTools.trim(rawValue)))
      {
        cameraSpeedMult = value;
        FlxG.camera.followLerp = Constants.DEFAULT_CAMERA_FOLLOW_RATE * cameraSpeedMult;
      }
      return;
    }

    var parts = target.split('.');
    var obj = resolveRoot(parts[0]);
    var i = 0;
    if (obj != null) i = 1;
    else
      obj = pf;

    if (i >= parts.length)
    {
      trace('[SetProperty] Target invalido: ' + target);
      return;
    }

    try
    {
      while (i < parts.length - 1)
      {
        obj = Reflect.getProperty(obj, parts[i]);
        if (obj == null)
        {
          trace('[SetProperty] "' + parts[i] + '" es null en la ruta ' + target);
          return;
        }
        i = i + 1;
      }
      Reflect.setProperty(obj, parts[parts.length - 1], value);
    }
    catch (e:Dynamic)
    {
      trace('[SetProperty] Error al asignar ' + target + ': ' + Std.string(e));
    }
  }

  function resolveRoot(name:String)
  {
    var pf = PlayState.instance;
    if (pf.currentStage == null) return null;
    if (name == 'boyfriend' || name == 'bf' || name == 'player') return pf.currentStage.getBoyfriend();
    if (name == 'dad' || name == 'opponent') return pf.currentStage.getDad();
    if (name == 'girlfriend' || name == 'gf') return pf.currentStage.getGirlfriend();
    return null;
  }

  function isNumeric(s:String):Bool
  {
    if (s == null || s.length == 0) return false;
    var chars = '0123456789.-+eE';
    var i = 0;
    while (i < s.length)
    {
      if (chars.indexOf(s.charAt(i)) == -1) return false;
      i = i + 1;
    }
    return !Math.isNaN(Std.parseFloat(s));
  }

  function parseValue(raw:String)
  {
    var v = StringTools.trim(raw);
    var lower = v.toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
    if (lower == 'null') return null;
    if (isNumeric(v)) return Std.parseFloat(v);
    return raw;
  }

  override public function onUpdate(event:UpdateScriptEvent):Void
  {
    if (cameraSpeedMult == 1.0) return;
    if (FlxG.camera.followLerp > 0) FlxG.camera.followLerp = Constants.DEFAULT_CAMERA_FOLLOW_RATE * cameraSpeedMult;
  }

  override public function onSongRetry(event:SongRetryEvent):Void
  {
    cameraSpeedMult = 1.0;
  }

  override public function onSongEnd(event:ScriptEvent):Void
  {
    cameraSpeedMult = 1.0;
  }

  override public function getTitle():String
  {
    return 'Set Property';
  }

  override public function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'target',
        title: 'Property',
        defaultValue: 'currentCameraSpeed',
        type: 'string'
      },
      {
        name: 'value',
        title: 'Value',
        defaultValue: '1',
        type: 'string'
      }
    ]);
  }
}
