#ifndef LARKMERE_TONEMAP
#define LARKMERE_TONEMAP

#include "/lib/settings.glsl"

// Shoulder on highlights. The toe stays near linear so gray fog does not lift to white.
vec3 filmicCurve(vec3 x) {
    vec3 h = max(x, vec3(0.0));
    vec3 num = h * (h * 0.60 + 0.35);
    vec3 den = h * (h * 0.60 + 0.55) + 0.30;
    return num / den;
}

vec3 gradeAndTonemap(vec3 color, float rain, float thunder, float day, float blueHour, float nightVisionAmount, float blind, float dark) {
    color = max(color, vec3(0.0));

    // Weather is mostly in the sky and the fog. This pass only settles it.
    color *= mix(1.0, 0.90, rain);
    color = mix(color, color * vec3(0.90, 0.94, 0.98), rain * 0.45);
    color *= mix(1.0, 0.82, thunder);

    float exposure = mix(1.10, 0.78, day);
    exposure = mix(exposure, 0.95, blueHour * 0.5);
    exposure *= mix(1.0, 0.90, rain);
    exposure = mix(exposure, 1.45, clamp(nightVisionAmount, 0.0, 1.0));
    color *= exposure;

    color = filmicCurve(color);

    float luma = dot(color, vec3(0.25, 0.65, 0.10));
    color += vec3(0.004, 0.006, 0.012) * (1.0 - smoothstep(0.0, 0.40, luma));
    color += vec3(0.012, 0.005, 0.0) * smoothstep(0.62, 0.95, luma);
    color = mix(color, color * vec3(0.90, 0.94, 1.0), blueHour * 0.35);

    color = pow(max(color, vec3(0.0)), vec3(1.0 / 2.2));

    color *= 1.0 - clamp(blind, 0.0, 1.0) * 0.92;
    color *= 1.0 - clamp(dark, 0.0, 1.0) * 0.88;
    return color;
}

#endif
