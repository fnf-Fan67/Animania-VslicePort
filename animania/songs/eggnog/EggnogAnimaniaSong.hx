package animania.songs.eggnog;

class EggnogAnimaniaSong extends Song
{
	function new()
	{
		super('eggnog-animania');
	}

	function shadersEnabled():Bool
	{
		return Save.instance.modOptions["shaders"] == true;
	}

	var playEggnogCountdownSounds:Bool = true;

	// Final cutscene (parents press the button, lights off)
	var hasPlayedCutscene:Bool = false;
	var cutsceneBlack = null;
	var cutsceneParents = null;
	var cutsceneFrameCb = null;
	var cutsceneLightsOff:Bool = false;

	var firefliesZoomFactor:Float = 0.35;

	var fireFliesShader = null;
	var fireFliesSpr = null;
	var fireFliesTime:Float = 0;
	var fireFliesBaseScaleX:Float = 1;
	var fireFliesBaseScaleY:Float = 1;

	var fireFliesFrag:String = "
#pragma header
uniform float iTime;
uniform vec2 iResolution;
uniform float iFireflyCount;
uniform float iFarFireflyCount;
uniform float uFireflySize;
uniform float uGlowRange;
#define MAX_FIREFLIES 24.0
#define MAX_FAR_FIREFLIES 24.0
const vec3 warmColor = vec3(0.9255, 0.7137, 0.5137);
const vec3 coolColor = vec3(0.9137, 0.9020, 0.6667);

float N21(vec2 p) {
    vec3 a = fract(vec3(p.xyx) * vec3(213.897, 653.453, 253.098));
    a += dot(a, a.yzx + 79.76);
    return fract((a.x + a.y) * a.z);
}
vec2 N22(vec2 p) {
    float n = N21(p);
    return vec2(n, N21(n + p));
}

float glowFalloffSq(float d2) {
    float r2 = uGlowRange * uGlowRange;
    if (d2 >= r2) return 0.0;
    float invDist = inversesqrt(max(d2, 0.00001));
    float glow = uFireflySize * invDist;
    float t = d2 / r2;
    glow *= (1.0 - t * t);
    return min(glow, 1.0);
}

void main() {
    vec2 uv = openfl_TextureCoordv * 2.0 - 1.0;
    float intensity = 0.0;
    float alpha = 0.0;

    for (float i = 0.0; i < MAX_FIREFLIES; i++) {
        if (i >= iFireflyCount) break;
        vec2 rnd = N22(vec2(i, i * 2.0));
        float angle = iTime * rnd.x + i;
        
        vec2 rndMod = N22(vec2(i + 0.5, i * 3.0 + 0.1));
        float rndSq = rndMod.x * rndMod.x;
        float radius = 2.0 * (0.1 + 0.9 * rndSq);
        vec2 center = 0.1 * vec2(sin(iTime * 0.4 + i), cos(iTime * 0.4 + i * 1.7));

        vec2 point = vec2(cos(angle) * radius, sin(angle)) + center;
        vec2 diff = uv - point;
        float d2 = dot(diff, diff);
        float glow = glowFalloffSq(d2);
        glow *= 0.35 + 0.65 * (0.5 + 0.5 * sin(angle * 1.35));
        intensity += glow;
        alpha += glow;
    }

    for (float i = 0.0; i < MAX_FAR_FIREFLIES; i++) {
        if (i >= iFarFireflyCount) break;
        float idx = i + 60.0;
        vec2 rnd = N22(vec2(idx, idx + 2.0));
        float angle = iTime * rnd.x + idx;
        
        vec2 rndMod = N22(vec2(idx + 0.5, idx * 3.0 + 0.1));
        float rndSq = rndMod.x * rndMod.x;
        float radius = 1.5 * (0.1 + 0.9 * rndSq);
        vec2 center = 0.08 * vec2(cos(iTime * 0.35 + idx), sin(iTime * 0.35 + idx * 1.4));

        vec2 point = vec2(cos(angle) * radius, sin(angle)) + center;
        vec2 diff = uv - point;
        float d2 = dot(diff, diff);
        float glow = glowFalloffSq(d2);
        glow *= 0.25 + 0.55 * (0.5 + 0.5 * sin(angle * 1.15));
        intensity += glow;
        alpha += glow;
    }

    alpha = clamp(alpha, 0.0, 1.0);
    vec3 color = mix(coolColor, warmColor, alpha);
    gl_FragColor = vec4(color * intensity, alpha);
}";

