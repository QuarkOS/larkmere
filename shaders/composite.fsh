#version 330 compatibility
#include "/lib/shadows.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

vec3 volumetricShafts(vec2 uv) {
#ifndef VOLUMETRIC_LIGHT
    return vec3(0.0);
#else
    if (!hasSkylight || isEyeInWater == 2) {
        return vec3(0.0);
    }

    float depth = texture(depthtex0, uv).r;
    vec3 view = viewPosFromDepth(depth, uv);
    float dist = length(view);
    if (dist < 1.25) {
        return vec3(0.0);
    }

    float marchLen = min(dist, 72.0);
    vec3 endView = view * (marchLen / dist);
    float material = texture(colortex2, uv).b;
    float skyLight = texture(colortex2, uv).g;
    // Unlit pixels are the sky only when they sit on the far plane.
    // The hand is also unlit, and it is close — shafts should not cover it.
    float gate = material < 0.10
        ? (depth > 0.98 ? 1.0 : 0.0)
        : smoothstep(0.06, 0.42, skyLight);
    if (gate <= 0.001) {
        return vec3(0.0);
    }

    float jitter = hash12(gl_FragCoord.xy);
    float accum = 0.0;
    float weightSum = 0.0;
    for (int i = 0; i < VOL_STEPS; i++) {
        float t = (float(i) + jitter) / float(VOL_STEPS);
        t = t * t * 0.65 + t * 0.35;
        vec3 sampleView = endView * t;
        vec3 samplePlayer = (gbufferModelViewInverse * vec4(sampleView, 1.0)).xyz;
        float lit = sampleShadow(samplePlayer, vec3(0.0));
        float w = exp(-length(sampleView) * 0.028);
        accum += lit * w;
        weightSum += w;
    }
    accum /= max(weightSum, 1e-4);

    float sunPart = sunIntensity();
    float moonPart = moonIntensity();
    vec3 tint = sunPart >= moonPart ? sunDiscColor() : moonDiscColor();
    float density = 0.62 * gate;
    density *= mix(1.0, 0.40, rainStrength);
    density *= smoothstep(0.0, 0.10, shadowLightElevation());
    return tint * accum * density * (sunPart + moonPart);
#endif
}

void main() {
    vec3 color = texture(colortex0, texcoord).rgb;
#ifdef VOLUMETRIC_LIGHT
    color += volumetricShafts(texcoord);
#endif
    outColor = vec4(max(color, vec3(0.0)), 1.0);
}
