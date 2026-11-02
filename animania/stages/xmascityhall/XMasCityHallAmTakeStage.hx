package animania.stages.xmascityhall;

class XMasCityHallAmTakeStage extends ScriptedStage
{
	function new()
	{
		super('xMasCityMallAmTake');
	}

	var railBoppers = [];

	function onCreate(e)
	{
		super.onCreate(e);

		PauseSubState.musicSuffix = '-amtake5';
	}

	var leftTV;
	var rightTV;

	var sshh = "
#pragma header

uniform float uTime;
uniform vec2 uResolution;

uniform float uDensity;
uniform float uFlakeSize;
uniform float uFallSpeed;  
uniform float uWindStrength; 
uniform float uTwinkle;
uniform float uOpacity;   

void main()
{
    vec2 fragCoord = openfl_TextureCoordv.xy * uResolution;

    float snow = 0.0;
    float random = fract(sin(dot(fragCoord.xy, vec2(12.9898,78.233))) * 43758.5453);

    for (int k = 0; k < 6; k++) {
        for (int j = 0; j < 4; j++) {
            int i = 1 + j * 3;
            float cellSize = 2.0 + (float(i) * 3.0);
            float downSpeed = -(0.3 * uFallSpeed) - (sin(uTime*0.4 + float(k+i*20)) + 1.0) * 0.00008 * uFallSpeed;

            vec2 uv = (fragCoord.xy / uResolution.x)
                + vec2(0.01 * uWindStrength * sin((uTime + float(k*6185)) * 0.6 + float(i)) * (5.0/float(i)),
                       downSpeed * (uTime + float(k*1352)) * (1.0/float(i)));

            vec2 uvStep = (ceil((uv) * cellSize - vec2(0.5,0.5)) / cellSize);

            float x = fract(sin(dot(uvStep.xy, vec2(12.9898+float(k)*12.0, 78.233+float(k)*315.156))) * 43758.5453 + float(k)*12.0) - 0.5;
            float y = fract(sin(dot(uvStep.xy, vec2(62.2364+float(k)*23.0, 94.674+float(k)*95.0))) * 62159.8432 + float(k)*12.0) - 0.5;

            float randomMagnitude1 = sin(uTime*2.5) * 0.7 * uTwinkle / cellSize;
            float randomMagnitude2 = cos(uTime*2.5) * 0.7 * uTwinkle / cellSize;

            float d = 5.0 * distance((uvStep.xy + vec2(x*sin(y), y)*randomMagnitude1 + vec2(y, x)*randomMagnitude2), uv.xy);

            float omiVal = fract(sin(dot(uvStep.xy, vec2(32.4691,94.615))) * 31572.1684);

            if (omiVal < uDensity) {
                float newd = (x+1.0) * 0.4 * uFlakeSize * clamp(1.9 - d*(15.0+(x*6.3))*(cellSize/1.4), 0.0, 1.0);
                snow += newd;
            }
        }
    }
    vec4 texColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
    float alpha = clamp(snow + random*0.01, 0.0, 1.0) * texColor.a * uOpacity;
    vec3 flakeColor = texColor.rgb;

    gl_FragColor = vec4(flakeColor * alpha, alpha);
}";

	var snowShader = null;
	var snowSpr = null;
	var snowTime:Float = 0;

	var _lowQualityProps = ['ceiling', 'upFreaks', 'rail-guys-far', 'goku', 'rail-guys-bobby', 'rail-guys-left', 'rail-guys-miku', 'rail-guys-monster', 'rail-guys-right', 'candy', 'alien_ship', 'tree-crushers', 'meat-boy', 'c-toy-1', 'c-toy-2'];

	function removeLowQualityProps()
	{
		var names = _lowQualityProps;
		var boppers = Reflect.field(this, 'boppers');
		var named = Reflect.field(this, 'namedProps');

		var i = 0;
		while (i < names.length)
		{
			var prop = getNamedProp(names[i]);
			if (prop != null)
			{
				FlxTween.cancelTweensOf(prop);
				if (boppers != null) boppers.remove(prop);
				if (named != null) named.remove(names[i]);
				remove(prop);
				prop.kill();
				prop.destroy();
			}
			i = i + 1;
		}
	}

