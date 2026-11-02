package animania.songs.dadbattle;

class DadBattleAnimania extends Song
{
	function new()
	{
		super('dadbattle-animania');
	}

	var useDangerBar:Bool = true;
	var useGodRays:Bool = true;

	var videoBeat = 223;

	var bfRef = null;
	var dadRef = null;
	var reflectionShaderDad = null;
	var reflectionShaderBf = null;
	var reflectionTime = 0;

	var chromShader = null;
	var chromChangeTween = null;

	var shaderTime = 0.0;

	var vid = null;
	var videoStarted = false;
	var hiddenHud = [];

	var videoToken = 0;
	var videoPrecached = false;
	var videoReady = false;
	var videoPending = false;
	var videoPlaying = false;
	var videoFinished = false;
	var videoWait = 0.0;
	var videoPlayTime = 0.0;
	var videoStallTime = 0.0;
	var videoMaxWait = 3.0;
	var videoStallMax = 2.0;
	var videoEndBeat = 250;

	var overlayBaseAlpha = null;
	var dadIdleBase = "";

	var dangerBar = null;
	var dangerShader = null;
	var dangerBarTried = false;
	var dangerSource = null;
	var dangerPulse = -300.0;
	var dangerLastHv = -1.0;

	var godRaysSpr = null;
	var godRaysShader = null;

	var fgOverlayRef = null;
	var lastChromOverlayAlpha = -1.0;

	var godRaysZoomFactor = 0.0;
	var godRaysScrollX = 1.0;
	var godRaysScrollY = 0.0;
	var godRaysBaseX = 0.0;
	var godRaysBaseY = 0.0;
	var godRaysBaseScaleX = 1.0;
	var godRaysBaseScaleY = 1.0;
	var godRaysBaseW = 1.0;
	var godRaysBaseH = 1.0;


	var useModchart = !Save.instance.modOptions["lowQuality"];
	var dadYYPos = -175;
	var oppFieldScale = 1.15;
	var hideOpponentCovers = true;
	var oppAnchorDX = 0.0;
	var oppAnchorDY = 0.0;
	var oppShakeIntensity = 0.05;
	var oppShakeTime = 0.1;

	var mlOpp = null;
	var mlPlr = null;
	var mlTw = new StringMap();
	var mlPlaced = false;
	var mlBaseIntroKilled = false;
	var mlStage = 0;
	var mlTriggers = [];
	var mlInIdle = true;
	var mlOppRecs = [];
	var mlPlrRecs = [];
	var mlPlrRecScale = 1.0;
	var mlPlrNoteScale = 1.0;
	var mlOppIncomingFn = null;
	var mlPlrIncomingFn = null;
	var mlPostFn = null;

	function mlLane()
	{
		return {ox: 0.0, oy: 0.0, bobAmp: 0.0, alpha: 1.0, pulse: 1.0, ax: 0.0, ay: 0.0, pa: 1.0,
			b0: 0.0, b1: 0.0, b2: 0.0, b3: 0.0, offs: [0.0, 0.0, 0.0, 0.0], ry: [0.0, 0.0, 0.0, 0.0], waveOn: false,
			skI: 0.0, skT: [0.0, 0.0, 0.0, 0.0], skH: [false, false, false, false], sx: [0.0, 0.0, 0.0, 0.0], sy: [0.0, 0.0, 0.0, 0.0]};
	}

	function mlTo(name, L, field, target, secs, ease, delay)
	{
		var key = name + ":" + field;
		var old = mlTw.get(key);
		if (old != null) old.cancel();

		var tw = FlxTween.num(Reflect.field(L, field), target, secs, {ease: ease, startDelay: delay}, function(v) {
			Reflect.setField(L, field, v);
		});
		mlTw.set(key, tw);
	}

	function mlBob(name, L, half)
	{
		var c = 0;
		while (c < 4)
		{
			var f = "b" + c;
			var key = name + ":" + f;
			var old = mlTw.get(key);
			if (old != null) old.cancel();

			Reflect.setField(L, f, -1.0);
			var vals = {};
			Reflect.setField(vals, f, 1.0);
			mlTw.set(key, FlxTween.tween(L, vals, half, {type: 4, ease: FlxEase.sineInOut, startDelay: c * 0.573 * half}));
			c += 1;
		}
	}

	function mlUndoLane(s, L, recs)
	{
		if (s == null || L == null) return;
		if (L.ax != 0) s.x -= L.ax;
		if (L.ay != 0) s.y -= L.ay;
		L.ax = 0.0;
		L.ay = 0.0;
		L.pa = 1.0;

		var c = 0;
		while (c < 4)
		{
			if (L.ry[c] != 0 && c < recs.length && recs[c] != null) recs[c].y -= L.ry[c];
			L.ry[c] = 0.0;
			if ((L.sx[c] != 0 || L.sy[c] != 0) && c < recs.length && recs[c] != null)
			{
				recs[c].x -= L.sx[c];
				recs[c].y -= L.sy[c];
			}
			L.sx[c] = 0.0;
			L.sy[c] = 0.0;
			c += 1;
		}
		L.waveOn = false;
	}

	function mlUndo(game)
	{
		if (!mlPlaced || game == null || mlOpp == null) return;

		mlUndoLane(game.opponentStrumline, mlOpp, mlOppRecs);
		mlUndoLane(game.playerStrumline, mlPlr, mlPlrRecs);

		var c = 0;
		while (c < mlPlrRecs.length)
		{
			var r = mlPlrRecs[c];
			if (r != null) r.scale.set(mlPlrRecScale, mlPlrRecScale);
			c += 1;
		}
	}

	// Strumline.fadeInArrows() (initStrumlines del juego base) deja un tween de y/alpha en cada flecha
	// que apunta a la posicion ORIGINAL del juego base (abajo con downscroll). Ese tween arranca en el
	// countdown, arrastra el strum de vuelta y le pisa el alpha, cortando la intro del modchart.
	// restoreY: fadeInArrow ya resto 10 a cada flecha; si el tween no arranco todavia (onCreate) se devuelve.
	function mlKillBaseIntro(s, restoreY)
	{
		if (s == null || s.strumlineNotes == null) return;

		var mem = s.strumlineNotes.members;
		var c = 0;
		while (c < mem.length)
		{
			var arrow = mem[c];
			if (arrow != null)
			{
				FlxTween.cancelTweensOf(arrow);
				arrow.alpha = 0.0;
				if (restoreY) arrow.y += 10.0;
			}
			c += 1;
		}
	}