	override function onCreate(event)
	{
		super.onCreate(event);

		resetCutsceneState();

		if (Save.instance.modOptions['shaders'])
		{
			fireFliesShader = null;
			fireFliesSpr = null;
			fireFliesTime = 0;
		}

		createFadeIn();
		if (Save.instance.modOptions['shaders'])
		{
			createFireflies();
		}
	}

	function createFadeIn():Void
	{
		if (!PlayStatePlaylist.isStoryMode)
			return;

		var play = PlayState.instance;

		var screeeen = new FunkinSprite();
		screeeen.makeSolidColor(2000, 2000, 0xFF000000);
		screeeen.screenCenter();
		screeeen.cameras = [play.camHUD];
		screeeen.zIndex = 999999;
		screeeen.alpha = 1;
		play.add(screeeen);

		FlxTween.tween(screeeen, {alpha: 0}, 1, {ease: FlxEase.sineIn});

		play.refresh();
	}

	override function onBeatHit(event)
	{
		super.onBeatHit(event);

		var play = PlayState.instance;
		if (play == null || play.isPlayerDying)
			return;

		var stage = play.currentStage;
		if (stage == null)
			return;

		switch (event.beat)
		{
			case 221:
				var snowman = stage.getNamedProp("snowman");
				if (snowman != null)
					FlxTween.tween(snowman, {alpha: .4}, .25, {ease: FlxEase.backOut});

			case 222:
				var cops = stage.getNamedProp("cops");
				if (cops != null)
					cops.playAnimation("throw", true, true);

			case 224:
				if (play.health > .3)
					play.health -= .2;

			case 226:
				var dad = stage.getDad();
				if (dad != null)
					dad.playAnimation("eggL", true, true);

				var snowman = stage.getNamedProp("snowman");
				if (snowman != null)
					FlxTween.tween(snowman, {alpha: 1}, .25, {ease: FlxEase.backOut});

			case 232:
				setAngryIdle(stage);

			case 284:
				setAngryIdle(stage);
		}
	}

	function setAngryIdle(stage):Void
	{
		var dad = stage.getDad();
		if (dad == null)
			return;

		dad.idleSuffix = "-angry";
		dad.shouldAlternate = false;
	}

	function createFireflies():Void
	{
		if (!shadersEnabled())
			return;

		var stage = PlayState.instance.currentStage;
		if (stage == null)
			return;

		fireFliesShader = new FlxRuntimeShader(fireFliesFrag);
		fireFliesShader.setFloat("iTime", 0);

		fireFliesSpr = new FunkinSprite();
		fireFliesSpr.makeSolidColor(Std.int(FlxG.width * 2.5), Std.int(FlxG.height * 2.5), 0xFF000000);
		fireFliesSpr.zIndex = 390;
		stage.add(fireFliesSpr);
		stage.refresh();
		fireFliesSpr.scrollFactor.set(0.75, 0.75);
		fireFliesSpr.screenCenter();
		fireFliesSpr.blend = BlendMode.ADD;
		fireFliesSpr.shader = fireFliesShader;

		fireFliesBaseScaleX = fireFliesSpr.scale.x;
		fireFliesBaseScaleY = fireFliesSpr.scale.y;

		fireFliesShader.setFloat("iFireflyCount", 20);
		fireFliesShader.setFloat("iFarFireflyCount", 25);
		fireFliesShader.setFloat("uFireflySize", 0.01);
		fireFliesShader.setFloat("uGlowRange", 0.2);
		fireFliesShader.setFloatArray("iResolution", [fireFliesSpr.width, fireFliesSpr.height]);
	}

	override function onCountdownStart(event)
	{
		super.onCountdownStart(event);

		Countdown.soundSuffix = '-eggnog';
	}

	override function onSongRetry(event)
	{
		super.onSongRetry(event);

		resetCutsceneState();
	}

