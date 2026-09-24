#ifndef LARKMERE_SKY
#define LARKMERE_SKY

#include "/lib/common.glsl"

// Sun elevation in view space. 1 is overhead, 0 is the horizon, negative is night.
float sunElevation() {
    return dot(safeNormalize(sunPosition), safeNormalize(upPosition));
}

float shadowLightElevation() {
    return dot(safeNormalize(shadowLightPosition), safeNormalize(upPosition));
}

float daylightFactor() {
    return smoothstep(-0.06, 0.16, sunElevation());
}

float goldenFactor() {
    float elev = sunElevation();
    return exp(-pow((elev - 0.045) / 0.15, 2.0));
}

float blueHourFactor() {
    float elev = sunElevation();
    return exp(-pow(elev / 0.11, 2.0));
}

vec3 sunDiscColor() {
    float elev = sunElevation();
    float day = smoothstep(0.0, 0.32, elev);
    vec3 high = vec3(1.00, 0.965, 0.90);
    vec3 low = vec3(1.00, 0.50, 0.24);
    vec3 c = mix(low, high, day);
    c = mix(c, low, goldenFactor() * 0.72);
    c = mix(c, vec3(0.62, 0.58, 0.52), smoothstep(0.04, -0.10, elev));
    return c;
}

vec3 moonDiscColor() {
    return vec3(0.58, 0.68, 0.92);
}

// Cool light that fills shadows. This is the valley's actual color.
vec3 skyFillColor() {
    float day = daylightFactor();
    float golden = goldenFactor();
    vec3 dayFill = vec3(0.48, 0.58, 0.70);
    vec3 goldenFill = vec3(0.30, 0.38, 0.54);
    vec3 nightFill = vec3(0.040, 0.052, 0.090);
    vec3 c = mix(nightFill, dayFill, day);
    c = mix(c, goldenFill, golden * day);
    c = mix(c, vec3(0.34, 0.36, 0.40), rainStrength * 0.65);
    c *= mix(1.0, 0.55, thunderStrength);
    return c;
}

float sunIntensity() {
    if (!hasSkylight) {
        return 0.0;
    }
    float elev = sunElevation();
    float intensity = smoothstep(-0.02, 0.14, elev);
    intensity *= mix(1.0, 0.22, rainStrength);
    intensity *= mix(1.0, 0.40, thunderStrength);
    return intensity;
}

float moonIntensity() {
    if (!hasSkylight) {
        return 0.0;
    }
    float moonElev = dot(safeNormalize(moonPosition), safeNormalize(upPosition));
    float intensity = smoothstep(-0.02, 0.18, moonElev) * (1.0 - daylightFactor());
    intensity *= mix(1.0, 0.35, rainStrength);
    return intensity * 0.22;
}

// View-space direction to a sky color. Shared by the sky pass and aerial fog
// so the horizon and the mist are the same atmosphere.
vec3 atmosphereColor(vec3 viewDir) {
    vec3 dir = safeNormalize(viewDir);
    float height = dot(dir, safeNormalize(upPosition));

    if (!hasSkylight && hasCeiling) {
        vec3 low = vec3(0.26, 0.07, 0.035);
        vec3 high = vec3(0.10, 0.025, 0.018);
        return mix(low, high, clamp(height, 0.0, 1.0));
    }
    if (!hasSkylight) {
        vec3 low = vec3(0.14, 0.09, 0.18);
        vec3 high = vec3(0.035, 0.028, 0.065);
        return mix(low, high, clamp(height, 0.0, 1.0));
    }

    float day = daylightFactor();
    float golden = goldenFactor();
    float blueHour = blueHourFactor();

    vec3 zenith = mix(vec3(0.010, 0.014, 0.032), vec3(0.26, 0.44, 0.70), day);
    vec3 horizon = mix(vec3(0.045, 0.055, 0.090), vec3(0.64, 0.71, 0.76), day);
    horizon = mix(horizon, vec3(0.90, 0.52, 0.30), golden * smoothstep(-0.05, 0.20, sunElevation()));
    horizon = mix(horizon, vec3(0.52, 0.40, 0.48), blueHour * 0.80);

    float grad = smoothstep(-0.08, 0.55, height);
    vec3 sky = mix(horizon, zenith, grad);

    sky = mix(sky, vec3(0.20, 0.22, 0.25), rainStrength * 0.82);
    vec3 stormHorizon = vec3(0.32, 0.34, 0.36);
    sky = mix(sky, mix(stormHorizon, vec3(0.16, 0.17, 0.19), grad), thunderStrength * 0.75);

    vec3 sunDir = safeNormalize(sunPosition);
    float sunDot = clamp(dot(dir, sunDir), 0.0, 1.0);
    float glow = pow(sunDot, 7.0) * sunIntensity();
    sky += sunDiscColor() * glow * 0.42;

    vec3 moonDir = safeNormalize(moonPosition);
    float moonDot = clamp(dot(dir, moonDir), 0.0, 1.0);
    sky += moonDiscColor() * pow(moonDot, 12.0) * moonIntensity() * 0.35;

    return sky;
}

#endif