	// NoteHoldCover.revive() fuerza alpha = 1 en cada hold nuevo; se iguala al alpha del strum del oponente.
	function mlSyncCovers(s, L)
	{
		if (s == null || L == null || s.noteHoldCovers == null) return;

		var cm = s.noteHoldCovers.members;
		var i = 0;
		while (i < cm.length)
		{
			var cv = cm[i];
			i += 1;
			if (cv != null && cv.alive && cv.alpha != L.alpha) cv.alpha = L.alpha;
		}
	}

	function mlHidePre(game)
	{
		if (game == null || mlPlaced) return;

		if (game.playerStrumline != null && game.playerStrumline.alpha != 0) game.playerStrumline.alpha = 0;
		if (game.opponentStrumline != null && game.opponentStrumline.alpha != 0) game.opponentStrumline.alpha = 0;
	}

	function mlInit(game)
	{
		mlUndo(game);

		for (k in mlTw.keys())
		{
			var t = mlTw.get(k);
			if (t != null) t.cancel();
		}
		mlTw = new StringMap();

		useModchart = !Save.instance.modOptions["lowQuality"];

		mlOpp = mlLane();
		mlPlr = mlLane();
		mlStage = 0;
		mlInIdle = true;
		mlPlrNoteScale = 1.0;
		mlTriggers = [31, 37, videoBeat, 284, 384];

		mlOpp.alpha = 0.0;
		if (useModchart)
		{
			mlOpp.ox = -200;
			mlOpp.oy = dadYYPos - 50;
			mlOpp.bobAmp = 7.5;
			mlOpp.skI = oppShakeIntensity;
			mlBob("opp", mlOpp, 1.309);
		}

		mlPlr.alpha = 0.0;
		mlPlr.ox = 50;
		mlPlr.oy = 50;

		if (!mlBaseIntroKilled && game != null && game.opponentStrumline != null && game.playerStrumline != null)
		{
			mlKillBaseIntro(game.opponentStrumline, true);
			mlKillBaseIntro(game.playerStrumline, true);
			mlBaseIntroKilled = true;
		}
		mlHidePre(game);

		if (mlPostFn == null)
		{
			mlPostFn = function() {
				mlPost();
			};
			FlxG.signals.postUpdate.add(mlPostFn);
		}
	}

	function mlPlace(game)
	{
		if (game == null || game.currentStage == null || mlOpp == null) return;

		var stage = game.currentStage;
		var s = game.opponentStrumline;
		var dad = stage.getDad();
		if (s == null || dad == null) return;

		var c = 0;
		mlPlrRecs = [];
		mlOppRecs = [];
		while (c < 4)
		{
			mlPlrRecs[c] = game.playerStrumline.getByIndex(c);
			mlOppRecs[c] = s.getByIndex(c);
			c += 1;
		}

		if (!mlPlaced)
		{
			mlPlrRecScale = mlPlrRecs[0].scale.x;

			if (!mlBaseIntroKilled)
			{
				mlKillBaseIntro(s, false);
				mlKillBaseIntro(game.playerStrumline, false);
				mlBaseIntroKilled = true;
			}

			s.isDownscroll = true;
			s.strumlineScale.set(oppFieldScale, oppFieldScale);

			game.remove(s, true);
			stage.add(s);
			s.cameras = [game.camGame];

			var m = 0;
			while (m < s.members.length)
			{
				var mem = s.members[m];
				if (mem != null && mem != s.strumlineNotes && mem != s.noteHoldCovers) mem.visible = false;
				m += 1;
			}

			s.showNotesplash = false;

			mlOppIncomingFn = function(n) {
				mlOnIncoming(n, 0);
			};
			mlPlrIncomingFn = function(n) {
				mlOnIncoming(n, 1);
			};
			s.onNoteIncoming.add(mlOppIncomingFn);
			game.playerStrumline.onNoteIncoming.add(mlPlrIncomingFn);
		}

		s.visible = useModchart;

		s.zIndex = dad.zIndex - 2;
		s.x = dad.x + dad.width * 0.6 - s.width * 0.5 + oppAnchorDX;
		s.y = dad.y + dad.height * 0.3 + oppAnchorDY;
		mlOpp.ax = 0.0;
		mlOpp.ay = 0.0;
		stage.refresh();

		mlPlaced = true;

		mlApply(s, mlOpp, mlOppRecs);
		mlApply(game.playerStrumline, mlPlr, mlPlrRecs);
	}

	function mlOnIncoming(n, lane)
	{
		if (n == null) return;

		var L = (lane == 0) ? mlOpp : mlPlr;
		if (L == null) return;

		n.alpha = L.alpha;
		var h = n.holdNoteSprite;
		if (h != null) h.alpha = L.alpha;
		if (h != null && lane == 0 && !h.flipY)
		{
			h.flipY = true;
			h.updateClipping();
		}

		n.yOffset = L.offs[n.direction % 4];
		if (h != null) h.yOffset = L.offs[n.direction % 4];

		if (lane == 1 && mlPlrNoteScale != 1.0) n.scale.set(n.scale.x * mlPlrNoteScale, n.scale.y * mlPlrNoteScale);
	}

	function mlApply(s, L, recs)
	{
		if (s == null) return;

		if (s.alpha != L.alpha) s.alpha = L.alpha;
		if (L.alpha <= 0.0) return;

		if (L.ox != L.ax)
		{
			s.x += L.ox - L.ax;
			L.ax = L.ox;
		}
		if (L.oy != L.ay)
		{
			s.y += L.oy - L.ay;
			L.ay = L.oy;
		}

		if (L.skI > 0)
		{
			var skT = L.skT;
			var skH = L.skH;
			var sx = L.sx;
			var sy = L.sy;
			var k = 0;
			while (k < 4)
			{
				var tx = 0.0;
				var ty = 0.0;
				if (skT[k] > 0 || skH[k])
				{
					skT[k] -= FlxG.elapsed;
					var mag = L.skI * recs[k].width;
					tx = FlxG.random.float(-mag, mag);
					ty = FlxG.random.float(-mag, mag);
				}
				if (tx != sx[k] || ty != sy[k])
				{
					recs[k].x += tx - sx[k];
					recs[k].y += ty - sy[k];
					sx[k] = tx;
					sy[k] = ty;
				}
				k += 1;
			}
		}

		var amp = L.bobAmp;
		if (amp == 0 && !L.waveOn) return;

		var offs = L.offs;
		offs[0] = amp * L.b0;
		offs[1] = amp * L.b1;
		offs[2] = amp * L.b2;
		offs[3] = amp * L.b3;
		L.waveOn = (amp != 0);

		var ry = L.ry;
		var c = 0;
		while (c < 4)
		{
			var d = offs[c] - ry[c];
			if (d != 0)
			{
				recs[c].y += d;
				ry[c] = offs[c];
			}
			c += 1;
		}

		var nm = s.notes.members;
		var nl = nm.length;
		var i = 0;
		while (i < nl)
		{
			var n = nm[i];
			i += 1;
			if (n != null && n.alive) n.yOffset = offs[n.direction % 4];
		}

		var hm = s.holdNotes.members;
		var hl = hm.length;
		i = 0;
		while (i < hl)
		{
			var h = hm[i];
			i += 1;
			if (h != null && h.alive) h.yOffset = offs[h.noteDirection % 4];
		}
	}

