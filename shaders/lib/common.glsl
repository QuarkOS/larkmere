#ifndef LARKMERE_COMMON
#define LARKMERE_COMMON

#include "/lib/settings.glsl"

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform vec3 cameraPosition;
uniform vec3 upPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;

uniform float rainStrength;
uniform float wetness;
uniform float thunderStrength;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform float nightVision;
uniform float blindness;
uniform float darknessFactor;

uniform int isEyeInWater;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

uniform bool hasSkylight;
uniform bool hasCeiling;

vec3 safeNormalize(vec3 v) {
    return v / max(length(v), 1e-4);
}

// gl_TextureMatrix[1] maps the raw lightmap into roughly [0.03125, 0.96875].
vec2 decodeLightmap(vec2 lmcoord) {
    return clamp((lmcoord - 0.03125) / 0.9375, vec2(0.0), vec2(1.0));
}

vec3 viewPosFromDepth(float depth, vec2 uv) {
    vec4 ndc = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 view = gbufferProjectionInverse * ndc;
    return view.xyz / view.w;
}

// More shadow texels near the camera. Must match between the shadow pass and the sample.
vec2 distortShadow(vec2 clipXY) {
    float radius = length(clipXY);
    float denom = 0.18 + radius * 0.82;
    return clipXY / denom * 0.90;
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

#endif
