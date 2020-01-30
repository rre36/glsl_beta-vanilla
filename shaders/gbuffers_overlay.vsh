#define temporal_aa

varying vec2 texcoord;
varying vec4 tint;

#ifdef g_enchantment
varying vec2 lmcoord;
#endif

uniform vec2 taaOffset;

#define viewMAD(m, v) (mat3(m) * (v) + (m)[3].xyz)
#define diag3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define diag4(mat) vec4(diag3(mat), (mat)[2].w)
#define projMAD(m, v) (diag3(m) * (v) + (m)[3].xyz)

void main() {
    vec4 pos    = gl_Vertex;
        pos     = viewMAD(gl_ModelViewMatrix, pos.xyz).xyzz;
        pos     = pos.xyzz * diag4(gl_ProjectionMatrix) + vec4(0.0, 0.0, gl_ProjectionMatrix[3].z, 0.0);

    #ifdef temporal_aa
        pos.xy += taaOffset*pos.w;
    #endif
    
    gl_Position = pos;

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	tint    = gl_Color;

    #ifdef g_enchantment
        lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    #endif
}