	function mlPost()
	{
		if (!mlPlaced) return;

		var game = PlayState.instance;
		if (game == null) return;

		mlSyncCovers(game.opponentStrumline, mlOpp);
		mlPostLane(game.opponentStrumline, mlOpp);
		mlPostLane(game.playerStrumline, mlPlr);
	}

	function mlPostLane(s, L)
	{
		if (s == null || L == null || !L.waveOn || L.alpha <= 0.0) return;

		var songPos = Conductor.instance.songPosition;
		var hm = s.holdNotes.members;
		var hl = hm.length;
		var i = 0;
		while (i < hl)
		{
			var h = hm[i];
			i += 1;
			if (h == null || !h.alive) continue;

			if (h.hitNote && !h.missedNote && songPos > h.strumTime && h.sustainLength > 0) h.y += L.offs[h.noteDirection % 4];
		}
	}

	function mlApplyPulse()
	{
		var L = mlPlr;
		if (L.pulse == L.pa) return;

		L.pa = L.pulse;
		var sc = mlPlrRecScale * L.pulse;
		var c = 0;
		while (c < mlPlrRecs.length)
		{
			mlPlrRecs[c].scale.set(sc, sc);
			c += 1;
		}
	}

	function mlUpdate(game, elapsed)
	{
		if (!mlPlaced)
		{
			mlHidePre(game);
			return;
		}
		if (game.currentStage == null) return;

		if (useModchart)
		{
			mlOpponentIdle(game);
			mlDrainHolds(game, elapsed);
		}

		mlApply(game.opponentStrumline, mlOpp, mlOppRecs);
		mlApply(game.playerStrumline, mlPlr, mlPlrRecs);
		mlApplyPulse();
	}

	function mlBeat(beat)
	{
		if (!mlPlaced) return;

		var bl = Conductor.instance.beatLengthMs / 1000;

		while (mlStage < mlTriggers.length && beat >= mlTriggers[mlStage])
		{
			mlFire(mlStage, bl);
			mlStage += 1;
		}

		if (beat > 283 && beat % 2 == 0)
		{
			mlPlr.pulse = 1.1;
			mlTo("plr", mlPlr, "pulse", 0.95, bl, FlxEase.sineOut, 0);
		}
	}

	function mlFire(stage, bl)
	{
		if (stage == 0)
		{
			if (useModchart)
			{
				mlTo("opp", mlOpp, "alpha", 0.5, 0.5 * bl, FlxEase.quadOut, 0);
				mlTo("opp", mlOpp, "oy", dadYYPos, 0.5 * bl, FlxEase.circOut, 0);
			}
		}
		else if (stage == 1)
		{
			mlTo("plr", mlPlr, "alpha", 1, 1.6 * bl, FlxEase.quadOut, 0);
			mlTo("plr", mlPlr, "oy", 0, 1.6 * bl, FlxEase.circOut, 0);
			mlTo("plr", mlPlr, "ox", 0, 2 * bl, FlxEase.circOut, 0);
		}
		else if (stage == 2)
		{
			mlTo("plr", mlPlr, "alpha", 0, bl, FlxEase.circOut, 0);
		}
		else if (stage == 3)
		{
			mlTo("plr", mlPlr, "alpha", 1, 1.75 * bl, FlxEase.sineInOut, 0);
			mlPlrNoteScale = 0.95;
		}
		else if (stage == 4)
		{
			var whereWeGo = AmScroll.isDown() ? 30 : -30;
			mlTo("plr", mlPlr, "alpha", 0, bl, FlxEase.sineIn, 0);
			mlTo("plr", mlPlr, "oy", whereWeGo, bl, FlxEase.sineIn, 0);
		}
	}

	function mlVideoEnd()
	{
		if (mlPlr == null) return;

		mlBob("plr", mlPlr, 0.873);
		mlTo("plr", mlPlr, "bobAmp", 10.4, 6.5, FlxEase.circOut, 0.5);
	}

	function mlHit(dir)
	{
		var xx = -200;
		var yy = dadYYPos;

		if (dir == 0) xx -= 25;
		else if (dir == 1) yy += 20;
		else if (dir == 2) yy -= 45;
		else if (dir == 3) xx += 35;

		mlInIdle = false;
		mlOpp.skT[dir] = oppShakeTime;
		mlTo("opp", mlOpp, "ox", xx, 0.1, FlxEase.circOut, 0);
		mlTo("opp", mlOpp, "oy", yy, 0.1, FlxEase.circOut, 0);
	}

	function mlOpponentIdle(game)
	{
		if (mlInIdle) return;

		var dad = game.currentStage.getDad();
		if (dad == null || dad.animation.curAnim == null) return;

		if (dad.animation.curAnim.name.indexOf("idle") != -1)
		{
			mlInIdle = true;
			mlTo("opp", mlOpp, "ox", -200, 0.25, FlxEase.circOut, 0);
			mlTo("opp", mlOpp, "oy", dadYYPos + (dad.idleSuffix == "" ? 0 : -50), 0.25, FlxEase.circOut, 0);
		}
	}

	function mlDrainHolds(game, elapsed)
	{
		var hm = game.opponentStrumline.holdNotes.members;
		var n = hm.length;
		var skH = mlOpp.skH;
		skH[0] = false;
		skH[1] = false;
		skH[2] = false;
		skH[3] = false;
		var i = 0;
		while (i < n)
		{
			var h = hm[i];
			i += 1;
			if (h == null || !h.alive) continue;

			if (h.hitNote && !h.missedNote && h.sustainLength > 0)
			{
				mlDrainHealth(game, 0.075 * elapsed);
				skH[h.noteDirection % 4] = true;
			}
		}
	}