	function buildStage()
	{
		var play = PlayState.instance;
		if (play == null)
			return;

		railBoppers = [];
		super.buildStage();

		if (Save.instance.modOptions["lowQuality"])
		{
			removeLowQualityProps();
		}

		for (dataProp in _data.props)
		{
			final prop = getNamedProp(dataProp.name);
			if (prop == null)
				continue;

			if (dataProp.name.indexOf('rail-guys-') != -1)
				railBoppers.push(prop);
		}

		if (!Save.instance.modOptions["lowQuality"])
		{
		leftTV = new FunkinSprite(-1800, -690);
    leftTV.loadTextureAtlas("stages/xMassCityMall/tvl", "shared", {cacheOnLoad: true});
    leftTV.zIndex = 70;
    leftTV.scrollFactor.set(0.875, 0.875);
    leftTV.anim.addByFrameLabel("noise", "noise", 24, false);
    leftTV.anim.onFinish.add(name -> if (name == "noise")
    {
      if (FlxG.random.bool(15))
        leftTV.anim.play("OOGA BOOGA", true);
      else
        leftTV.anim.play(FlxG.random.int(0, 5), true);
    }
    else if (name == "OOGA BOOGA") leftTV.anim.play("noise", true));
    leftTV.anim.addByFrameLabel("0", "f1", 24);
    leftTV.anim.addByFrameLabel("1", "f2", 24);
    leftTV.anim.addByFrameLabel("2", "f3", 24);
    leftTV.anim.addByFrameLabel("3", "f4", 24);
    leftTV.anim.addByFrameLabel("4", "f5", 24);
    leftTV.anim.addByFrameLabel("5", "f6", 24);
    leftTV.anim.addByFrameLabelIndices("OOGA BOOGA", "OOGA BOOGA", [0, 0, 0, 0], 24, false);
    leftTV.anim.play("OOGA BOOGA", true);
    leftTV.flipX = true;
    add(leftTV);

    rightTV = new FunkinSprite(980, -690);
    rightTV.loadTextureAtlas("stages/xMassCityMall/tvr", "shared", {cacheOnLoad: true});
    rightTV.zIndex = 70;
    rightTV.scrollFactor.set(0.875, 0.875);
    rightTV.anim.addByFrameLabel("noise", "noise", 24, false);
    rightTV.anim.onFinish.add(name -> if (name == "noise") rightTV.anim.play(FlxG.random.int(0, 6), true));
    rightTV.anim.addByFrameLabel("0", "f1", 24);
    rightTV.anim.addByFrameLabel("1", "f2", 24);
    rightTV.anim.addByFrameLabel("2", "f3", 24);
    rightTV.anim.addByFrameLabel("3", "f4", 24);
    rightTV.anim.addByFrameLabel("4", "f5", 24);
    rightTV.anim.addByFrameLabel("5", "f6", 24);
    rightTV.anim.addByFrameLabel("6", "f7", 24);
    rightTV.anim.play("noise", true);
    add(rightTV);
		}

		if (Save.instance.modOptions["shaders"])
		{
		snowShader = new FlxRuntimeShader(sshh);
		snowShader.setFloat("uTime", 0);

		snowSpr = new FunkinSprite();
		snowSpr.makeSolidColor(Std.int(FlxG.width * 3.5), Std.int(FlxG.height * 3.5), FlxColor.WHITE);
		snowSpr.zIndex = 395;
		add(snowSpr);
		refresh();
		snowSpr.scrollFactor.set(1.2, 1.2);
		snowSpr.screenCenter();
		snowSpr.shader = snowShader;

		snowShader.setFloatArray("uResolution", [snowSpr.width, snowSpr.height]);

		snowShader.setFloat("uDensity", 0.175);
		snowShader.setFloat("uFlakeSize", 2.0);
		snowShader.setFloat("uFallSpeed", 0.75);
		snowShader.setFloat("uWindStrength", 2.0);
		snowShader.setFloat("uTwinkle", 0.9);
		snowShader.setFloat("uOpacity", 0.9);
		}

		refresh();
	}

	function onUpdate(event)
	{
		super.onUpdate(event);

		if (snowShader != null)
			snowShader.setFloat("uTime", snowTime += event.elapsed);
	}

	var boppersIdle:Int = 2;

	function onBeatHit(event)
	{
		super.onBeatHit(event);

    if (!Save.instance.modOptions["lowQuality"])
    {
      if (FlxG.random.bool(10))
        leftTV.anim.play("noise", true);

      if (FlxG.random.bool(10))
        rightTV.anim.play("noise", true);

      if (event.beat % boppersIdle == 0)
        boppersBop();
    }

		var play = PlayState.instance;
		if (play == null || play.currentSong == null || play.currentSong.id != "cocoa-animania" || play.isPlayerDying)
			return;

		if (event.beat == 12)
		{
			FlxTween.tween(play.camHUD, {alpha: 1}, Conductor.instance.beatLengthMs / 1000, {ease: FlxEase.cubeOut});
			play.cancelCameraZoomTween();
			play.currentCameraZoom = play.stageZoom;
		}
		else if (event.beat == 146)
		{
			moveIn();
		}
		else if (event.beat == 184)
		{
			moveOut();
		}
		else if (event.beat == 256)
		{
			if (PlayStatePlaylist.isStoryMode)
			{
				var screeen = new FunkinSprite();
				screeen.makeGraphic(1, 1, 0xFF4D3A99);
				screeen.scale.set(2000, 2000);
				screeen.screenCenter();
				screeen.alpha = 0;
				add(screeen);
				screeen.camera = play.camHUD;
				screeen.blend = BlendMode.OVERLAY;
				FlxTween.tween(screeen, {alpha: 1}, 4, {ease: FlxEase.sineOut});

				var screeeen = new FunkinSprite();
				screeeen.makeGraphic(1, 1, FlxColor.BLACK);
				screeeen.scale.set(2000, 2000);
				screeeen.screenCenter();
				screeeen.alpha = 0;
				add(screeeen);
				screeeen.camera = play.camHUD;
				FlxTween.tween(screeeen, {alpha: 1}, 4, {ease: FlxEase.sineOut});
			}
		}
	}

