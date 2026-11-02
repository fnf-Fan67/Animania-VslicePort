package animania.gameplay.strumlines;

#if !mobile
class MoveStrumlinesAmTake extends Module
{
	function new()
	{
		super('MoveStrumlineAmTake');
	}

	override function onCountdownStart(event:CountdownScriptEvent):Void
	{
		if (!ModuleHandler.getModule('AnimaniaStuff').isAllowedStage()) return;

		super.onCountdownStart(event);
		var playerStrumline = PlayState.instance.playerStrumline;
		var opponentStrumline = PlayState.instance.opponentStrumline;

		playerStrumline.x += 55;
		opponentStrumline.x += 40;
	}
}
#end
