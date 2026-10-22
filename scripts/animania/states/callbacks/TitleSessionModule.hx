import funkin.modding.module.Module;

class TitleSessionModule extends Module
{
  public var introSeen:Bool = false;

  public function new()
  {
    super('TitleSessionModule', 1);
  }
}
