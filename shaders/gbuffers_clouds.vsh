#version 120

#define temporal_aa

#include "/lib/math.glsl"

varying vec2 texcoord;

varying vec3 scenePosition;

varying vec4 glcolor;

uniform vec2 taaOffset;

uniform mat4 gbufferModelView, gbufferModelViewInverse;

void main() {
	vec4 position 	= gl_Vertex;	
		position 	= viewMAD(gl_ModelViewMatrix, position.xyz).xyzz;
    	//vpos 		= position.xyz;
    	position.xyz = viewMAD(gbufferModelViewInverse, position.xyz);
		scenePosition = position.xyz;
		position.xyz = viewMAD(gbufferModelView, position.xyz);
		position     = position.xyzz * diag4(gl_ProjectionMatrix) + vec4(0.0, 0.0, gl_ProjectionMatrix[3].z, 0.0);
    #ifdef temporal_aa
        position.xy += taaOffset*position.w;
    #endif
	gl_Position = position;


	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
}