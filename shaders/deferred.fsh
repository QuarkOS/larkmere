#version 330 compatibility
//
// Pipeline, after the gbuffer and shadow passes:
//   deferred   — light opaque pixels, aerial perspective, copy to colortex5
//   water      — refraction from that copy, reflection, then weather
//   composite  — shadow-map light shafts into colortex0
//   composite1 — bloom extract (half res)
//   composite2/3 — blur
//   final      — bloom, weather grade, filmic tonemap

#include "/lib/lighting.glsl"
#include "/lib/fog.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;

in vec2 texcoord;

/* RENDERTARGETS: 0,5 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outCopy;

void main() {
    float depth = texture(depthtex0, texcoord).r;
    vec3 albedo = texture(colortex0, texcoord).rgb;
    vec4 data = texture(colortex2, texcoord);
    float material = data.b;
    vec2 lightLevel = data.rg;
    float ao = data.a;

    vec3 view = viewPosFromDepth(depth, texcoord);
    vec3 player = (gbufferModelViewInverse * vec4(view, 1.0)).xyz;
    vec3 worldNormal = safeNormalize(mat3(gbufferModelViewInverse) * (texture(colortex1, texcoord).rgb * 2.0 - 1.0));

    vec3 lit;
    if (material > 0.90) {
        lit = applyAerial(albedo, player, view, 1.0);
    } else if (material < 0.10) {
        lit = albedo;
        if (isEyeInWater > 0) {
            lit = applyAerial(lit, player, view, 1.0);
        }
    } else {
        lit = lightScene(albedo, worldNormal, player, lightLevel, material, ao, true);
        lit = applyAerial(lit, player, view, lightLevel.y);
    }

    outColor = vec4(lit, 1.0);
    outCopy = outColor;
}
