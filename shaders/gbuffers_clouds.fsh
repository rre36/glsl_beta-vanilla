#version 120

#include "/settings.glsl"
#include "/lib/math.glsl"

uniform sampler2D texture;

varying vec2 texcoord;

varying vec3 scenePosition;

varying vec4 glcolor;

uniform float far;

uniform vec3 fogColor;

vec3 fancy_fog(vec3 color, float distance){
	float dist 	= distance/far;
		dist 	= lin_step(dist, fog_start, 1.0);
	float alpha = 1.0-exp2(-dist*pi);

	color 	= mix(color, fogColor, saturate(alpha));

	return color;
}

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;

        color.rgb = fancy_fog(color.rgb, length(scenePosition));

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}