	function mlDrainHealth(game, amount)
	{
		if (game.health <= .1) return;

		var bf = game.currentStage.getBoyfriend();
		var mult = (bf != null && bf.idleSuffix != "") ? Math.max(1, game.health * .85) : 1;
		game.health -= amount * mult;
	}

	var refShader = "
	#pragma header

	uniform float iTime;

	uniform float bend;
	uniform float rightBend;

	float rand(vec2 co)
	{
        return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
	}

	vec3 applyHue(vec3 aColor, float aHue)
	{
        float angle = radians(aHue);
		vec3 k = vec3(0.57735, 0.57735, 0.57735);
		float cosAngle = cos(angle);
		return aColor * cosAngle + cross(k, aColor) * sin(angle) + k * dot(k, aColor) * (1.0 - cosAngle);
	}

	vec3 applyHSBCEffect(vec3 color)
	{
        color = applyHue(color, -26.0);
		return color;
	}

	void main()
	{
    	vec2 uv = openfl_TextureCoordv;

		float x = uv.x * 2.0 - 1.0;

		float centerCurve = 1.0 - x * x;

		float rightCurve = smoothstep(0.0, 1.0, uv.x);
		rightCurve *= rightCurve;

		uv.y -= centerCurve * bend;
		uv.y -= rightCurve * rightBend;

		vec4 color = flixel_texture2D(bitmap, uv);

		if (color.a < 0.01)
			discard;

		uv.y += sin((uv.x * 56.0) + iTime * 3.0) * 0.011;

		vec4 refl = flixel_texture2D(bitmap, uv);

		vec2 px = 1.0 / openfl_TextureSize;
		vec4 blur = vec4(0.0);

		blur += flixel_texture2D(bitmap, uv + vec2(-6.0 * px.x, 0.0));
		blur += flixel_texture2D(bitmap, uv + vec2(-3.0 * px.x, 0.0));
		blur += refl * 2.0;
		blur += flixel_texture2D(bitmap, uv + vec2(3.0 * px.x, 0.0));
		blur += flixel_texture2D(bitmap, uv + vec2(6.0 * px.x, 0.0));

		refl = blur / 6.0;
		refl.rgb *= 0.45;

		float lum = dot(refl.rgb, vec3(0.299, 0.587, 0.114));
		float sparkle = step(0.995, rand(floor(uv * 350.0) + floor(iTime * 8.0))) * smoothstep(0.55, 1.0, lum);

		refl.rgb += vec3(sparkle * 0.45);

		float visibility = smoothstep(0.6, 1.0, uv.y);
		float a = refl.a * visibility;

		refl.rgb = applyHSBCEffect(refl.rgb / max(refl.a, 0.0001)) * refl.a;

		gl_FragColor = vec4(refl.rgb * a, a);
	}";

	var dangerGrad = "
	#pragma header

	uniform float cutoff;
	uniform float fadeSize;
	uniform vec3 gradientColor;
	uniform float gradientAlpha;

	void main()
	{
		vec2 uv = openfl_TextureCoordv;
		vec4 tex = flixel_texture2D(bitmap, uv);

		if (tex.a <= 0.0 || uv.x < cutoff - 5.0)
			discard;

		float visibility = 1.0 - smoothstep(cutoff, cutoff + fadeSize, uv.x);

		float a = tex.a * visibility * gradientAlpha;

		gl_FragColor = vec4(gradientColor * a, a);
	}";

	var godLight = "
	#pragma header

	uniform float iTime;
	uniform vec2 resolution;
	uniform vec3 rayColor;
	uniform float outAlpha;

	float rayStrength(vec2 raySource, vec2 rayRefDirection, vec2 coord, float seedA, float seedB, float speed)
	{
		vec2 sourceToCoord = coord - raySource;
		float cosAngle = dot(normalize(sourceToCoord), rayRefDirection);

		return clamp(
			(0.45 + 0.15 * sin(cosAngle * seedA + iTime * speed)) +
			(0.30 + 0.20 * cos(-cosAngle * seedB + iTime * speed)),
			0.0,
			1.0
		) *
		clamp(
			(resolution.x - length(sourceToCoord)) / resolution.x,
			0.5,
			1.0
		);
	}

	void main()
	{
		vec2 uv = openfl_TextureCoordv;

		vec2 coord = vec2(
			uv.x * resolution.x,
			(1.0 - uv.y) * resolution.y
		);

		vec2 rayPos1 = vec2(
			resolution.x * 0.2,
			resolution.y * 1.5
		);

		vec2 rayRefDir1 = normalize(vec2(1.0, -0.116));

		vec2 rayPos2 = vec2(
			resolution.x * 0.3,
			resolution.y * 1.6
		);

		vec2 rayRefDir2 = normalize(vec2(1.0, 0.241));

		vec4 rays1 = vec4(1.0) *
			rayStrength(
				rayPos1,
				rayRefDir1,
				coord,
				36.2214,
				21.11349,
				1.5
			);

		vec4 rays2 = vec4(1.0) *
			rayStrength(
				rayPos2,
				rayRefDir2,
				coord,
				22.39910,
				18.0234,
				1.1
			);

		vec4 rays = rays1 * 0.5 + rays2 * 0.4;

		float brightness = 1.0 - coord.y / resolution.y;

		rays.rgb *= rayColor;

		float contrast = 2.0;
		rays.rgb = (rays.rgb - 0.5) * contrast + 0.5;
		rays.rgb = clamp(rays.rgb, 0.0, 1.0);

		float spriteAlpha = flixel_texture2D(bitmap, uv).a;

		rays.rgb *= spriteAlpha;
		gl_FragColor = vec4(rays.rgb, spriteAlpha * outAlpha);
	}";

	function applyStagePosition(char, stageCharData)
	{
		if (!Save.instance.modOptions['lowQuality'] && char == null || stageCharData == null) return;

		char.zIndex = stageCharData.zIndex;
		char.x = stageCharData.position[0] - char.characterOrigin.x;
		char.y = stageCharData.position[1] - char.characterOrigin.y;

		var finalScale = char.getBaseScale() * stageCharData.scale;
		char.setScale(finalScale);

		char.scrollFactor.x = stageCharData.scroll[0];
		char.scrollFactor.y = stageCharData.scroll[1];

		char.alpha = stageCharData.alpha;
		char.angle = stageCharData.angle;
	}

