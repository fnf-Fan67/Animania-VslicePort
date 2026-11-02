package animania.events;

class CountDownEvent extends SongEvent
{
	public function new()
	{
		super("CountDown");
	}

	public override function getEventSchema()
	{
		return [
			{
				name: 'isPixel',
				title: 'Is it pixel?',
				type: "bool",
				defaultValue: false,
			},
			{
				name: 'curStep',
				title: 'CountDown Step',
				type: "string",
				defaultValue: '3',
			}
		];
	}

	public override function handleEvent(data):Void
	{
		if (PlayState.instance == null || PlayState.instance.currentStage == null)
			return;
		if (PlayState.instance.isMinimalMode)
			return;
		var game = PlayState.instance;

		var isPixel:CountdownStep = data.value.isPixel;
		var countStep:CountdownStep = switch(data.value.curStep.toLowerCase())
		{
			case "3": 
				CountdownStep.THREE;
			case "2": 
				CountdownStep.TWO;
			case "1": 
				CountdownStep.ONE;
			default: 
				CountdownStep.GO;
			case "after": 
				CountdownStep.AFTER;
		}

		Countdown.showCountdownGraphic(countStep, isPixel);
		Countdown.playCountdownSound(countStep, isPixel);


		var event:ScriptEvent = new CountdownScriptEvent((countStep != CountdownStep.AFTER ? 'COUNTDOWN_STEP' : 'COUNTDOWN_END'), countStep);
		game.dispatchEvent(event);

		
		game.refresh();
	}

	public override function loadEvent():Void
	{
		trace('Tryed to load event shit');
	}

	/**
	 * Retrieves the asset path to the icon this event type should use in the chart editor.
	 * To customize this, override getIconPath().
	 */
	/*public override function getIconPath():String
	{
		return 'ui/chart-editor/events/SoloTime';
	}*/

	public override function getTitle():String
	{
		return 'CountDown Event';
	}
}
