package animania.stages.xmascityhall;

class XMasCityHallAmTakeDarkStage extends ScriptedStage
{
	function new()
	{
		super('xMasCityMallAmTakeDark');
	}

	function lowQualityMode():Bool
	{
		return Save.instance.modOptions["lowQuality"] == true;
	}

	function shadersEnabled():Bool
	{
		return Save.instance.modOptions["shaders"] == true;
	}

	var railBoppers = [];
	var leftTV = null;
	var rightTV = null;
	var boppersIdle:Int = 2;

	var xmasDarkShader = null;

	var snowShader = null;
	var snowSprite = null;
	var snowTime:Float = 0;
	var snowBaseScaleX:Float = 1;
	var snowBaseScaleY:Float = 1;

	var snowZoomFactor:Float = 0.35;

	var snowFrag:String = "
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

	override function onCreate(e)
	{
		snowShader = null;
		snowSprite = null;
		snowTime = 0;

		super.onCreate(e);

		PauseSubState.musicSuffix = '-amtake5';

		createSnowOverlay();
	}

	override function buildStage():Void
	{
		if (PlayState.instance == null)
			return;

		railBoppers = [];
		leftTV = null;
		rightTV = null;

		super.buildStage();

		for (dataProp in _data.props)
		{
			var prop = getNamedProp(dataProp.name);
			if (prop == null)
				continue;

			if (dataProp.name.indexOf('rail-guys-') != -1)
				railBoppers.push(prop);
		}

		if (!lowQualityMode())
		{
			leftTV = new FunkinSprite(-1800, -690);
			leftTV.loadTextureAtlas("stages/xMassCityMallDark/tvl", "shared", {cacheOnLoad: true});
			leftTV.zIndex = 70;
			leftTV.scrollFactor.set(0.875, 0.875);
			leftTV.anim.addByFrameLabel("noise", "noise", 24, false);
			leftTV.anim.onFinish.add(function(name)
			{
				if (name == "noise")
				{
					if (FlxG.random.bool(15))
						leftTV.anim.play("OOGA BOOGA", true);
					else
						leftTV.anim.play(Std.string(FlxG.random.int(0, 5)), true);
				}
				else if (name == "OOGA BOOGA")
				{
					leftTV.anim.play("noise", true);
				}
			});
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
			rightTV.loadTextureAtlas("stages/xMassCityMallDark/tvr", "shared", {cacheOnLoad: true});
			rightTV.zIndex = 70;
			rightTV.scrollFactor.set(0.875, 0.875);
			rightTV.anim.addByFrameLabel("noise", "noise", 24, false);
			rightTV.anim.onFinish.add(function(name)
			{
				if (name == "noise")
					rightTV.anim.play(Std.string(FlxG.random.int(0, 6)), true);
			});
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

		refresh();

		if (Save.instance.modOptions["lowQuality"])
		{
			removeLowQualityProps();
		}
	}

	override function onSongLoaded(event)
	{
		super.onSongLoaded(event);
		applyDarkShader();
	}

	function shadeObject(obj):Void
	{
		if (obj != null)
			obj.shader = xmasDarkShader;
	}

	function applyDarkShader():Void
	{
		if (xmasDarkShader == null)
			xmasDarkShader = HSVBlendedShader.xmasInit();

		shadeObject(getDad());
		shadeObject(getGirlfriend());
		shadeObject(getBoyfriend());

		var gf = getGirlfriend();
		if (gf != null)
		{
			try
			{
				if (gf.fgSnow != null)
					gf.fgSnow.shader = xmasDarkShader;
			}
			catch (err:Dynamic) {}
		}


		if (!lowQualityMode())
		{
			var miku = getNamedProp("rail-guys-miku");
			var bf = getBoyfriend();
			if (miku != null && bf != null)
				miku.alpha = (bf.characterId.indexOf("miku") == -1 ? 1 : 0.0001);

			for (name in ["tree-crushers", "meat-boy", "c-toy-1", "c-toy-2", "alien_ship"])
				shadeObject(getNamedProp(name));
		}

		for (name in ["zonet", "casset", "gang", "coolbud", "cops", "bandage_girl", "santa", "snowfg", "snowman"])
			shadeObject(getNamedProp(name));
	}

	function createSnowOverlay():Void
	{
		if (!shadersEnabled())
			return;

		snowShader = new FlxRuntimeShader(snowFrag);
		snowShader.setFloat("uTime", 0);

		snowSprite = new FunkinSprite();
		snowSprite.makeSolidColor(Std.int(FlxG.width * 3.5), Std.int(FlxG.height * 3.5), 0xFF99BBFF);
		snowSprite.zIndex = 395;
		add(snowSprite);
		refresh();
		snowSprite.scrollFactor.set(1.2, 1.2);
		snowSprite.screenCenter();
		snowSprite.shader = snowShader;

		snowBaseScaleX = snowSprite.scale.x;
		snowBaseScaleY = snowSprite.scale.y;

		snowShader.setFloatArray("uResolution", [snowSprite.width, snowSprite.height]);

		snowShader.setFloat("uDensity", 0.35);
		snowShader.setFloat("uFlakeSize", 2.0);
		snowShader.setFloat("uFallSpeed", 0.75);
		snowShader.setFloat("uWindStrength", 4.0);
		snowShader.setFloat("uTwinkle", 0.9);
		snowShader.setFloat("uOpacity", 0.75);
	}

	override function onUpdate(event)
	{
		super.onUpdate(event);

		if (snowShader == null || snowSprite == null)
			return;

		snowTime += event.elapsed;
		snowShader.setFloat("uTime", snowTime);

		var zoom = FlxG.camera.zoom;
		var f = (1 - snowZoomFactor) / zoom + snowZoomFactor;
		snowSprite.scale.set(snowBaseScaleX * f, snowBaseScaleY * f);
	}

	override function onBeatHit(event)
	{
		super.onBeatHit(event);

		if (lowQualityMode())
			return;

		if (leftTV != null && FlxG.random.bool(10))
			leftTV.anim.play("noise", true);

		if (rightTV != null && FlxG.random.bool(10))
			rightTV.anim.play("noise", true);

		if (event.beat % boppersIdle == 0)
			boppersBop();
	}

	function boppersBop():Void
	{
		for (p in railBoppers)
			bounceProp(p);
	}

	function bounceProp(p):Void
	{
		var bopperY = p.y;
		p.y += 10;
		new FlxTimer().start(2 / 24, function(t) { p.y = bopperY + 7.5; });
		new FlxTimer().start(4 / 24, function(t) { p.y = bopperY + 2.5; });
		new FlxTimer().start(6 / 24, function(t) { p.y = bopperY; });
	}

	override function onNoteHit(e)
	{
		super.onNoteHit(e);

		if (e.isComboBreak)
			makeCrowdLaugh();
	}

	override function onNoteGhostMiss(e)
	{
		super.onNoteGhostMiss(e);
		makeCrowdLaugh();
	}

	override function onNoteMiss(e)
	{
		if (e.eventCanceled || e.note.kind == "solotime")
			return;

		super.onNoteMiss(e);
		makeCrowdLaugh();
	}

	function makeCrowdLaugh():Void
	{
		var cops = getNamedProp("cops");
		if (cops == null)
			return;

		if (cops.getCurrentAnimation().indexOf("snowball") == -1)
			cops.playAnimation("laugh", true, true);
	}

	var _lowQualityProps = ['ceiling', 'upFreaks', 'rail-guys-far', 'goku', 'rail-guys-bobby', 'rail-guys-left', 'rail-guys-miku', 'rail-guys-right', 'candy', 'alien_ship', 'tree-crushers', 'meat-boy', 'c-toy-1', 'c-toy-2'];

	function removeLowQualityProps()
	{
		var i = 0;
		while (i < _lowQualityProps.length)
		{
			var name = _lowQualityProps[i];
			var prop = getNamedProp(name);
			if (prop != null)
			{
				FlxTween.cancelTweensOf(prop);
				boppers.remove(prop);
				namedProps.remove(name);
				remove(prop);
				prop.kill();
				prop.destroy();
			}
			i = i + 1;
		}
	}
}
