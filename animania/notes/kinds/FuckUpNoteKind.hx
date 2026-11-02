package animania.notes.kinds;

class FuckUpNoteKind extends NoteKind
{
	function new()
	{
		super("Fuck Up", "Fuck Up", "fuckup", [
			{
				name: "Custom Anim",
				description: "Custom Anim Name",
				type: "String",
				data: {
					defaultValue: ""
				}
			},
			{
				name: "valMin",
				description: "MinRandomTime",
				type: "Float",
				data: {
					min: -0.3,
					max: 0.3,
					step: 0.01,
					precision: 2,
					defaultValue: 0.1
				}
			},
			{
				name: "valMax",
				description: "MaxRandomTime",
				type: "Float",
				data: {
					min: -0.3,
					max: 0.3,
					step: 0.01,
					precision: 2,
					defaultValue: 0.2
				}
			},
			{
				name: "holdTimer",
				description: "hold Timer",
				type: "Float",
				data: {
					min: 0.0,
					max: 12,
					step: 0.1,
					precision: 2,
					defaultValue: 0
				}
			},
			{
				name: "conOrPress",
				description: "Confirm or Press",
				type: "Int",
				data: {
					min: 0,
					max: 1,
					step: 1,
					precision: 0,
					defaultValue: 1
				}
			},
			{
				name: "sex",
				description: "Reddit Mode",
				type: "Bool",
				data: {
					defaultValue: false
				}
			}
		]);
	}

	override function onNoteHit(event:NoteScriptEvent)
	{
		event.cancel();
		super.onNoteHit(event);
	}

	function playForcedAnimRandom()
	{
	}

	override function onNoteMiss(event)
	{
		super.onNoteMiss(event);
	}

	override function onUpdate(event:UpdateScriptEvent)
	{
		super.onUpdate(event);
	}

	override function onNoteIncoming(event:NoteScriptEvent)
	{
		FlxTimer.wait(((event.note.strumTime - Conductor.instance.songPosition) / 1000)
			- FlxG.random.float(event.note.getParam("valMin") ?? 0.1, event.note.getParam("valMax") ?? 0.2),
			() ->
			{
				var pPress:Bool = ((event.note.getParam("conOrPress") ?? 1) == 1);

				if (!event.note.noteData.getMustHitNote())
					PlayState.instance.opponentStrumline.hitNote(event.note, false, pPress);
				else if (event.note.noteData.getMustHitNote())
					PlayState.instance.playerStrumline.hitNote(event.note, false, pPress);

				var customAnim:String = event.note.getParam("Custom Anim");
				if (customAnim != null && customAnim.trim() != "")
				{
					var char = PlayState.instance?.currentStage?.getDad();
					if (event.note.noteData.getMustHitNote())
						char = PlayState.instance?.currentStage?.getBoyfriend();

					this.noanim = true;
					if (PlayState.instance != null
						&& PlayState.instance.currentStage != null
						&& PlayState.instance.currentStage.getDad() != null)
					{
						char?.canPlayOtherAnims = true;
						char?.playAnimation(customAnim, true, true);
						char?.holdTimer = -event.note.getParam("holdTimer") ?? 0;
					}
				}
			});
		var customAnim:String = event.note.getParam("Custom Anim");
		if (customAnim != null && customAnim.trim() != "")
		{
			this.noanim = true;
		}

		if (event.note.noteData.getMustHitNote())
			event.note.hasBeenHit = true;
		super.onNoteIncoming(event);
	}
}
