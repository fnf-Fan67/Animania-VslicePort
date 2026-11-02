package animania.hud.fullcombo;

class FullComboModule extends Module implements IPlayStateScriptedClass
{
	public function new()
	{
		super("FullComboModule", 200);
	}

	static var MEGA_ALLOWED_STAGES:Array<String> = [
		"mainStageAmTake",
		"serviceEnterance",
		"xMasCityMallAmTake",
		"xMasCityMallAmTakeDark",
		"xMasCityMallNastyAmTake",
		"phoneCallStreet"
	];

	function isAllowedStage():Bool
	{
		var play = PlayState.instance;
		if (play == null || play.currentStage == null) return false;
		return MEGA_ALLOWED_STAGES.indexOf(play.currentStage.id) != -1;
	}

	public var fcSprite:FullComboSpr = null;

	/** Notas seguidas acertadas desde el último corte de combo (para el bonus de score). */
	public var curNoteCombo:Int = 0;

	/** Score acumulado de esas notas (para calcular el bonus). */
	public var scoreCombo:Float = 0;

	/** true mientras la UI de FC ya fue construida para el PlayState actual. */
	public var uiReady:Bool = false;

	override public function onStateChangeEnd(event:StateChangeScriptEvent):Void
	{
		uiReady = false;
		if (Std.isOfType(event.targetState, PlayState) && isAllowedStage())
			buildFCSprite();
		super.onStateChangeEnd(event);
	}

	override public function onSubStateOpenEnd(event:SubStateScriptEvent):Void
	{
		if (Std.isOfType(event.targetState, PlayState) && isAllowedStage())
			buildFCSprite();
		super.onSubStateOpenEnd(event);
	}

	function buildFCSprite():Void
	{
		var play = PlayState.instance;
		if (play == null)
			return;

		uiReady = true;
		curNoteCombo = 0;
		scoreCombo = 0;

		fcSprite = new FullComboSpr(20);
		fcSprite.frames = Paths.getSparrowAtlas("ui/ratings/GAMEPLAY_UI_ASSETS", "shared");
		fcSprite.animation.addByPrefix("y", "full combo", 1, false);
		fcSprite.animation.play("y", true);
		fcSprite.camera = play.camHUD;
		fcSprite.zIndex = 1550;
		fcSprite.updateHitbox();
		fcSprite.y = AmScroll.isPref() ? 20 : FlxG.height - fcSprite.height;
		fcSprite.alpha = 0.0001;
		fcSprite.comboStatus = "PFC";

		play.add(fcSprite);
	}

	override public function onDestroy(event:ScriptEvent):Void
	{
		uiReady = false;
		if (fcSprite != null)
		{
			FlxTween.cancelTweensOf(fcSprite);
			fcSprite.destroy();
			fcSprite = null;
		}
		super.onDestroy(event);
	}

	override public function onSongStart(event:ScriptEvent):Void
	{
		super.onSongStart(event);
		if (fcSprite == null)
			return;

		fcSprite.revive();
		fcSprite.active = true;
		fcSprite.comboStatus = "PFC";
		fcSprite.x = 20;
		fcSprite.y = AmScroll.isPref() ? 20 : FlxG.height - fcSprite.height;
		fcSprite.alpha = 0.0001;
		curNoteCombo = 0;
		scoreCombo = 0;
	}

	override public function onNoteHit(event:HitNoteScriptEvent):Void
	{
		if (uiReady && event.note.noteData.getMustHitNote())
			onComboNoteHit(event);
		super.onNoteHit(event);
	}

	override public function onNoteMiss(event:NoteScriptEvent):Void
	{
		if (uiReady && event.note.noteData.getMustHitNote())
			onComboBreak();
		super.onNoteMiss(event);
	}

	/**
	 * Nota acertada sin romper combo: hace aparecer/actualizar el sprite de FC
	 * y decide si sigue siendo PFC o pasa a "Normal" (FC común).
	 */
	function onComboNoteHit(event:HitNoteScriptEvent):Void
	{
		if (event.isComboBreak)
		{
			onComboBreak();
			return;
		}

		curNoteCombo++;
		scoreCombo += event.score;

		if (fcSprite == null)
			return;

		if (fcSprite.active && fcSprite.alpha < .1)
		{
			fcSprite.scale.set(.55, .55);
			fcSprite.angle = -45;
			FlxTween.tween(fcSprite.scale, {x: 0.8, y: 0.8}, .25);
			FlxTween.tween(fcSprite, {angle: 0, alpha: 1}, .25);
		}

		fcSprite.comboStatus = (Highscore.tallies.sick == Highscore.tallies.totalNotesHit) ? "PFC" : "Normal";
	}

	/**
	 * Miss o corte de combo: anima el sprite saliendo de pantalla, otorga el bonus
	 * de score acumulado (igual que `spawnCombo` en el módulo original) y resetea.
	 */
	function onComboBreak():Void
	{
		if (fcSprite != null && fcSprite.active)
		{
			fcSprite.comboStatus = "Break";
			fcSprite.active = false;
			FlxTween.tween(fcSprite, {x: fcSprite.x - 150, angle: -95, alpha: 0}, .2, {
				onComplete: (_) -> fcSprite.kill()
			});
		}

		grantComboBonus();
	}

	/** Bonus de score al cortar la racha, calcado del `spawnCombo` original. */
	function grantComboBonus():Void
	{
		var play = PlayState.instance;
		if (play == null || curNoteCombo <= 7)
		{
			curNoteCombo = 0;
			scoreCombo = 0;
			return;
		}

		final bonusScore:Int = Math.round(curNoteCombo * (scoreCombo / 150));
		play.songScore += Math.round(bonusScore - (scoreCombo / 150));

		curNoteCombo = 0;
		scoreCombo = 0;
	}

	override public function onBeatHit(event:SongTimeScriptEvent):Void
	{
		super.onBeatHit(event);
		if (!uiReady || fcSprite == null || !fcSprite.active || fcSprite.alpha != 1)
			return;

		fcSprite.scale.set(0.825, 0.825);
		FlxTween.tween(fcSprite.scale, {x: 0.9, y: 0.9}, Conductor.instance.beatLengthMs / 2000);
	}
}
