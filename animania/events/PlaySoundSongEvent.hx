package animania.events;

class PlaySoundSongEvent extends SongEvent
{
  public function new()
  {
    super('PlaySound');
  }

  override public function handleEvent(data:SongEventData):Void
  {
    var snd = data.getString('snd');
    if (snd == null || snd == '') return;

    var lib = data.getString('lib');
    var vol = data.getFloat('vol');
    var pitch = data.getFloat('pitch');
    if (vol == null) vol = 1.0;
    if (pitch == null) pitch = 1.0;

    var path = null;
    if (lib == null || lib == '') path = Paths.sound(snd);
    else
      path = Paths.sound(snd, lib);

    try
    {
      var sound = FunkinSound.playOnce(path, vol, null, null, true);
      if (sound != null) sound.pitch = pitch;
    }
    catch (e:Dynamic)
    {
      trace('[PlaySound] No se pudo reproducir "' + path + '": ' + Std.string(e));
    }
  }

  override public function getTitle():String
  {
    return 'Play Sound';
  }

  override public function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'snd',
        title: 'Sound',
        defaultValue: '',
        type: SongEventFieldType.STRING
      },
      {
        name: 'lib',
        title: 'Library',
        defaultValue: 'shared',
        type: SongEventFieldType.STRING
      },
      {
        name: 'vol',
        title: 'Volume',
        defaultValue: 1.0,
        min: 0,
        step: 0.1,
        type: SongEventFieldType.FLOAT
      },
      {
        name: 'pitch',
        title: 'Pitch',
        defaultValue: 1.0,
        min: 0.1,
        step: 0.05,
        type: SongEventFieldType.FLOAT
      }
    ]);
  }
}