	function mirrorAnimation(refChar, realChar)
	{
		if (refChar == null || realChar == null) return;
		if (realChar.animation.curAnim == null) return;

		if (refChar.animation.curAnim == null || refChar.animation.curAnim.name != realChar.animation.curAnim.name)
		{
			refChar.playAnimation(realChar.animation.curAnim.name, false);
		}
	}

	function getCurvedRedBar()
	{
		var mod = ModuleHandler.getModule("CurvedHealthBarModule");
		if (mod == null) return null;
		return mod.redBar;
	}

	function trySetupDangerBar(game)
	{
		if (!Save.instance.modOptions["shaders"] || dangerBar != null || dangerBarTried) return;
		if (game.healthBar == null) return;

		var curved = getCurvedRedBar();

		if (curved == null && shaderTime < 1.0 && ModuleHandler.getModule("CurvedHealthBarModule") != null) return;

		dangerBarTried = true;
		dangerSource = curved;

		dangerBar = new FunkinSprite();
		dangerBar.loadGraphic(Paths.image("ui/healthbar/WHITEBAR"));
		dangerBar.scrollFactor.set(0, 0);
		dangerBar.cameras = [game.camHUD];
		dangerBar.zIndex = 805;

		dangerShader = new FlxRuntimeShader(dangerGrad);
		dangerShader.setFloat("cutoff", 0.5);
		dangerShader.setFloat("fadeSize", 0.5);
		dangerShader.setFloatArray("gradientColor", [1.0, 0.0, 0.0]);
		dangerShader.setFloat("gradientAlpha", 1.0);
		dangerBar.shader = dangerShader;

		game.add(dangerBar);
		game.refresh();
	}

	function updateDangerBar(game, elapsed)
	{
		if (!Save.instance.modOptions['shaders']) return;
		trySetupDangerBar(game);
		if (dangerBar == null || dangerShader == null) return;

		var hv = game.healthBar.value;

		dangerPulse += elapsed * hv;

		if (dangerSource != null)
		{
			dangerBar.x = dangerSource.x;
			dangerBar.y = dangerSource.y;
			dangerBar.flipY = dangerSource.flipY;
		}
		else
		{
			dangerBar.x = game.healthBar.x;
			dangerBar.y = game.healthBar.y;
			dangerBar.flipY = AmScroll.isDown();
		}

		if (hv != dangerLastHv)
		{
			dangerLastHv = hv;
			dangerShader.setFloat("cutoff", 1 - (hv / 2));
			dangerShader.setFloat("fadeSize", (hv / 2) * .9);
		}
		dangerShader.setFloat("gradientAlpha", Math.cos(FlxEase.sineInOut(dangerPulse)));
	}

	function setupGodRays(game)
	{
		if (!Save.instance.modOptions["shaders"]) return;

		var stage = game.currentStage;

		godRaysSpr = new StageProp();
		godRaysSpr.makeSolidColor(Std.int(FlxG.width * 1.5), FlxG.height, FlxColor.BLACK);
		godRaysSpr.screenCenter();
		godRaysSpr.scrollFactor.set(godRaysScrollX, godRaysScrollY);

		var holyGrad = stage.getNamedProp("holygrad");
		if (holyGrad != null) holyGrad.alpha = 0;
		#if mobile
		if (holyGrad != null) holyGrad.blend = BlendMode.SCREEN;
		#end
		godRaysSpr.zIndex = (holyGrad != null) ? holyGrad.zIndex - 2 : stage.getDad().zIndex - 3;

		godRaysShader = new FlxRuntimeShader(godLight);
		godRaysShader.setFloatArray("rayColor", [1.3, 1.2, 0.9]);
		godRaysShader.setFloatArray("resolution", [godRaysSpr.width, godRaysSpr.height]);
		godRaysShader.setFloat("iTime", 0);
		godRaysShader.setFloat("outAlpha", 1.0);
		#if mobile
		godRaysShader.setFloat("outAlpha", 0.0);
		#end

		godRaysSpr.shader = godRaysShader;
		godRaysSpr.blend = BlendMode.ADD;
		godRaysSpr.alpha = 0;

		stage.addProp(godRaysSpr, "godRays");
		stage.refresh();

		godRaysBaseX = godRaysSpr.x;
		godRaysBaseY = godRaysSpr.y;
		godRaysBaseScaleX = godRaysSpr.scale.x;
		godRaysBaseScaleY = godRaysSpr.scale.y;
		godRaysBaseW = godRaysSpr.width;
		godRaysBaseH = godRaysSpr.height;

		applyGodRaysZoomFactor(game);
	}

	function applyGodRaysZoomFactor(game)
	{
		if (godRaysSpr == null) return;

		var cam = game.camGame;
		var zoom = cam.zoom;
		if (zoom <= 0) return;

		var s = Math.max(0, (1 - godRaysZoomFactor) / zoom + godRaysZoomFactor);

		godRaysSpr.scale.set(godRaysBaseScaleX * s, godRaysBaseScaleY * s);
		godRaysSpr.updateHitbox();

		var w = godRaysBaseW * s;
		var h = godRaysBaseH * s;

		var cx = godRaysBaseX + godRaysBaseW * 0.5 - cam.scroll.x * godRaysScrollX;
		var cy = godRaysBaseY + godRaysBaseH * 0.5 - cam.scroll.y * godRaysScrollY;

		var ox = cam.width * 0.5;
		var oy = cam.height * 0.5;

		var nx = (cx - ox) * s + ox;
		var ny = (cy - oy) * s + oy;

		godRaysSpr.x = nx - w * 0.5 + cam.scroll.x * godRaysScrollX;
		godRaysSpr.y = ny - h * 0.5 + cam.scroll.y * godRaysScrollY;
	}

	function hookVideo(v, token, game)
	{
		v.bitmap.onFormatSetup.add(function() {
			if (token != videoToken || vid != v) return;
			v.setGraphicSize(FlxG.width, FlxG.height);
			v.updateHitbox();
			v.screenCenter();
			videoReady = true;
		});

		v.bitmap.onEndReached.add(function() {
			if (token != videoToken || vid != v || !videoPlaying) return;
			onVideoEnd(game);
		});

		v.bitmap.onEncounteredError.add(function(msg) {
			if (token != videoToken || vid != v) return;
			trace("[DadBattleAnimania] error de video: " + msg);

			if (videoStarted) onVideoEnd(game);
			else destroyVideo(game);
		});
	}

