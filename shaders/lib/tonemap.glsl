#ifndef LARKMERE_TONEMAP
#define LARKMERE_TONEMAP

#include "/lib/settings.glsl"

// Shoulder on highlights only. Below the knee the curve is a power
// through the origin, so mid-gray mist is not lifted toward white.
vec3 filmicCurve(vec3 x) {
    vec3 h = pow(max(x, vec3(0.0)), vec3(1.04));
    float knee = 0.70;
    float room = 0.30;
    float softness = 0.85;
    vec3 over = max(h - vec3(knee), vec3(0.0));
    vec3 shoulder = vec3(knee) + room * over / (over + vec3(softness));
    // Below the knee, keep the value. Using the shoulder alone lifts gray to the knee.
    vec3 shaped = mix(h, shoulder, step(vec3(knee), h));
    return min(shaped, vec3(1.0));
}

vec3 gradeAndTonemap(vec3 color, float rain, float thunder, float day, float golden, float blueHour, float nightVisionAmount, float blind, float dark) {
    color = max(color, vec3(0.0));

    color *= mix(1.0, 0.88, rain);
    color *= mix(1.0, 0.78, thunder);

    float exposure = mix(1.42, 0.90, day);
    exposure = mix(exposure, 1.02, golden * day);
    exposure = mix(exposure, 0.96, blueHour * 0.35);
    exposure *= mix(1.0, 0.92, rain);
    exposure = mix(exposure, 1.55, clamp(nightVisionAmount, 0.0, 1.0));
    color *= exposure;

    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    float sat = mix(1.04, 1.14, day);
    sat = mix(sat, 0.90, rain);
    sat = mix(sat, 1.06, golden * 0.45);
    color = mix(vec3(luma), color, sat);

    color = filmicCurve(color);

    luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    // Cool shade by pulling warmth out. Every channel stays at or below 1,
    // so this cannot lift pewter fog.
    float shade = 1.0 - smoothstep(0.05, 0.32, luma);
    vec3 cool = vec3(0.86, 0.93, 1.00);
    color *= mix(vec3(1.0), cool, shade * mix(0.60, 0.22, rain) * day);

    float warm = smoothstep(0.48, 0.92, luma) * golden;
    color *= mix(vec3(1.0), vec3(1.05, 1.01, 0.92), warm);
    color = mix(color, color * vec3(0.94, 0.97, 1.00), blueHour * 0.28);

    color = pow(max(color, vec3(0.0)), vec3(1.0 / 2.2));
    color *= 1.0 - clamp(blind, 0.0, 1.0) * 0.92;
    color *= 1.0 - clamp(dark, 0.0, 1.0) * 0.88;
    return clamp(color, vec3(0.0), vec3(1.0));
}

#endif
