package animania.songs.fresh;

class FreshAnimania extends Song
{
	var blackAss:FunkinSprite = null;
	var ver:FunkinSprite = null;
	var solo_time_d:FunkinSprite = null;
	var hasPlayedCutscene:Bool = false;
    function new()
    {
        super('fresh-animania');

        hasPlayedCutscene = false;
    }

    function onCreate(event:ScriptEvent):Void
	{
        super.onCreate(event);

		hasPlayedCutscene = false;
        onLoadSong(PlayState.lastParams);
	}

    function onLoadSong(params)
    {
        if (params.targetSong.id != "fresh-animania")
            return;

        var currentStage:Dynamic = PlayState.instance.currentStage;

		blackAss = new FunkinSprite();
        blackAss.makeGraphic(1, 1, FlxColor.WHITE);
        blackAss.color = FlxColor.BLACK;
        blackAss.scale.set(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3));
        blackAss.updateHitbox();
        blackAss.screenCenter();
        blackAss.zIndex = 9000;
        blackAss.alpha = 0;
        currentStage.add(blackAss);

		ver = new FunkinSprite();
        ver.loadGraphic(Paths.image('stages/mainStageAmTake/gf_event', 'shared'));
        ver.zIndex = currentStage.getGirlfriend().zIndex - 1;
        ver.x = 520;
        ver.y = -580;
        ver.visible = false;
        ver.y -= 800;
        currentStage.add(ver);

		solo_time_d = new FunkinSprite(0, 0, Paths.animateAtlas('stages/mainStageAmTake/solotime_cardboard', 'shared'));
        solo_time_d.zIndex = 8;
        solo_time_d.applyStageMatrix = true;

        addAtlasAnim(solo_time_d, "off", "off loop", 24, true);
        addAtlasAnim(solo_time_d, "turn", "turned on", 24, false);
        addAtlasAnim(solo_time_d, "on", "on loop", 24, true);
        solo_time_d.animation.onFinish.add((animName) -> if (animName == "turn") playSoloSign('on'));
        playSoloSign('off');
        currentStage.add(solo_time_d);

        solo_time_d.x += 325;
		solo_time_d.y -= 350;

		solo_time_d.y -= 800;

        currentStage.refresh();