	function destroyVideo(game)
	{
		videoToken += 1;
		videoReady = false;
		videoPending = false;
		videoPlaying = false;
		videoPrecached = false;

		if (vid == null) return;

		var v = vid;
		vid = null;

		v.visible = false;
		try
		{
			v.stop();
		}
		catch (e:Dynamic) {}
		if (game != null) game.remove(v, true);
		try
		{
			v.destroy();
		}
		catch (e:Dynamic) {}
	}

	function destroyVideoLater(v, game)
	{
		v.visible = false;
		try
		{
			v.stop();
		}
		catch (e:Dynamic) {}
		if (game != null) game.remove(v, true);

		new FlxTimer().start(0.05, function(_) {
			try
			{
				v.destroy();
			}
			catch (e:Dynamic) {}
		});
	}

	function setupVideo(game)
	{
		destroyVideo(game);

		var token = videoToken;
		var path = Paths.videos("DADBATTLE_SOLOTIME_CUTSCENE.mkv");

		var v = new FunkinVideoSprite();
		v.bitmap.volumeAdjust = 0;
		v.scrollFactor.set();
		v.cameras = [game.camHUD];
		v.zIndex = 0;
		v.visible = false;
		v.antialiasing = true;

		vid = v;
		hookVideo(v, token, game);

		var ok = false;
		try
		{
			ok = v.precache(path);
		}
		catch (e:Dynamic)
		{
			ok = false;
		}
		videoPrecached = ok;

		if (!ok)
		{
			try
			{
				ok = v.load(path);
			}
			catch (e:Dynamic)
			{
				ok = false;
			}
		}

		if (!ok)
		{
			vid = null;
			videoToken += 1;
			try
			{
				v.destroy();
			}
			catch (e:Dynamic) {}
			return;
		}

		game.add(v);
		game.refresh();
	}

	function setHudHidden(game, hidden)
	{
		if (hidden)
		{
			if (hiddenHud.length > 0) return;

			var objs = [game.healthBarBG, game.healthBar, game.iconP1, game.iconP2, dangerBar];

			var mod = ModuleHandler.getModule("CurvedHealthBarModule");
			if (mod != null)
			{
				objs.push(mod.bg);
				objs.push(mod.redBar);
				objs.push(mod.greenBar);
			}

			var score = ModuleHandler.getModule("AnimaniaScoreModule");
			if (score != null)
			{
				objs.push(score.scoreLabel);
				for (i in 0...score.scoreDigits.length)
				{
					var i = score.scoreDigits[i];
					objs.push(i);
				}
			}

			var fc = ModuleHandler.getModule("FullComboSpr");
			if (fc != null)
			{
				objs.push(fc.fcSprite);
			}

			for (o in objs)
			{
				if (o == null) continue;
				hiddenHud.push({obj: o, alpha: o.alpha});
				o.alpha = 0;
			}
		}
		else
		{
			for (h in hiddenHud) h.obj.alpha = h.alpha;
			hiddenHud = [];
		}
	}

	function startVideo(game)
	{
		if (videoStarted) return;
		videoStarted = true;

		if (vid == null)
		{
			onVideoEnd(game);
			return;
		}

		vid.bitmap.volumeAdjust = 0;
		if (videoPrecached) vid.resume();
		else vid.play();

		videoWait = 0.0;
		videoPlayTime = 0.0;
		videoStallTime = 0.0;

		if (videoReady)
		{
			showVideo(game);
		}
		else
		{
			videoPending = true;
		}
	}

	function showVideo(game)
	{
		videoPending = false;
		videoPlaying = true;
		videoPlayTime = 0.0;
		videoStallTime = 0.0;

		vid.visible = true;
		vid.antialiasing = true;

		setHudHidden(game, true);

		game.disableKeys = true;
		new FlxTimer().start(.15, function(_) {
			if (game.vocals != null) game.vocals.playerVolume = 1;
		});
	}

	function updateVideo(game, elapsed)
	{
		if (!videoStarted)
		{
			var bt = Conductor.instance.currentBeatTime;
			if (bt >= videoBeat && bt < videoEndBeat) startVideo(game);
			return;
		}

		if (videoFinished) return;

		if (videoPending)
		{
			if (vid == null)
			{
				onVideoEnd(game);
				return;
			}

			if (videoReady)
			{
				showVideo(game);
				return;
			}

			videoWait += elapsed;
			if (videoWait >= videoMaxWait)
			{
				trace("[DadBattleAnimania] el video no se pudo mostrar a tiempo: se sigue sin video");
				onVideoEnd(game);
			}
		}
		else if (videoPlaying)
		{
			videoPlayTime += elapsed;
			if (vid == null)
			{
				onVideoEnd(game);
				return;
			}

			var stalled = false;
			if (videoPlayTime > 1.0 && FlxG.sound.music != null && FlxG.sound.music.playing)
			{
				try
				{
					stalled = !vid.bitmap.isPlaying;
				}
				catch (e:Dynamic)
				{
					stalled = false;
				}
			}

			if (stalled)
			{
				videoStallTime += elapsed;
				if (videoStallTime >= videoStallMax)
				{
					trace("[DadBattleAnimania] el video se quedo sin reproducir: se cierra");
					onVideoEnd(game);
				}
			}
			else
			{
				videoStallTime = 0.0;
			}
		}
	}

	function onVideoEnd(game)
	{
		if (videoFinished) return;
		videoFinished = true;

		var v = vid;
		vid = null;
		videoToken += 1;
		videoPending = false;
		videoPlaying = false;
		videoReady = false;

		if (v != null) destroyVideoLater(v, game);

		game.camGame.flash();
		setHudHidden(game, false);
		game.disableKeys = false;

		var bf = game.currentStage.getBoyfriend();
		if (bf != null) bf.idleSuffix = "";

		var dad = game.currentStage.getDad();
		if (dad != null) dad.idleSuffix = "-alt";

		var overlay = game.currentStage.getNamedProp("fgRedOverlay");
		if (Save.instance.modOptions["shaders"] && overlay != null)
		{
			FlxTween.cancelTweensOf(overlay);
			FlxTween.tween(overlay, {alpha: 0}, 8, {startDelay: 1, ease: FlxEase.sineInOut});
		}

		startGodRaysSequence(game);

		mlVideoEnd();
	}

