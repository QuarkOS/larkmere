#ifndef LARKMERE_WAVES
#define LARKMERE_WAVES

#include "/lib/common.glsl"

float waterHeight(vec2 worldXZ, float id) {
    float amp = mix(0.020, 0.052, rainStrength);
    float speed = mix(0.85, 1.40, rainStrength);
    if (abs(id - ID_LAVA) < 0.5) {
        amp = 0.018;
        speed = 0.22;
    } else if (abs(id - ID_ICE) < 0.5) {
        return 0.0;
    }

    float t = frameTimeCounter * speed;
    float h = sin(worldXZ.x * 0.52 + t) * sin(worldXZ.y * 0.44 + t * 0.82);
    h += sin(dot(worldXZ, vec2(0.86, 0.31)) + t * 1.35) * 0.55;
    return h * amp;
}

vec3 waveNormal(vec2 worldXZ, float id) {
    float e = 0.30;
    float h = waterHeight(worldXZ, id);
    float hx = waterHeight(worldXZ + vec2(e, 0.0), id);
    float hz = waterHeight(worldXZ + vec2(0.0, e), id);
    return safeNormalize(vec3(h - hx, e, h - hz));
}

#endif
