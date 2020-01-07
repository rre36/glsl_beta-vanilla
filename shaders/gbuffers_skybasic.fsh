#version 120

uniform float viewHeight;
uniform float viewWidth;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform vec3 sunvec;

varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

varying vec4 tint;

#define pow2(x) (x*x)

#define sstep(x, low, high) smoothstep(low, high, x)

float fogify(float x, float w) {
	float y = clamp(exp(-x * w) * 1.75 - 0.4, 0.0, 1.0);
	return pow2(y);
}

vec3 calcSkyColor(vec3 pos) {
	float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
	return mix(skyColor, fogColor, fogify(max(upDot, 0.0), 3.0));
}
vec3 calcSkyColor(vec3 pos, vec3 color) {
	float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
	return mix(color, fogColor, fogify(max(upDot, 0.0), 3.0));
}

void main() {
	vec3 color = skyColor;

	
	if (starData.a > 0.5) {
		color = starData.rgb * sstep(-sunvec.y, -0.04, 0.04);
	} else {
		vec4 pos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0, 1.0);
		pos = gbufferProjectionInverse * pos;
		color = calcSkyColor(normalize(pos.xyz), color);
		if (tint.a < 0.99 && starData.a < 0.5) color = mix(color, tint.rgb, tint.a);
	}



/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}