	function resetRunState(game)
	{
		if (game == null || game.currentStage == null) return;

		var stage = game.currentStage;

		setHudHidden(game, false);
		game.disableKeys = false;

		videoStarted = false;
		videoFinished = false;
		videoWait = 0.0;
		videoPlayTime = 0.0;
		videoStallTime = 0.0;
		setupVideo(game);

		var bf = stage.getBoyfriend();
		if (bf != null) bf.idleSuffix = "-angry";
		var dad = stage.getDad();
		if (dad != null) dad.idleSuffix = dadIdleBase;

		var overlay = stage.getNamedProp("fgRedOverlay");
		if (overlay != null)
		{
			FlxTween.cancelTweensOf(overlay);
			if (overlayBaseAlpha != null) overlay.alpha = overlayBaseAlpha;
		}

		if (!Save.instance.modOptions['lowQuality'])
		{
			if (godRaysSpr != null)
			{
				FlxTween.cancelTweensOf(godRaysSpr);
				godRaysSpr.alpha = 0;
			}
			var holyGrad = stage.getNamedProp("holygrad");
			if (holyGrad != null)
			{
				FlxTween.cancelTweensOf(holyGrad);
				holyGrad.alpha = 0;
			}
		}
		if (Save.instance.modOptions['shaders'])
		{
			if (chromChangeTween != null)
			{
				chromChangeTween.cancel();
				chromChangeTween = null;
			}
			if (chromShader != null)
			{
				chromShader.setFloat("strength", .1);
				game.camGame.filters = [new ShaderFilter(chromShader)];
			}

			dangerPulse = -300.0;
		}
		mlInit(game);
	}

	function startGodRaysSequence(game)
	{
		if (!Save.instance.modOptions["shaders"] || godRaysSpr == null) return;

		var holyGrad = game.currentStage.getNamedProp("holygrad");

		FlxTween.cancelTweensOf(godRaysSpr);
		FlxTween.tween(godRaysSpr, {alpha: 0.1}, 3, {startDelay: 2, ease: FlxEase.sineInOut});
		FlxTween.tween(godRaysSpr, {alpha: 0}, 6, {startDelay: 20.75, ease: FlxEase.sineInOut});

		if (holyGrad != null)
		{
			FlxTween.cancelTweensOf(holyGrad);
			var holyAlpha = 0.6;
			#if mobile
			holyAlpha = 0.1;
			#end
			FlxTween.tween(holyGrad, {alpha: holyAlpha}, 3, {startDelay: 2, ease: FlxEase.sineInOut});
			FlxTween.tween(holyGrad, {alpha: 0}, 6, {startDelay: 20.75, ease: FlxEase.sineInOut});
		}
	}

	function godRaysEffect(alpha, time, easeStr)
	{
		if (godRaysSpr == null) return;

		FlxTween.cancelTweensOf(godRaysSpr);

		var easeFunction = Reflect.field(FlxEase, easeStr);
		if (easeFunction == null) easeFunction = FlxEase.sineInOut;

		if (time <= 0)
		{
			godRaysSpr.alpha = alpha;
		}
		else
		{
			FlxTween.tween(godRaysSpr, {alpha: alpha}, time, {ease: easeFunction});
		}
	}

	function onCreate(event)
	{
		var game = PlayState.instance;
		if (game == null || game.currentStage == null) return;

		var realBf = game.currentStage.getBoyfriend();
		var realDad = game.currentStage.getDad();

		if (Save.instance.modOptions["shaders"])
		{
		if (realBf != null)
		{
			bfRef = CharacterDataParser.fetchCharacter(realBf.characterId);
			if (bfRef != null)
			{
				game.currentStage.addCharacter(bfRef, CharacterType.OTHER);
				applyStagePosition(bfRef, game.currentStage._data.characters.bf);

				bfRef.zIndex = realBf.zIndex - 1;
				bfRef.flipX = false;
				bfRef.flipY = true;
				bfRef.useRenderTexture = true;
				bfRef.scale.y = 0.75;
				bfRef.x -= 25;
				bfRef.y += bfRef.height / 1.27;
				bfRef.skew.x = -5;

				reflectionShaderBf = new FlxRuntimeShader(refShader);
				reflectionShaderBf.setFloat("bend", 0.05);
				reflectionShaderBf.setFloat("rightBend", 0.0);
				bfRef.shader = reflectionShaderBf;
			}
		}

		if (realDad != null)
		{
			dadRef = CharacterDataParser.fetchCharacter(realDad.characterId);
			if (dadRef != null)
			{
				game.currentStage.addCharacter(dadRef, CharacterType.OTHER);
				applyStagePosition(dadRef, game.currentStage._data.characters.dad);

				dadRef.zIndex = realDad.zIndex - 1;
				game.currentStage.refresh();

				dadRef.x -= 45;
				dadRef.flipX = false;
				dadRef.flipY = true;
				dadRef.useRenderTexture = true;
				dadRef.skew.y = -11;
				dadRef.scale.y = 0.75;
				dadRef.y += dadRef.height / 1.3;
				dadRef.skew.x = -7;

				reflectionShaderDad = new FlxRuntimeShader(refShader);
				reflectionShaderDad.setFloat("bend", 0.1);
				reflectionShaderDad.setFloat("rightBend", 0.11);
				dadRef.shader = reflectionShaderDad;
			}
		}
		}

		if (Save.instance.modOptions["shaders"])
		{
			chromShader = new FlxRuntimeShader(Assets.getText(Paths.frag('chromaticAbberation')));
			chromShader.setFloat("strength", .1);
			game.camGame.filters = [new ShaderFilter(chromShader)];
		}

		setupGodRays(game);

		var ov = game.currentStage.getNamedProp("fgRedOverlay");
		overlayBaseAlpha = (ov != null) ? ov.alpha : null;
		dadIdleBase = (realDad != null) ? realDad.idleSuffix : "";

		videoStarted = false;
		videoFinished = false;
		hiddenHud = [];
		dangerPulse = -300.0;
		setupVideo(game);

		if (realBf != null) realBf.idleSuffix = "-angry";

		mlInit(game);
	}

	function onCountdownStart(event)
	{
		var game = PlayState.instance;
		mlPlace(game);

		// No se salta en charting mode (startTimestamp) ni si el carry de story mode esta mezclando vida/camara.
		var carry = ModuleHandler.getModule('storyCarryoverModule');
		if (game == null || game.isChartingMode || (carry != null && carry.blendPending)) return;

		// Sin countdown la cancion arranca en el siguiente frame y ya no queda tiempo "muerto" para que el GC corra:
		// se hace una recoleccion mayor justo ANTES de arrancar (la musica todavia no suena), no a mitad de la cancion.
		FlxTimer.wait(0, function() {
			try
			{
				MemoryUtil.collect(true);
			}
			catch (e:Dynamic) {}
			Countdown.skipCountdown();
		});
	}

