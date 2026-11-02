package animania.gameplay.camera;

class FocusCameraStagePointModule extends Module
{
	function new()
	{
		super("FocusCameraStagePoint", 10);
	}

	function hasCameraPoint(data:Dynamic):Bool
	{
		var point:String = data.getString("stagePoint");
		if (point == null || point == "" || point == "NONE")
			point = data.getString("cameraPoint");
		return point != null && point != "" && point != "NONE";
	}

	function easeHasDirection(ease:String):Bool
	{
		var low:String = ease.toLowerCase();
		return low.substr(low.length - 5) == "inout" || low.substr(low.length - 3) == "out" || low.substr(low.length - 2) == "in";
	}

	override function onSongEvent(event:SongEventScriptEvent):Void
	{
		var data = event.eventData;
		if (data.eventKind != "FocusCamera")
			return;

		if (!hasCameraPoint(data))
			return;

		var state = PlayState.instance;
		if (state == null || state.currentStage == null || state.isMinimalMode)
			return;

		var targetX:Null<Float> = data.getFloat("x");
		if (targetX == null)
			targetX = 0.0;
		var targetY:Null<Float> = data.getFloat("y");
		if (targetY == null)
			targetY = 0.0;

		var duration:Null<Float> = data.getFloat("duration");
		if (duration == null)
			duration = 4.0;

		var ease:String = data.getString("ease");
		if (ease == null)
			ease = "CLASSIC";

		var easeDir:String = data.getString("easeDir");
		if (easeDir == null)
			easeDir = "In";
		if (easeHasDirection(ease) || ease == "linear")
			easeDir = "";

		var easeFunction = null;
		if (ease != "CLASSIC" && ease != "INSTANT")
		{
			easeFunction = Reflect.field(FlxEase, ease + easeDir);
			if (easeFunction == null)
			{
				trace("[FocusCameraStagePoint] Ease invalido: " + ease + easeDir);
				return;
			}
		}

		event.cancelEvent();
		data.activated = true;

		switch (ease)
		{
			case "CLASSIC":
				state.resetCamera(false, false, false);
				state.cancelCameraFollowTween();
				state.cameraFollowPoint.setPosition(targetX, targetY);

			case "INSTANT":
				state.tweenCameraToPosition(targetX, targetY, 0);

			default:
				var durSeconds:Float = Conductor.instance.stepLengthMs * duration / Constants.MS_PER_SEC;
				state.tweenCameraToPosition(targetX, targetY, durSeconds, easeFunction);
		}
	}
}
