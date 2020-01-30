uniform sampler2D gcolor;

varying vec2 texcoord;
varying vec4 tint;

#ifdef g_enchantment
varying vec2 lmcoord;
uniform sampler2D lightmap;
#endif

void main() {
	vec4 color = texture2D(gcolor, texcoord) * tint;

    #ifdef g_enchantment
        color.rgb  *= texture2D(lightmap, lmcoord).rgb;
    #endif

        //gl_FragDepth = gl_FragCoord.z - 1e-4;

    /* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}