        var gf = currentStage.getGirlfriend();
        gf.anim.onFrameChange.add((name, symb, idx) -> if (name == "fresh solo") {
            trace(symb, idx);
            switch (symb)
            {
		
                case 1:
                    ver.visible = true;
                    FlxTween.tween(ver, {y: ver.y + 800}, 6, {startDelay: 6, ease: FlxEase.cubeOut});

                case 333:
			    	ver.zIndex = currentStage.getGirlfriend().zIndex + 1;
			    	currentStage.refresh();

                case 369:
			    	ver.zIndex = currentStage.getGirlfriend().zIndex - 1;
			    	currentStage.refresh();

                case 371:
                    ver.y += 2;
                case 377:
                    ver.y += 2;
                case 379:
                    ver.y += 5;

                case 381:
                    ver.y -= 5;
                case 383:
    				ver.y -= 4;

                case 387:
    				ver.zIndex = 12;
    				currentStage.refresh();

                case 389:
    				FlxTween.tween(ver, {y: ver.y - 800}, 4, {ease: FlxEase.cubeIn});
            }
        });
    }

    /**
     * Registra una animacion del atlas buscando el id primero como frame label y despues como symbol.
     * (addBySymbol a secas no registra nada si el nombre es un frame label, y entonces play() no hace nada.)
     */
    function addAtlasAnim(spr:FunkinSprite, animName:String, id:String, fps:Int, loop:Bool):Bool
    {
        var norm = (s) -> s.toLowerCase().split(" ").join("").split("_").join("");
        var labels:Array<String> = spr.getFrameLabelList();

        var found:String = null;
        for (l in labels) if (l == id) { found = l; break; }
        if (found == null) for (l in labels) if (norm(l) == norm(id)) { found = l; break; }

        if (found != null)
        {
            spr.anim.addByFrameLabel(animName, found, fps, loop);
            return true;
        }

        try
        {
            spr.anim.addBySymbol(animName, id, fps, loop);
        }
        catch (e:Dynamic) {}

        if (spr.animation.getNameList().contains(animName)) return true;

        var symbols:Array<String> = [];
        try { for (k in spr.library.dictionary.keys()) symbols.push(k); } catch (e:Dynamic) {}
        trace('[FreshAnimania] No se encontro "' + id + '" en el atlas. Labels: ' + labels + ' | Symbols: ' + symbols);
        return false;
    }

    function playSoloSign(name:String):Void
    {
        if (solo_time_d == null) return;
        if (!solo_time_d.animation.getNameList().contains(name)) return;
        solo_time_d.animation.play(name, true);
    }

    override function onBeatHit(event:SongTimeScriptEvent):Void
    {
        super.onBeatHit(event);

        var beat = event.beat;
        var currentStage:Dynamic = PlayState.instance.currentStage;

        switch (beat)
        {
            case 1:
                trace('primer beat');
            case 108:
                var dad = currentStage.getDad();
                dad.zIndex = 9999;
                currentStage.refresh();
                blackAss.alpha = 1;
                FlxTween.tween(dad, {alpha: 0}, 0.8, {startDelay: 1.2, ease: FlxEase.cubeOut});
            case 112:
                FlxTween.cancelTweensOf(currentStage.getDad());
                currentStage.getDad().alpha = 1;
                var vin2 = currentStage.getNamedProp('vin2');
                vin2.alpha = 1;

                var dad = currentStage.getDad();
                dad.zIndex = 20;
                currentStage.refresh();
                blackAss.alpha = 1;
                FlxTween.tween(blackAss, {alpha: 0}, 7, {ease: FlxEase.smootherStepInOut});
                FlxTween.tween(vin2, {alpha: 0.8}, 12, {ease: FlxEase.smootherStepInOut});
            case 116:
                trace('comenzando evento');
                moveIn();
            case 128:
                FlxTween.tween(solo_time_d, {y: solo_time_d.y + 800}, 4, {ease: FlxEase.sineOut});
				trace('inicio');
            case 143:
                playSoloSign('turn');
                FlxTween.tween(solo_time_d, {y: solo_time_d.y - 800}, 7, {startDelay: 12, ease: FlxEase.sineIn});
				trace('prende');
            case 144:
                var vin2 = currentStage.getNamedProp('vin2');
                vin2.alpha = 0;

                blackAss.color = FlxColor.WHITE;
                blackAss.blend = BlendMode.ADD;
                blackAss.alpha = 1;
                FlxTween.tween(blackAss, {alpha: 0}, 1.2, {ease: FlxEase.sineOut});
            case 174:
                trace('quitando evento');
                moveOut();
        }
    }

    var sfxSounds:FunkinSound = null;

	function onCountdownStart(event)
	{
		sfxSounds = FunkinSound.load(Paths.inst("fresh-animania", "-sfx"));
		super.onCountdownStart(event);
	}

    function onSongStart(event:Dynamic)
	{
		super.onSongStart(event);
		PlayState.instance.vocals.add(sfxSounds);
		sfxSounds.play(true);
	}


    function moveIn()
    {
        var opponentStrumline:Dynamic = PlayState.instance.opponentStrumline;
        var playerStrumline:Dynamic = PlayState.instance.playerStrumline;
		var ogHealthbar:Dynamic = PlayState.instance.healthBar;
        var health:Dynamic = ModuleHandler.getModule('CurvedHealthBarModule').redBar;
		var health2:Dynamic = ModuleHandler.getModule('CurvedHealthBarModule').greenBar;
        var healthBG:Dynamic = ModuleHandler.getModule('CurvedHealthBarModule').bg;
		var score:Dynamic = ModuleHandler.getModule('AnimaniaScoreModule').scoreLabel;
		var scoreDigits:Dynamic = ModuleHandler.getModule('AnimaniaScoreModule').scoreDigits;
		var fcSprite:Dynamic = ModuleHandler.getModule('FullComboModule').fcSprite;
        var iconP1:Dynamic = PlayState.instance.iconP1;
        var iconP2:Dynamic = PlayState.instance.iconP2;

        var offset = (AmScroll.isDown() ? -200 : 200);
        var offsetScore = (AmScroll.isPref() ? -200 : 200);

        FlxTween.tween(health, {y: health.y + offset}, 10, {ease: FlxEase.sineInOut});
		FlxTween.tween(ogHealthbar, {y: ogHealthbar.y + offset}, 10, {ease: FlxEase.sineInOut});
		FlxTween.tween(health2, {y: health2.y + offset}, 10, {ease: FlxEase.sineInOut});
        FlxTween.tween(healthBG, {y: healthBG.y + offset}, 10, {ease: FlxEase.sineInOut});
		FlxTween.tween(score, {y: score.y + offsetScore}, 10, {ease: FlxEase.sineInOut});
		FlxTween.tween(fcSprite, {y: fcSprite.y + offsetScore}, 10, {ease: FlxEase.sineInOut});
		for (i in 0...scoreDigits.length)
		{
			FlxTween.tween(scoreDigits[i], {y: scoreDigits[i].y + offsetScore}, 10, {ease: FlxEase.sineOut});
		}

        FlxTween.tween(iconP1, {y: iconP1.y + offset}, 10, {ease: FlxEase.sineInOut});
        FlxTween.tween(iconP2, {y: iconP2.y + offset}, 10, {ease: FlxEase.sineInOut});


        FlxTween.tween(opponentStrumline, {x: opponentStrumline.x - 100, alpha: 0.75}, 12.25, {ease: FlxEase.sineOut});
		if (AmMlpc.playerStrum())
		{
        FlxTween.tween(playerStrumline, {x: playerStrumline.x - FlxG.width/4 + 20}, 14.55, {ease: FlxEase.sineInOut});
		}

		if (AmMlpc.oppScale())
		{
        FlxTween.num(opponentStrumline.strumlineScale.x, .65, 12.25, {ease: FlxEase.sineOut}, v -> opponentStrumline.strumlineScale.x = v);
        FlxTween.num(opponentStrumline.strumlineScale.y, .65, 12.25, {ease: FlxEase.sineOut}, v -> opponentStrumline.strumlineScale.y = v);
		}
		if (AmMlpc.playerStrum())
		{
        FlxTween.num(playerStrumline.strumlineScale.x, 1.1, 14.55, {ease: FlxEase.sineInOut}, v -> playerStrumline.strumlineScale.x = v);
		FlxTween.num(playerStrumline.strumlineScale.y, 1.1, 14.55, {ease: FlxEase.sineInOut}, v -> playerStrumline.strumlineScale.y = v);
		}
	}

    function moveOut()
    {
        var opponentStrumline:Dynamic = PlayState.instance.opponentStrumline;
        var playerStrumline:Dynamic = PlayState.instance.playerStrumline;
		var ogHealthbar:Dynamic = PlayState.instance.healthBar;
        var health:Dynamic = ModuleHandler.getModule('CurvedHealthBarModule').redBar;
		var health2:Dynamic = ModuleHandler.getModule('CurvedHealthBarModule').greenBar;
        var healthBG:Dynamic = ModuleHandler.getModule('CurvedHealthBarModule').bg;
		var score:Dynamic = ModuleHandler.getModule('AnimaniaScoreModule').scoreLabel;
		var scoreDigits:Dynamic = ModuleHandler.getModule('AnimaniaScoreModule').scoreDigits;
		var fcSprite:Dynamic = ModuleHandler.getModule('FullComboModule').fcSprite;
        var iconP1:Dynamic = PlayState.instance.iconP1;
        var iconP2:Dynamic = PlayState.instance.iconP2;

        var offset = (AmScroll.isDown() ? -200 : 200 );
        var offsetScore = (AmScroll.isPref() ? -200 : 200);

        FlxTween.tween(health, {y: health.y - offset}, 1.5, {ease: FlxEase.sineOut});
		FlxTween.tween(ogHealthbar, {y: ogHealthbar.y - offset}, 1.5, {ease: FlxEase.sineOut});
		FlxTween.tween(health2, {y: health2.y - offset}, 1.5, {ease: FlxEase.sineOut});
        FlxTween.tween(healthBG, {y: healthBG.y - offset}, 1.5, {ease: FlxEase.sineOut});
		FlxTween.tween(score, {y: score.y - offsetScore}, 1.5, {ease: FlxEase.sineOut});
        FlxTween.tween(fcSprite, {y: fcSprite.y - offsetScore}, 1.5, {ease: FlxEase.sineOut});
		for (i in 0...scoreDigits.length)
		{
			FlxTween.tween(scoreDigits[i], {y: scoreDigits[i].y - offsetScore}, 1.5, {ease: FlxEase.sineOut});
		}

        FlxTween.tween(iconP1, {y: iconP1.y - offset}, 1.5, {ease: FlxEase.sineOut});
        FlxTween.tween(iconP2, {y: iconP2.y - offset}, 1.5, {ease: FlxEase.sineOut});

        FlxTween.tween(opponentStrumline, {x: opponentStrumline.x + 100, alpha: 1}, 2.65, {ease: FlxEase.backOut});
		if (AmMlpc.playerStrum())
		{
        FlxTween.tween(playerStrumline, {x: playerStrumline.x + FlxG.width/4 - 20}, 2.45, {ease: FlxEase.cubeOut});
		}

		if (AmMlpc.oppScale())
		{
        FlxTween.num(opponentStrumline.strumlineScale.x, 1, 2.65, {ease: FlxEase.backOut}, v -> opponentStrumline.strumlineScale.x = v);
		FlxTween.num(opponentStrumline.strumlineScale.y, 1, 2.65, {ease: FlxEase.backOut}, v -> opponentStrumline.strumlineScale.y = v);
		}
		if (AmMlpc.playerStrum())
		{
        FlxTween.num(playerStrumline.strumlineScale.x, 1, 2.45, {ease: FlxEase.cubeOut}, v -> playerStrumline.strumlineScale.x = v);
		FlxTween.num(playerStrumline.strumlineScale.y, 1, 2.45, {ease: FlxEase.cubeOut}, v -> playerStrumline.strumlineScale.y = v);
		}
    }

    public override function onSongEnd(event:CountdownScriptEvent):Void
	{
		super.onSongEnd(event); 
		if (!PlayStatePlaylist.isStoryMode)
			hasPlayedCutscene = true;

		if (!hasPlayedCutscene)
		{
			PlayState.instance.isInCutscene = true;
			PlayState.instance.mayPauseGame = false;
			hasPlayedCutscene = true;

			event.cancel();

			startCutscene();
		}
		else
		{
			hasPlayedCutscene = false;
			PlayState.instance.isInCutscene = false;
			PlayState.instance.mayPauseGame = true;
		}
	}

    function startCutscene()
	{
		PlayState.instance.isInCutscene = true;
		PlayState.instance.mayPauseGame = false;
		hasPlayedCutscene = true;

		FlxTween.tween(PlayState.instance.camHUD, {alpha: 0}, 1, {ease: FlxEase.backOut});
		PlayState.instance.tweenCameraZoom(0.9, 1.9, true, FlxEase.quadInOut);
		PlayState.instance.tweenCameraToPosition(PlayState.instance.cameraFollowPoint.x + 100, PlayState.instance.cameraFollowPoint.y + 50, 1.9, FlxEase.quadInOut);
		var blackScreen = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		blackScreen.scrollFactor.set();
		blackScreen.cameras = [PlayState.instance.camCutscene];
		PlayState.instance.add(blackScreen);
		blackScreen.alpha = 0;
		FlxTween.tween(blackScreen, {alpha: 1}, 1.75, {ease: FlxEase.quadInOut});

		FlxTimer.wait(2, startVideo);
	}

    function startVideo()
	{
		VideoCutscene.play(Paths.videos('FRESH_CUTSCENE.mkv'), CutsceneType.ENDING);
		VideoCutscene.vid.alpha = 0;
		FlxTween.tween(VideoCutscene.vid, {alpha: 1}, .35, {ease: FlxEase.cubeOut});
	}
}