	function resetCutsceneState():Void
	{
		hasPlayedCutscene = false;
		cutsceneLightsOff = false;
		cutsceneBlack = null;
		cutsceneParents = null;
		cutsceneFrameCb = null;
	}

	override function onSongEnd(event)
	{
		super.onSongEnd(event);

		var play = PlayState.instance;
		if (play == null)
			return;

		// Freeplay: no cutscene.
		if (!PlayStatePlaylist.isStoryMode)
			hasPlayedCutscene = true;

		if (!hasPlayedCutscene)
		{
			hasPlayedCutscene = true;
			event.cancel();
			startEndCutscene();
		}
		else
		{
			// Make sure the cutscene can play again next time! DO NOT CANCEL THE EVENT!
			hasPlayedCutscene = false;
		}
	}

	function startEndCutscene():Void
	{
		var play = PlayState.instance;
		var stage = play.currentStage;
		var parents = stage != null ? stage.getDad() : null;

		play.disableKeys = true;

		// No parents / no animation: don't leave the song hanging, just end it.
		if (parents == null || !parents.hasAnimation("endCutscene"))
		{
			FlxTimer.wait(0.1, () -> endCutscene());
			return;
		}

		cutsceneParents = parents;
		cutsceneLightsOff = false;

		cutsceneBlack = new FunkinSprite();
		cutsceneBlack.makeSolidColor(2000, 2000, 0xFF000000);
		cutsceneBlack.scrollFactor.set();
		cutsceneBlack.screenCenter();
		cutsceneBlack.alpha = 0;
		cutsceneBlack.zIndex = 999999;
		stage.add(cutsceneBlack);
		stage.refresh();

		parents.isDead = true;
		play.tweenCameraZoom(1.5, 7.5, false, FlxEase.backOut);
		play.tweenCameraToPosition(-550, -70, 7.25, FlxEase.backOut);

		FlxTimer.wait(1.75, () -> playParentsPress());

		// Safety net: if the lights-off frame is never reported, force it.
		FlxTimer.wait(3.5, () -> cutsceneLightsOffNow());

		FlxTimer.wait(6.75, () -> endCutscene());
	}

	function playParentsPress():Void
	{
		var parents = cutsceneParents;
		if (parents == null)
			return;

		parents.playAnimation("endCutscene", true, true);
		FunkinSound.playOnce(Paths.sound("gameplay/stages/CityMall/parentsPress"));

		// Lights off on frame 39 of the animation (same as the original eggnog.hx).
		cutsceneFrameCb = function(name, frameNumber, frameIndex)
		{
			if (frameNumber >= 39)
				cutsceneLightsOffNow();
		};
		parents.animation.onFrameChange.add(cutsceneFrameCb);
	}

	function cutsceneLightsOffNow():Void
	{
		if (cutsceneLightsOff)
			return;

		var play = PlayState.instance;
		if (play == null || cutsceneBlack == null)
			return;

		cutsceneLightsOff = true;

		if (cutsceneParents != null && cutsceneFrameCb != null)
			cutsceneParents.animation.onFrameChange.remove(cutsceneFrameCb);
		cutsceneFrameCb = null;

		play.camHUD.alpha = 0.001;
		FunkinSound.playOnce(Paths.sound("gameplay/stages/CityMall/lightsOff"));
		cutsceneBlack.alpha = 1;

		if (cutsceneParents != null)
			cutsceneParents.zIndex = 101000100;
		if (play.currentStage != null)
			play.currentStage.refresh();
	}

	function endCutscene():Void
	{
		var play = PlayState.instance;
		if (play == null)
			return;

		// hasPlayedCutscene is true here, so onSongEnd lets the song finish this time.
		play.endSong(true);
	}

	override function onUpdate(event)
	{
		super.onUpdate(event);

		if (fireFliesShader == null || fireFliesSpr == null)
			return;

		fireFliesTime += event.elapsed * .25;
		fireFliesShader.setFloat("iTime", fireFliesTime);

		var zoom = FlxG.camera.zoom;
		var f = (1 - firefliesZoomFactor) / zoom + firefliesZoomFactor;
		fireFliesSpr.scale.set(fireFliesBaseScaleX * f, fireFliesBaseScaleY * f);
	}
}
