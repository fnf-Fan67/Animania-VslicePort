#pragma header

uniform vec4 blendColor;
uniform int iBlendMode;
uniform float hue;
uniform float saturation;
uniform float brightness;
uniform float contrast;

const int BLMODE_ADD = 0;
const int BLMODE_DARKEN = 2;
const int BLMODE_DIFFERENCE = 3;
const int BLMODE_ERASE = 4;
const int BLMODE_HARDLIGHT = 5;
const int BLMODE_INVERT = 6;
const int BLMODE_LIGHTEN = 8;
const int BLMODE_MULTIPLY = 9;
const int BLMODE_NORMAL = 10;
const int BLMODE_OVERLAY = 11;
const int BLMODE_SCREEN = 12;
const int BLMODE_SHADER = 13;
const int BLMODE_SUBTRACT = 14;

const vec3 CONST_VEC3_0 = vec3(0.0);
const vec3 CONST_VEC3_1 = vec3(1.0);
const vec4 CONST_VEC4_1 = vec4(1.0);

vec4 blendNormalAlphas(vec4 bg, vec4 src) {
	return mix(bg, src, src.a);
}

vec3 blendSubtract(vec3 base, vec3 blend) {
	return max(base.rgb+blend.rgb-CONST_VEC3_1, CONST_VEC3_0);
}
vec3 blendScreen(vec3 base, vec3 blend) {
	return CONST_VEC3_1 - (CONST_VEC3_1 - base) * (CONST_VEC3_1 - blend);
}

float overlay(float s, float d) {
	return d < 0.5 ? 2.0 * s * d : 1.0 - 2.0 * (1.0 - s) * (1.0 - d);
}

vec4 blendThing(vec4 src, vec4 dst, vec3 blendResult) {
	return vec4(
		(
			src.rgb * (1.0 - dst.a) +
			blendResult * dst.a
		),
		src.a
	);
}

vec4 blendOverlay(vec4 base, vec4 blend) {
	return blendThing(base, blend, vec3(
			overlay(base.r, blend.r),
			overlay(base.g, blend.g),
			overlay(base.b, blend.b)
		));
}

vec4 blendDarken(vec4 base, vec4 blend) {
	return blendThing(base, blend, min(base.rgb, blend.rgb));
}

vec4 blendLighten(vec4 base, vec4 blend) {
	return blendThing(base, blend, max(base.rgb, blend.rgb));
}

vec4 blendHardLight(vec4 base, vec4 blend) {
	return blendThing(base, blend, vec3(
			overlay(blend.r, base.r),
			overlay(blend.g, base.g),
			overlay(blend.b, base.b)
		));
}


const vec3 grayscaleValues = vec3(0.3098039215686275, 0.607843137254902, 0.0823529411764706);
const float e = 2.718281828459045;
const mat3 hueM1 = mat3(0.213, 0.213, 0.213, 0.715, 0.715, 0.715, 0.072, 0.072, 0.072);
const mat3 hueM2 = mat3(0.787, -0.213, -0.213, -0.715, 0.285, -0.715, -0.072, -0.072, 0.928);
const mat3 hueM3 = mat3(-0.213, 0.143, -0.787, -0.715, 0.140, 0.715, 0.928, -0.283, 0.072);

vec3 applyHueRotate(vec3 aColor, float aHue) {
	float angle = radians(aHue);

	mat3 m = hueM1 + cos(angle) * hueM2 + sin(angle) * hueM3;

	return m * aColor;
}

vec3 applySaturation(vec3 aColor, float value) {
	if (value > 0.0)
	{
		value = value * 3.0;
	}
	value = (1.0 + (value / 100.0));
	vec3 grayscale = vec3(dot(aColor, grayscaleValues));
	return clamp(mix(grayscale, aColor, value), 0.0, 1.0);
}

vec3 applyContrast(vec3 aColor, float value) {
	value = (1.0 + (value / 100.0));
	if (value > 1.0) {
		value = (((0.00852259 * pow(e, 4.76454 * (value - 1.0))) * 1.01) - 0.0086078159) * 10.0; //Just roll with it...
		value += 1.0;
	}
	return clamp((aColor - 0.25) * value + 0.25, 0.0, 1.0);
}

vec3 applyHSBCEffect(vec3 color) {

	//Brightness
	color = color + brightness / 255.0;

	//Hue
	if (hue != 0.0)
		color = applyHueRotate(color, hue);

	//Contrast
	if (contrast != 0.0)
		color = applyContrast(color, contrast);

	//Saturation
	if (saturation != 0.0)
		color = applySaturation(color, saturation);

	return color;
}

vec4 applyHSBCEffect(vec4 textureColor) {

	// Un-multiply alpha if the texture is premultiplied
	// Lime premultiplies alphas before sending it to render, so we want to accomodate header. This fixes some antialiased edges appearing darker
	vec3 unpremultipliedColor = textureColor.a != 0.0 ? textureColor.rgb / textureColor.a : textureColor.rgb;

	// Apply effects to the unpremultiplied color
	vec3 outColor = applyHSBCEffect(unpremultipliedColor);

	return vec4(outColor * textureColor.a, textureColor.a);
}

vec4 blend(vec4 bg, vec4 src, int blendMode) {
	/*
	if (blendMode == BLMODE_ADD) {
		return min(bg + src, CONST_VEC4_1);
	} else if (blendMode == BLMODE_DARKEN) {
		return blendDarken(bg, src);
	} else if (blendMode == BLMODE_DIFFERENCE) {
		bg.rgb = abs(bg.rgb-src.rgb);
		return bg;
	} else if (blendMode == BLMODE_ERASE) {
		bg.rgb = bg.rgb - src.rgb;
		return bg;
	} else if (blendMode == BLMODE_HARDLIGHT) {
		return blendHardLight(bg, src);
	} else if (blendMode == BLMODE_INVERT) {
		return blendThing(bg, src, (CONST_VEC3_1 - bg.rgb));
	} else if (blendMode == BLMODE_LIGHTEN) {
		return blendLighten(bg, src);
	} else if (blendMode == BLMODE_MULTIPLY) {
		return vec4(bg.rgb * mix(CONST_VEC3_1, src.rgb, src.a), bg.a);
	} else if (blendMode == BLMODE_OVERLAY) {
		return blendOverlay(bg, src);
	} else if (blendMode == BLMODE_SCREEN) {
		return vec4(blendScreen(bg.rgb, src.rgb), blendNormalAlphas(bg, src));
	} else if (blendMode == BLMODE_SUBTRACT) {
		return vec4(blendSubtract(bg.rgb, src.rgb), blendNormalAlphas(bg, src));
	}
	return bg * (CONST_VEC4_1 - src.aaaa) + src;
	*/
		return vec4(bg.rgb * mix(CONST_VEC3_1, src.rgb, src.a), bg.a);
}

void main() {
	// V-Slice: applyFlixelEffects() no existe. flixel_texture2D ya aplica
	// premultiply, color transform y alpha.
	vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
	color = applyHSBCEffect(color);

	gl_FragColor = blend(color, blendColor, iBlendMode);
}
