#version 120

#include "/lib/math.glsl"
#extension GL_ARB_shader_texture_lod : enable

/*
const bool colortex1Clear   = false;

const int colortex0Format   = RGB8;
const int colortex1Format   = RGB8;
*/

#define temporal_aa

varying vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex1;

uniform sampler2D depthtex1;

uniform float frameTime;
uniform float viewHeight;
uniform float viewWidth;

uniform vec2 pixelSize, viewSize;
uniform vec2 taaOffset;

uniform vec3 cameraPosition, previousCameraPosition;

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView, gbufferPreviousProjection;

/*
temporal anti aliasing based on
- bsl shaders
- chocapic13 shaders
- unreal 4
*/

vec2 taa_reproject(vec2 coord, float depth) {
    float hand  = float(depth > 0.56);
    vec4 pos    = vec4(coord, depth, 1.0)*2.0-1.0;
        pos     = gbufferProjectionInverse*pos;
        pos    /= pos.w;
        pos     = gbufferModelViewInverse*pos;

    vec4 ppos   = pos + vec4(cameraPosition-previousCameraPosition, 0.0)*hand;
        ppos    = gbufferPreviousModelView*ppos;
        ppos    = gbufferPreviousProjection*ppos;

    return (ppos.xy/ppos.w)*0.5+0.5;
}
vec2 taa_reproject(vec3 coord, float depth) {
    float hand  = float(depth > 0.56);
    vec3 pos    = coord*2.0-1.0;
        pos     = projMAD(gbufferProjectionInverse, pos);
        pos     = viewMAD(gbufferModelViewInverse, pos);

    vec3 ppos   = pos + (cameraPosition-previousCameraPosition)*hand;
        ppos    = viewMAD(gbufferPreviousModelView, ppos);
        ppos    = projMAD(gbufferPreviousProjection, ppos);

    return ppos.xy*0.5+0.5;
}

//3x3 screenpos sampling based on chocapic13's taa
vec3 screenpos3x3(sampler2D depth) {
    vec2 dx     = vec2(pixelSize.x, 0.0);
    vec2 dy     = vec2(0.0, pixelSize.y);

    vec3 dtl    = vec3(texcoord, 0.0)  + vec3(-pixelSize, texture2DLod(depth, texcoord - dx - dy, 0).x);
    vec3 dtc    = vec3(texcoord, 0.0)  + vec3(0.0, -pixelSize.y, texture2DLod(depth, texcoord - dy, 0).x);
    vec3 dtr    = vec3(texcoord, 0.0)  + vec3(pixelSize.x, -pixelSize.y, texture2DLod(depth, texcoord - dy + dx, 0).x);

    vec3 dml    = vec3(texcoord, 0.0)  + vec3(-pixelSize.x, 0.0, texture2DLod(depth, texcoord - dx, 0).x);
    vec3 dmc    = vec3(texcoord, 0.0)  + vec3(0.0, 0.0, texture2DLod(depth, texcoord, 0).x);
    vec3 dmr    = vec3(texcoord, 0.0)  + vec3(0.0, pixelSize.y,  texture2DLod(depth, texcoord + dx, 0).x);

    vec3 dbl    = vec3(texcoord, 0.0)  + vec3(-pixelSize.x, pixelSize.y, texture2DLod(depth, texcoord + dy - dx, 0).x);
    vec3 dbc    = vec3(texcoord, 0.0)  + vec3(0.0, pixelSize.y, texture2DLod(depth, texcoord + dy, 0).x);
    vec3 dbr    = vec3(texcoord, 0.0)  + vec3(pixelSize.x, pixelSize.y, texture2DLod(depth, texcoord + dy + dx, 0).x);

    vec3 dmin   = dmc;

    dmin    = dmin.z > dtc.z ? dtc : dmin;
    dmin    = dmin.z > dtr.z ? dtr : dmin;

    dmin    = dmin.z > dml.z ? dml : dmin;
    dmin    = dmin.z > dtl.z ? dtl : dmin;
    dmin    = dmin.z > dmr.z ? dmr : dmin;

    dmin    = dmin.z > dbl.z ? dbl : dmin;
    dmin    = dmin.z > dbc.z ? dbc : dmin;
    dmin    = dmin.z > dbr.z ? dbr : dmin;

    return dmin;
}

