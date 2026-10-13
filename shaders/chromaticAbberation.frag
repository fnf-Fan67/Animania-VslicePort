#pragma header

#define iChannel0 bitmap
#define texture texture2D

uniform float strength;

vec2 PincushionDistortion(in vec2 uv, in vec2 screenMult, float uvD, float strength)
{
	return 0.5 + screenMult * (1.0 - strength * uvD);
}

vec3 ChromaticAbberation(in sampler2D tex, in vec2 uv)
{
	vec2 st = uv - 0.5;
	float uvA = atan(st.x, st.y);
	float uvD = dot(st, st);
	vec2 screenMult = vec2(sin(uvA), cos(uvA)) * sqrt(uvD);
	float rChannel = texture(tex, PincushionDistortion(uv, screenMult, uvD, strength * 0.5)).r;
	float gChannel = texture(tex, PincushionDistortion(uv, screenMult, uvD, strength * 0.25)).g;
	float bChannel = texture(tex, PincushionDistortion(uv, screenMult, uvD, strength * 0.125)).b;
	return vec3(rChannel, gChannel, bChannel);
}

void main() {
	vec3 col = ChromaticAbberation(iChannel0, openfl_TextureCoordv);

	gl_FragColor = vec4(col, texture(iChannel0, openfl_TextureCoordv).a);
}
