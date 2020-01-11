#define temporal_aa

varying float ao;

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 scenePosition;

varying vec4 glcolor;

attribute vec3 mc_Entity;

uniform vec2 taaOffset;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelViewInverse;

varying vec3 skylight_color;

#define pow2(x) (x*x)

#define viewMAD(m, v) (mat3(m) * (v) + (m)[3].xyz)
#define diag3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define diag4(mat) vec4(diag3(mat), (mat)[2].w)
#define projMAD(m, v) (diag3(m) * (v) + (m)[3].xyz)
#define saturate(x) clamp(x, 0.0, 1.0)

uniform int worldTime;

float lin_step(float x, float low, float high) {
    float t = saturate((x-low)/(high-low));
    return t;
}

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;

    #ifndef g_translucent
        if (!(mc_Entity.x == 18.0 || mc_Entity.x == 161.0)) ao = gl_Color.a;
	    else ao = 1.0;
    #else
        ao = 1.0;
    #endif

    glcolor.a = 1.0;

    vec4 pos    = gl_Vertex;
        pos     = viewMAD(gl_ModelViewMatrix, pos.xyz).xyzz;

        scenePosition = viewMAD(gbufferModelViewInverse, pos.xyz);

    vec3 worldpos   = scenePosition + cameraPosition;

    vec3 chunkpos   = floor((worldpos - 0.1) / 16.0) * 16.0 - cameraPosition;

    const vec3 skylight_basecol = vec3(1.0);
    const vec3 skylight_night = vec3(0.58, 0.58, 1.0) * 0.3;

    float sunrise_mult = 1000.0 / 1500.0;

    float chunk_dist    = length(chunkpos.xz);
        chunk_dist      = chunk_dist < 32.0 ? sqrt(chunk_dist / 32.0) * 32.0 : chunk_dist;
        chunk_dist      = chunk_dist < 64.0 ? sqrt(chunk_dist / 64.0) * 64.0 : chunk_dist;

    float chunk_offset  = min(chunk_dist / 2.0, 400.0);

    float skylight_fade = lin_step(float(worldTime) - chunk_offset, 11500.0, 13000.0);
        skylight_fade  -= lin_step(float(worldTime) - chunk_offset, 23000.0, 24000.0) * sunrise_mult;
        skylight_fade  += (1.0 - lin_step(float(worldTime) - chunk_offset, 0.0, 500.0)) * (1.0 - sunrise_mult);
        skylight_fade   = floor((skylight_fade) * 14.0) / 14.0;

    skylight_color  = mix(skylight_basecol, skylight_night, skylight_fade);

    pos     = pos.xyzz * diag4(gl_ProjectionMatrix) + vec4(0.0, 0.0, gl_ProjectionMatrix[3].z, 0.0);

    #ifdef temporal_aa
    pos.xy += taaOffset*pos.w;
    #endif
    
    gl_Position = pos;
}