vec4 texture_catmullrom(sampler2D tex, vec2 uv) {
    vec2 res    = viewSize;

    vec2 coord  = uv*res;
    vec2 coord1 = floor(coord - 0.5) + 0.5;

    vec2 f      = coord-coord1;

    vec2 w0     = f*(-0.5 + f*(1.0-0.5*f));
    vec2 w1     = 1.0 + pow2(f)*(-2.5+1.5*f);
    vec2 w2     = f*(0.5 + f*(2.0-1.5*f));
    vec2 w3     = pow2(f)*(-0.5+0.5*f);

    vec2 w12    = w1+w2;
    vec2 delta12 = w2/w12;

    vec2 uv0    = coord1 - vec2(1.0);
    vec2 uv3    = coord1 + vec2(1.0);
    vec2 uv12   = coord1 + delta12;

        uv0    *= pixelSize;
        uv3    *= pixelSize;
        uv12   *= pixelSize;

    vec4 col    = vec4(0.0);
        col    += texture2DLod(tex, vec2(uv0.x, uv0.y), 0)*w0.x*w0.y;
        col    += texture2DLod(tex, vec2(uv12.x, uv0.y), 0)*w12.x*w0.y;
        col    += texture2DLod(tex, vec2(uv3.x, uv0.y), 0)*w3.x*w0.y;

        col    += texture2DLod(tex, vec2(uv0.x, uv12.y), 0)*w0.x*w12.y;
        col    += texture2DLod(tex, vec2(uv12.x, uv12.y), 0)*w12.x*w12.y;
        col    += texture2DLod(tex, vec2(uv3.x, uv12.y), 0)*w3.x*w12.y;

        col    += texture2DLod(tex, vec2(uv0.x, uv3.y), 0)*w0.x*w3.y;
        col    += texture2DLod(tex, vec2(uv12.x, uv3.y), 0)*w12.x*w3.y;
        col    += texture2DLod(tex, vec2(uv3.x, uv3.y), 0)*w3.x*w3.y;

    return clamp(col, 0.0, 65535.0);
}

#define taa_blend 1.0
#define taa_mreject 4.0
#define taa_antighost 4.0
#define taa_antiflicker 0.6

const vec3 lumacoeff_rec709 = vec3(0.2125, 0.7154, 0.0721);

float get_luma(vec3 x) {
    return dot(x, lumacoeff_rec709);
}

vec3 get_taa(vec3 scenecol, float scenedepth) {
    vec3 screen3x3  = screenpos3x3(depthtex1);

    vec2 rcoord     = taa_reproject(texcoord, scenedepth);

    vec2 px_dist    = 0.5-abs(fract((rcoord-texcoord)*viewSize)-0.5);

    //motion rejection
    float bweight   = dot(px_dist, px_dist);
        bweight     = pow(bweight, 1.5)*taa_mreject;

    if (clamp(rcoord, 0.0, 1.0) != rcoord) return scenecol;

    vec3 coltl   = texture2DLod(colortex0,texcoord+vec2(-pixelSize.x, -pixelSize.y), 0).rgb;
	vec3 coltm   = texture2DLod(colortex0,texcoord+vec2( 0.0,         -pixelSize.y), 0).rgb;
	vec3 coltr   = texture2DLod(colortex0,texcoord+vec2( pixelSize.x, -pixelSize.y), 0).rgb;
	vec3 colml   = texture2DLod(colortex0,texcoord+vec2(-pixelSize.x, 0.0         ), 0).rgb;
	vec3 colmr   = texture2DLod(colortex0,texcoord+vec2( pixelSize.x, 0.0         ), 0).rgb;
	vec3 colbl   = texture2DLod(colortex0,texcoord+vec2(-pixelSize.x,  pixelSize.y), 0).rgb;
	vec3 colbm   = texture2DLod(colortex0,texcoord+vec2( 0.0,          pixelSize.x), 0).rgb;
	vec3 colbr   = texture2DLod(colortex0,texcoord+vec2( pixelSize.x,  pixelSize.y), 0).rgb;

	vec3 min_col = min(scenecol,min(min(min(coltl,coltm),min(coltr,colml)),min(min(colmr,colbl),min(colbm,colbr))));
	vec3 max_col = max(scenecol,max(max(max(coltl,coltm),max(coltr,colml)),max(max(colmr,colbl),max(colbm,colbr))));

    vec3 repcol = texture_catmullrom(colortex1, rcoord).rgb;     //removed catmull-rom, maybe that makes it blur

    vec3 taacol = clamp(repcol, min_col, max_col);

    float clamped = distance(repcol, taacol)/get_luma(repcol);


    //flicker reduction
    float ldiff     = distance(repcol, scenecol)/get_luma(repcol);
        ldiff       = 1.0-saturate(pow2(ldiff))*taa_antiflicker;
    
    vec2 vel    = (texcoord-rcoord)/pixelSize;

    float taa_weight = saturate(1.0-sqrt(length(vel))/2.5)*0.6;

    taa_weight     = max(taa_weight, 0.9);

    float lb    = taa_blend;

    taa_weight  = mix(taa_weight, 0.7, 1.0-saturate(ldiff*lb + bweight + clamped*taa_antighost));

    taacol.rgb  = mix(scenecol.rgb, taacol.rgb, taa_weight);

    return taacol;
}


void main() {
    vec4 scenecol   = texture2DLod(colortex0, texcoord, 0);
    float scenedepth = texture2D(depthtex1, texcoord).x;

    #ifdef temporal_aa
    vec3 temporal   = get_taa(scenecol.rgb, scenedepth);
        scenecol.rgb = temporal;
    #endif

    /*DRAWBUFFERS:01*/
    gl_FragData[0]  = scenecol;
    gl_FragData[1]  = vec4(temporal, 1.0);
}