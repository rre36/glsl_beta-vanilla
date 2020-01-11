#include "/settings.glsl"
#include "/lib/math.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

varying float ao;

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 scenePosition;
varying vec3 skylight_color;

varying vec4 glcolor;

#include "/lib/fog.glsl"

#ifdef g_entity
uniform vec4 entityColor;
#endif

void main() {
	vec4 color = texture2D(texture, texcoord, -1) * glcolor;

    #ifdef g_entity
    color.rgb   = mix(color.rgb, entityColor.rgb, entityColor.a);
    #endif

		color.rgb *= ao * sqrt(ao);

	vec2 lmc 	= vec2(lmcoord.x, 0.0);

	vec3 light_map = texture2D(lightmap, lmc).rgb;
	
	vec3 skylight 	= pow2(smoothstep(0.0, 1.0, lmcoord.y)) * skylight_color;

		light_map = max(light_map, skylight);

	color.rgb *= light_map;

    color.rgb   = fancy_fog(color.rgb, length(scenePosition));

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}