package animania.gameplay.gameover;

class BfWHGameOver extends Module implements IPlayStateScriptedClass
{
	function new()
	{
		super('BfWHGameOver', 0);
	}

	final gameoverSuffix = "-wh";
	var activeGameover:Bool = false;
	public override function onGameOver(event:ScriptEvent)
	{
		var play = PlayState.instance;
		if (play != null && !play.isMinimalMode)
			activeGameover = (play.currentStage?.getBoyfriend()?.characterId == "bf-christmas" && play.currentStage?.getOpponent()?.characterId == "monster-plant");
		else
			activeGameover = false;

		if (activeGameover)
		{
			GameOverSubState.musicSuffix += gameoverSuffix;
			GameOverSubState.blueBallSuffix += gameoverSuffix;
			GameOverSubState.animationSuffix += gameoverSuffix;
		}
	}

	override function onSubStateOpenEnd(event)
	{
		if (event.targetState is GameOverSubState && activeGameover)
		{
			var play = PlayState.instance;
			if (play == null) return;

			GameOverSubState.instance.cameraFollowPoint.x -= 250;
			GameOverSubState.instance.cameraFollowPoint.y -= 375;
		}
	}
	override function onSubStateCloseBegin(event)
	{
		if (event.targetState is GameOverSubState && activeGameover)
		{
			GameOverSubState.musicSuffix = StringTools.stripSuffix(GameOverSubState.musicSuffix, gameoverSuffix);
			GameOverSubState.blueBallSuffix = StringTools.stripSuffix(GameOverSubState.blueBallSuffix, gameoverSuffix);
			GameOverSubState.animationSuffix = StringTools.stripSuffix(GameOverSubState.animationSuffix, gameoverSuffix);
			activeGameover = false;
		}
	}
}