	function onSongRetry(event)
	{
		var game = PlayState.instance;
		if (game == null) return;

		resetRunState(game);
	}

	function onNoteHit(event)
	{
		if (!useModchart || !mlPlaced) return;

		var game = PlayState.instance;
		if (game == null || game.currentStage == null) return;

		if (game.opponentStrumline.notes.members.indexOf(event.note) == -1) return;

		mlDrainHealth(game, 0.0125);
		mlHit(event.note.noteData.getDirection() % 4);
	}

	function onUpdate(event)
	{
		var game = PlayState.instance;
		if (game == null || game.currentStage == null) return;

		shaderTime += event.elapsed;

		updateVideo(game, event.elapsed);

		if (bfRef != null || dadRef != null)
		{
			reflectionTime += event.elapsed;

			if (dadRef != null)
			{
				if (reflectionShaderDad != null) reflectionShaderDad.setFloat("iTime", reflectionTime);
				mirrorAnimation(dadRef, game.currentStage.getDad());
			}

			if (bfRef != null)
			{
				if (reflectionShaderBf != null) reflectionShaderBf.setFloat("iTime", reflectionTime);
				mirrorAnimation(bfRef, game.currentStage.getBoyfriend());
			}
		}

		if (chromShader != null)
		{
			if (fgOverlayRef == null) fgOverlayRef = game.currentStage.getNamedProp("fgRedOverlay");
			var overlay = fgOverlayRef;
			if (overlay != null && overlay.alpha != lastChromOverlayAlpha)
			{
				lastChromOverlayAlpha = overlay.alpha;
				chromShader.setFloat("strength", overlay.alpha / 8);
			}
		}

		updateDangerBar(game, event.elapsed);

		// Los rayos de luz solo se dibujan con alpha > 0: mientras estan invisibles no se gasta nada en ellos.
		if (godRaysSpr != null && godRaysSpr.alpha > 0)
		{
			if (godRaysShader != null) godRaysShader.setFloat("iTime", shaderTime);
			applyGodRaysZoomFactor(game);
		}

		mlUpdate(game, event.elapsed);
	}

	function onResume(event)
	{
		var game = PlayState.instance;
		if (game == null) return;

		if (vid != null && (videoPlaying || videoPending)) vid.resume();

		if (chromShader == null) return;
		var cf = game.camGame.filters;
		if (cf == null || cf.length == 0) game.camGame.filters = [new ShaderFilter(chromShader)];
	}

	function onSongEvent(event)
	{
		if (event == null || event.eventData == null) return;

		if (event.eventData.eventKind == "Blank")
		{
			var value1 = event.eventData.getString("value1");
			if (value1 == null) return;

			var kind = value1.toLowerCase();

			if (kind == "chroma")
			{
				chromaEffect(event.eventData.getFloat("value2"), event.eventData.getFloat("value3"), event.eventData.getString("value4"));
			}
			else if (kind == "godrays")
			{
				godRaysEffect(event.eventData.getFloat("value2"), event.eventData.getFloat("value3"), event.eventData.getString("value4"));
			}
		}
	}

	function onBeatHit(event)
	{
		var game = PlayState.instance;
		if (game == null || game.currentStage == null) return;

		mlBeat(event.beat);

		if (event.beat >= videoBeat && event.beat < videoEndBeat)
			startVideo(game);

		if (event.beat > videoBeat - 1 && event.beat < 250 && game.vocals != null)
			game.vocals.playerVolume = 1;
	}

	function onPause(event)
	{
		if (vid != null && (videoPlaying || videoPending)) vid.pause();
	}

	function onGameOver(event)
	{
		var game = PlayState.instance;
		if (game == null) return;

		if (Save.instance.modOptions["shaders"])
			game.camGame.filters = [];

		if (vid != null)
		{
			try
			{
				vid.stop();
			}
			catch (e:Dynamic) {}
			vid.visible = false;
		}
		videoPending = false;
		videoPlaying = false;
		setHudHidden(game, false);
		game.disableKeys = false;
	}

	function onDestroy(event)
	{
		var game = PlayState.instance;

		if (game != null)
		{
			if (mlOppIncomingFn != null && game.opponentStrumline != null) game.opponentStrumline.onNoteIncoming.remove(mlOppIncomingFn);
			if (mlPlrIncomingFn != null && game.playerStrumline != null) game.playerStrumline.onNoteIncoming.remove(mlPlrIncomingFn);
		}
		if (mlPostFn != null)
		{
			FlxG.signals.postUpdate.remove(mlPostFn);
			mlPostFn = null;
		}
		mlOppIncomingFn = null;
		mlPlrIncomingFn = null;
		mlPlaced = false;
		mlBaseIntroKilled = false;
		mlTw = new StringMap();
		mlOpp = null;
		mlPlr = null;
		mlPlrRecs = [];
		mlOppRecs = [];

		if (dangerBar != null)
		{
			if (game != null) game.remove(dangerBar, true);
			dangerBar.destroy();
			dangerBar = null;
		}

		destroyVideo(game);
		videoStarted = false;
		videoFinished = false;
		hiddenHud = [];

		bfRef = null;
		dadRef = null;
		reflectionShaderBf = null;
		reflectionShaderDad = null;
		reflectionTime = 0;
		shaderTime = 0.0;
		chromShader = null;
		chromChangeTween = null;
		dangerPulse = -300.0;

		dangerShader = null;
		dangerSource = null;
		dangerLastHv = -1.0;
		dangerBarTried = false;
		godRaysShader = null;
		godRaysSpr = null;
		fgOverlayRef = null;
		lastChromOverlayAlpha = -1.0;
	}

	function chromaEffect(strength, time, easeStr)
	{
		if (chromShader == null) return;

		if (chromChangeTween != null)
			chromChangeTween.cancel();

		var easeFunction = Reflect.field(FlxEase, easeStr);
		if (easeFunction == null) easeFunction = FlxEase.smootherStepOut;

		lastChromOverlayAlpha = -1.0;
		if (time <= 0)
		{
			chromShader.setFloat("strength", strength);
		}
		else
		{
			chromChangeTween = FlxTween.num(chromShader.getFloat("strength"), strength, time, {ease: easeFunction}, function(stng) {
				chromShader.setFloat("strength", stng);
			});
		}
	}
}