	function onCountdownStart(event)
	{
		super.onCountdownStart(event);

		var play = PlayState.instance;
		if (play == null || play.isChartingMode)
			return;

		FlxTimer.wait(0, () -> Countdown.skipCountdown());

		play.camHUD.alpha = 0;

		var gf = getGirlfriend();
		if (gf != null)
			play.tweenCameraToPosition(gf.cameraFocusPoint.x, gf.cameraFocusPoint.y, 0);

		play.tweenCameraZoom(1.4, 0, false);
		FlxTimer.wait(Conductor.instance.beatLengthMs / 1000,
			() -> play.tweenCameraZoom(1.2, Conductor.instance.beatLengthMs * 4 / 1000, false, FlxEase.cubeOut));
	}

	function onSongStart(event)
	{
		super.onSongStart(event);

		var play = PlayState.instance;
		if (play == null)
			return;

		if (play.isChartingMode)
			play.isInCountdown = false;

		FlxTween.tween(play.camHUD, {alpha: 1}, Conductor.instance.beatLengthMs / 1000, {
			ease: FlxEase.cubeOut,
			startDelay: 4
		});
	}

	function boppersBop()
	{
		for (p in railBoppers)
		{
			var bopperY = p.y;
			p.y += 10;
			new FlxTimer().start(2 / 24, _ -> p.y = bopperY + 7.5);
			new FlxTimer().start(4 / 24, _ -> p.y = bopperY + 2.5);
			new FlxTimer().start(6 / 24, _ -> p.y = bopperY);
		}
	}

	function moveIn()
	{
		var play = PlayState.instance;
		if (play == null)
			return;

		FlxTween.tween(play.opponentStrumline, {x: play.opponentStrumline.x - 40, alpha: 0.75}, 1.75, {ease: FlxEase.sineOut});
		if (AmMlpc.playerStrum())
		{
		FlxTween.tween(play.playerStrumline, {x: play.playerStrumline.x - FlxG.width / 10 + 20}, 1.55, {ease: FlxEase.backOut});
		}

		if (AmMlpc.oppScale())
		{
		FlxTween.num(play.opponentStrumline.strumlineScale.x, .95, 1.75, {ease: FlxEase.sineOut},
			(value) -> play.opponentStrumline.strumlineScale.set(value, value));
		}
		if (AmMlpc.playerStrum())
		{
		FlxTween.num(play.playerStrumline.strumlineScale.x, 1.05, 1.55, {ease: FlxEase.backOut},
			(value) -> play.playerStrumline.strumlineScale.set(value, value));
		}
	}

	function moveOut()
	{
		var play = PlayState.instance;
		if (play == null)
			return;


		FlxTween.tween(play.opponentStrumline, {x: play.opponentStrumline.x + 40, alpha: 1}, 4.65, {ease: FlxEase.backOut});
		if (AmMlpc.playerStrum())
		{
		FlxTween.tween(play.playerStrumline, {x: play.playerStrumline.x + FlxG.width / 10 - 20}, 4.45, {ease: FlxEase.cubeOut});
		}

		if (AmMlpc.oppScale())
		{
		FlxTween.num(play.opponentStrumline.strumlineScale.x, 1, 4.65, {ease: FlxEase.backOut},
			(value) -> play.opponentStrumline.strumlineScale.set(value, value));
		}
		if (AmMlpc.playerStrum())
		{
		FlxTween.num(play.playerStrumline.strumlineScale.x, 1, 4.45, {ease: FlxEase.cubeOut},
			(value) -> play.playerStrumline.strumlineScale.set(value, value));
		}
	}

	override function onNoteHit(e)
	{
		if (e.isComboBreak)
			makeCrowdLaugh();
	}

	function onNoteGhostMiss(e)
	{
		super.onNoteGhostMiss(e);
		makeCrowdLaugh();
	}

	function onNoteMiss(e)
	{
		if (e.eventCanceled || e.note.kind == "solotime")
			return;
		super.onNoteMiss(e);
		makeCrowdLaugh();
	}

	function makeCrowdLaugh()
	{
		if (getNamedProp("cops").getCurrentAnimation().indexOf("snowball") == -1)
			getNamedProp("cops").playAnimation("laugh", true, true);
	}
}
