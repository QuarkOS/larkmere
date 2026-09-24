#ifndef LARKMERE_LIGHTING
#define LARKMERE_LIGHTING

#include "/lib/shadows.glsl"

// Linear HDR color for one surface. Shadows, weather, and emissive blocks
// all come through here so the grade stays consistent.
vec3 lightScene(vec3 albedo, vec3 worldNormal, vec3 playerPos, vec2 lightLevel, float material, float ao, bool castShadow) {
    vec3 n = safeNormalize(worldNormal);
    vec3 lightDir = safeNormalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    vec3 viewDir = safeNormalize(-playerPos);

    float ndotl = dot(n, lightDir);
    bool foliage = material > 0.50 && material < 0.70;
    bool entity = material > 0.30 && material < 0.50;
    bool emissive = material > 0.70 && material < 0.90;

    float occlusion = mix(0.42, 1.0, clamp(ao, 0.0, 1.0));
    float skyAmt = pow(clamp(lightLevel.y, 0.0, 1.0), 1.45);
    float blockAmt = pow(clamp(lightLevel.x, 0.0, 1.0), 2.05);

    float held = max(float(heldBlockLightValue), float(heldBlockLightValue2)) / 15.0;
    float heldReach = held * exp(-length(playerPos) * 0.20);
    blockAmt = max(blockAmt, heldReach * heldReach);

    if (!hasSkylight) {
        skyAmt = 0.0;
    }

    if (emissive) {
        vec3 glow = albedo * 2.15;
        glow += skyFillColor() * skyAmt * 0.08;
        return glow;
    }

    float shade = foliage
        ? clamp((ndotl + 0.42) / 1.42, 0.0, 1.0)
        : clamp(ndotl, 0.0, 1.0);

    float shadow = 1.0;
    if (castShadow && hasSkylight) {
        shadow = sampleShadow(playerPos, n);
    }

    float sunVis = shade * shadow * skyAmt * sunIntensity();
    float moonVis = shade * shadow * skyAmt * moonIntensity();

    vec3 direct = sunDiscColor() * sunVis + moonDiscColor() * moonVis;
    vec3 skyAmbient = skyFillColor() * skyAmt;
    vec3 blockLight = vec3(1.00, 0.56, 0.28) * blockAmt * 1.45;

    if (!hasSkylight && hasCeiling) {
        skyAmbient = vec3(0.22, 0.07, 0.035) * (0.35 + blockAmt * 0.15);
    } else if (!hasSkylight) {
        skyAmbient = vec3(0.09, 0.07, 0.13);
    }

    // A little light through leaves when the sun sits behind them.
    if (foliage && hasSkylight) {
        float back = pow(clamp(dot(safeNormalize(playerPos), lightDir), 0.0, 1.0), 2.0);
        direct += sunDiscColor() * back * skyAmt * sunIntensity() * 0.28;
    }

    float wet = wetness * smoothstep(0.40, 0.90, lightLevel.y) * clamp(n.y, 0.0, 1.0);
    if (foliage) {
        wet *= 0.30;
    }
    if (!hasSkylight) {
        wet = 0.0;
    }
    vec3 wetAlbedo = albedo * mix(1.0, 0.58, wet);

    vec3 lit = wetAlbedo * (direct + skyAmbient + blockLight) * occlusion;

    if (entity) {
        lit += albedo * 0.10;
    }
    lit += albedo * nightVision * vec3(0.28, 0.34, 0.24);

    if (wet > 0.001) {
        vec3 halfDir = safeNormalize(lightDir + viewDir);
        float specPower = mix(56.0, 28.0, rainStrength);
        float spec = pow(clamp(dot(n, halfDir), 0.0, 1.0), specPower);
        lit += vec3(0.95, 0.92, 0.86) * spec * wet * shadow * (sunIntensity() + moonIntensity());
    }

    // Keep a trace of air in caves so black does not crush to nothing.
    lit += albedo * vec3(0.012, 0.013, 0.016) * (1.0 - skyAmt);

    return max(lit, vec3(0.0));
}

#endif
