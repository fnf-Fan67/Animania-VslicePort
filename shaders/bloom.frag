#pragma header
uniform vec2 blurSize;
uniform float quality;
const vec3 multColor1 = vec3(25.);
const vec4 multColor2 = vec4(250., 250., 250., 50.) / vec4(350.);
void main()
{
	gl_FragColor = texture2D(bitmap, openfl_TextureCoordv.xy);
	for(float x=-1.; x<1.; x+=1./quality)
	{
		for(float y=-1.;y<1.;y+=1./quality)
		{
			vec4 color = texture2D(bitmap, openfl_TextureCoordv.xy + vec2(x, y) / openfl_TextureSize.xy * blurSize);
			color.rgb = pow(color.rgb, multColor1);
			gl_FragColor+=(color.r + color.g + color.b) / 3. / quality / quality * multColor2 * clamp(1.0-pow(x*x+y*y, 1./5.), 0., 1.) * .5;
		}
	}
}