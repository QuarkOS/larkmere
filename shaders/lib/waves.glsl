#ifndef LARKMERE_WAVES
#define LARKMERE_WAVES

#include "/lib/common.glsl"

float waterHeight(vec2 worldXZ, float id) {
    float amp = mix(0.016, 0.050, rainStrength);
    float speed = mix(0.72, 1.35, rainStrength);
    if (abs(id - ID_LAVA) < 0.5) {
        amp = 0.016;
        speed = 0.20;
    } else if (abs(id - ID_ICE) < 0.5) {
        return 0.0;
    }

    float t = frameTimeCounter * speed;
    float h = sin(dot(worldXZ, vec2(0.37, 0.21)) + t) * 0.52;
    h += sin(dot(worldXZ, vec2(-0.29, 0.58)) + t * 1.31) * 0.31;
    h += sin(dot(worldXZ, vec2(0.83, -0.17)) * 1.65 + t * 1.87) * 0.17;
    return h * amp;
}

vec3 waveNormal(vec2 worldXZ, float id) {
    float e = 0.28;
    float h = waterHeight(worldXZ, id);
    float hx = waterHeight(worldXZ + vec2(e, 0.0), id);
    float hz = waterHeight(worldXZ + vec2(0.0, e), id);
    return safeNormalize(vec3(h - hx, e, h - hz));
}

#endif
