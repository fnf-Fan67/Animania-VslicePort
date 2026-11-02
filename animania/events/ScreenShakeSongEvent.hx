package animania.events;

class ScreenShakeSongEvent extends SongEvent
{
  public function new()
  {
    super('ScreenShake');
  }

  override public function handleEvent(data:SongEventData):Void
  {
    var pf = PlayState.instance;
    if (pf == null) return;

    var gameTime = data.getFloat('gameTime');
    var gameIntensity = data.getFloat('gameIntensity');
    var hudTime = data.getFloat('hudTime');
    var hudIntensity = data.getFloat('hudIntensity');
    if (gameTime == null) gameTime = 0.03;
    if (gameIntensity == null) gameIntensity = 0.015;
    if (hudTime == null) hudTime = 0.03;
    if (hudIntensity == null) hudIntensity = 0.015;

    if (gameIntensity > 0 && gameTime > 0) pf.camGame.shake(gameIntensity, gameTime);
    if (hudIntensity > 0 && hudTime > 0) pf.camHUD.shake(hudIntensity, hudTime);
  }

  override public function getTitle():String
  {
    return 'Screen Shake';
  }

  override public function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'gameTime',
        title: 'Game Duration',
        defaultValue: 0.03,
        min: 0,
        step: 0.01,
        type: 'float',
        units: 'sec'
      },
      {
        name: 'gameIntensity',
        title: 'Game Intensity',
        defaultValue: 0.015,
        min: 0,
        step: 0.005,
        type: 'float'
      },
      {
        name: 'hudTime',
        title: 'HUD Duration',
        defaultValue: 0.03,
        min: 0,
        step: 0.01,
        type: 'float',
        units: 'sec'
      },
      {
        name: 'hudIntensity',
        title: 'HUD Intensity',
        defaultValue: 0.015,
        min: 0,
        step: 0.005,
        type: 'float'
      }
    ]);
  }
}
