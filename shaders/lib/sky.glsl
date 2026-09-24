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
    return smoothstep(-0.08, 0.18, sunElevation());
}

// Peaks while the sun is low, and is gone by mid-morning.
float goldenFactor() {
    float elev = sunElevation();
    float d = (elev - 0.10) / 0.11;
    return exp(-d * d);
}

float blueHourFactor() {
    float elev = sunElevation();
    float d = elev / 0.075;
    return exp(-d * d);
}

vec3 sunDiscColor() {
    float elev = sunElevation();
    float high = smoothstep(0.06, 0.38, elev);
    vec3 noon = vec3(1.00, 0.96, 0.88);
    vec3 low = vec3(1.00, 0.42, 0.14);
    vec3 c = mix(low, noon, high);
    c = mix(c, low, goldenFactor() * 0.88);
    c = mix(c, vec3(0.55, 0.50, 0.46), smoothstep(0.02, -0.12, elev));
    return c;
}

vec3 moonDiscColor() {
    return vec3(0.62, 0.74, 0.98);
}

// Cool skylight that fills shade. Kept dim so the sun remains the key.
vec3 skyFillColor() {
    float day = daylightFactor();
    float golden = goldenFactor();
    vec3 dayFill = vec3(0.15, 0.19, 0.30);
    vec3 goldenFill = vec3(0.09, 0.12, 0.22);
    vec3 nightFill = vec3(0.018, 0.024, 0.046);
    vec3 c = mix(nightFill, dayFill, day);
    c = mix(c, goldenFill, golden * day);
    c = mix(c, vec3(0.11, 0.12, 0.135), rainStrength * 0.80);
    c *= mix(1.0, 0.50, thunderStrength);
    return c;
}

// Warm dust bounced up from the valley floor.
vec3 groundFillColor() {
    float day = daylightFactor();
    vec3 dayBounce = vec3(0.050, 0.042, 0.028);
    vec3 nightBounce = vec3(0.006, 0.008, 0.014);
    vec3 c = mix(nightBounce, dayBounce, day);
    c = mix(c, c * vec3(0.65, 0.72, 0.80), rainStrength);
    return c;
}

float sunIntensity() {
    if (!hasSkylight) {
        return 0.0;
    }
    float elev = sunElevation();
    float up = smoothstep(-0.03, 0.12, elev);
    float clearAir = smoothstep(0.0, 0.20, elev);
    float intensity = up * mix(0.42, 1.0, clearAir);
    intensity *= mix(1.0, 0.30, rainStrength);
    intensity *= mix(1.0, 0.42, thunderStrength);
    return intensity;
}

// Small on purpose. Callers treat this as moonlight, not a second sun.
float moonIntensity() {
    if (!hasSkylight) {
        return 0.0;
    }
    float moonElev = dot(safeNormalize(moonPosition), safeNormalize(upPosition));
    float intensity = smoothstep(-0.02, 0.16, moonElev) * (1.0 - daylightFactor());
    intensity *= mix(1.0, 0.30, rainStrength);
    return intensity * 0.30;
}

// Sky gradient without the sun disc. Fog derives from this, then clamps it.
vec3 atmosphereBase(vec3 viewDir) {
    vec3 dir = safeNormalize(viewDir);
    vec3 up = safeNormalize(upPosition);
    float height = dot(dir, up);

    if (!hasSkylight && hasCeiling) {
        vec3 low = vec3(0.15, 0.038, 0.018);
        vec3 high = vec3(0.040, 0.010, 0.007);
        return mix(low, high, clamp(height * 0.5 + 0.5, 0.0, 1.0));
    }
    if (!hasSkylight) {
        vec3 low = vec3(0.065, 0.032, 0.105);
        vec3 high = vec3(0.014, 0.009, 0.038);
        return mix(low, high, clamp(height * 0.5 + 0.5, 0.0, 1.0));
    }

    float day = daylightFactor();
    float golden = goldenFactor();
    float blueHour = blueHourFactor();

    // More air along the horizon than toward the zenith.
    float air = exp(-max(height, -0.04) * 3.05);
    air = clamp(air, 0.0, 1.0);

    vec3 zenith = mix(vec3(0.0032, 0.0060, 0.018), vec3(0.022, 0.100, 0.46), day);
    vec3 horizon = mix(vec3(0.010, 0.014, 0.028), vec3(0.44, 0.52, 0.58), day);

    vec3 sunDir = safeNormalize(sunPosition);
    float facingSun = clamp(dot(dir, sunDir), 0.0, 1.0);
    float horizonBand = exp(-max(height, 0.0) * 4.6);
    horizon = mix(horizon, vec3(0.82, 0.36, 0.13), golden * facingSun * horizonBand * 0.90);
    horizon = mix(horizon, vec3(0.26, 0.20, 0.36), blueHour * (1.0 - day) * horizonBand);

    vec3 sky = mix(zenith, horizon, pow(air, 0.78));
    sky *= mix(1.0, 0.70, smoothstep(0.02, -0.20, height));

    sky = mix(sky, vec3(0.145, 0.155, 0.170), rainStrength * 0.88);
    sky = mix(sky, vec3(0.095, 0.100, 0.110), thunderStrength * 0.60);
    return sky;
}

// Distance mist. Tied to the sky, then held down so gray cannot grade out to white.
vec3 valleyMistColor(vec3 viewDir) {
    vec3 sky = atmosphereBase(viewDir);
    if (!hasSkylight) {
        return sky;
    }

    float day = daylightFactor();
    float golden = goldenFactor();
    vec3 pewter = mix(vec3(0.008, 0.010, 0.018), vec3(0.26, 0.29, 0.32), day);
    vec3 mist = mix(pewter, min(sky * 0.55, vec3(0.40)), 0.42);
    mist = mix(mist, vec3(0.36, 0.22, 0.13), golden * day * 0.38);
    mist = mix(mist, vec3(0.11, 0.12, 0.13), rainStrength * 0.78);
    mist *= mix(1.0, 0.68, thunderStrength);

    float cap = mix(0.10, 0.34, day);
    cap = mix(cap, 0.30, golden);
    return min(mist, vec3(cap));
}

// Tight halo only. A wide falloff paints the dome and washes the valley out.
vec3 atmosphereColor(vec3 viewDir) {
    vec3 dir = safeNormalize(viewDir);
    vec3 sky = atmosphereBase(dir);
    if (!hasSkylight) {
        return sky;
    }

    vec3 sunDir = safeNormalize(sunPosition);
    float mu = clamp(dot(dir, sunDir), 0.0, 1.0);
    float elev = max(sunElevation(), 0.0);
    float low = 1.0 - smoothstep(0.04, 0.42, elev);
    float power = mix(9.0, 80.0, smoothstep(0.0, 0.40, elev));
    float gain = mix(0.08, 0.62, low) * sunIntensity();
    sky += sunDiscColor() * pow(mu, power) * gain;

    vec3 moonDir = safeNormalize(moonPosition);
    float moonMu = clamp(dot(dir, moonDir), 0.0, 1.0);
    sky += moonDiscColor() * pow(moonMu, 56.0) * moonIntensity() * 0.45;
    return sky;
}

#endif
