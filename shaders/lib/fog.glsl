uniform float far;

uniform vec3 fogColor;

vec3 fancy_fog(vec3 color, float distance){
	float dist 	= lin_step(distance/far, fog_start, 1.0);
	float alpha = 1.0-exp(-dist*pi);

    #ifdef fog_terrain_fade
        alpha   = mix(alpha, 1.0, pow2(lin_step(distance/far, 0.9, 1.0)));
    #endif
        
	color 	= mix(color, fogColor, saturate(pow2(alpha)));

	return color;
}
