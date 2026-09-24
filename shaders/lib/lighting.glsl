#ifndef LARKMERE_LIGHTING
#define LARKMERE_LIGHTING

#include "/lib/shadows.glsl"

// Linear HDR color for one surface.
// Direct sun is the warm key. Shade is skylight, so it stays cool.
vec3 lightScene(vec3 albedo, vec3 worldNormal, vec3 playerPos, vec2 lightLevel, float material, float ao, bool castShadow) {
    vec3 albedoLin = srgbToLinear(albedo);
    vec3 n = safeNormalize(worldNormal);
    vec3 lightDir = safeNormalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    vec3 viewDir = safeNormalize(-playerPos);

    float ndotl = dot(n, lightDir);
    bool foliage = material > 0.50 && material < 0.70;
    bool entity = material > 0.30 && material < 0.50;
    bool emissive = material > 0.70 && material < 0.90;

    float skyAmt = pow(clamp(lightLevel.y, 0.0, 1.0), 1.35);
    float blockAmt = pow(clamp(lightLevel.x, 0.0, 1.0), 2.10);

    float held = max(float(heldBlockLightValue), float(heldBlockLightValue2)) / 15.0;
    float heldReach = held * exp(-length(playerPos) * 0.18);
    blockAmt = max(blockAmt, heldReach * heldReach);

    if (!hasSkylight) {
        skyAmt = 0.0;
    }

    if (emissive) {
        vec3 glow = albedoLin * 4.2;
        glow += skyFillColor() * skyAmt * 0.05;
        return glow;
    }

    // Leaves wrap a little so a forest reads as a volume, not a black shell.
    float shade = foliage
        ? clamp(ndotl * 0.62 + 0.30, 0.0, 1.0)
        : clamp(ndotl, 0.0, 1.0);

    float shadow = 1.0;
    if (castShadow && hasSkylight) {
        shadow = sampleShadow(playerPos, n);
    }

    float sunVis = shade * shadow * skyAmt * sunIntensity();
    float moonVis = shade * shadow * skyAmt * moonIntensity();

    vec3 direct = sunDiscColor() * sunVis * 1.65;
    direct += moonDiscColor() * moonVis * 2.15;

    if (foliage && hasSkylight) {
        float through = pow(clamp(dot(safeNormalize(playerPos), lightDir), 0.0, 1.0), 2.4);
        direct += sunDiscColor() * vec3(1.00, 0.78, 0.42) * through * skyAmt * sunIntensity() * 0.48;
    }

    float skyWeight = clamp(n.y * 0.58 + 0.52, 0.16, 1.0);
    float groundWeight = clamp(-n.y * 0.50 + 0.22, 0.0, 0.55);
    vec3 skyAmbient = skyFillColor() * skyAmt * skyWeight;
    vec3 groundAmbient = groundFillColor() * skyAmt * groundWeight;

    if (!hasSkylight && hasCeiling) {
        skyAmbient = vec3(0.16, 0.045, 0.022) * (0.28 + blockAmt * 0.12);
        groundAmbient = vec3(0.0);
    } else if (!hasSkylight) {
        skyAmbient = vec3(0.040, 0.030, 0.065);
        groundAmbient = vec3(0.0);
    }

    vec3 blockLight = vec3(1.00, 0.46, 0.18) * blockAmt * 1.90;

    float wet = wetness * smoothstep(0.35, 0.88, lightLevel.y) * smoothstep(0.05, 0.65, n.y);
    if (foliage) {
        wet *= 0.28;
    }
    if (!hasSkylight) {
        wet = 0.0;
    }
    vec3 wetAlbedo = albedoLin * mix(1.0, 0.46, wet);

    float ambOcc = mix(0.42, 1.0, clamp(ao, 0.0, 1.0));
    float dirOcc = mix(0.78, 1.0, clamp(ao, 0.0, 1.0));

    vec3 lit = wetAlbedo * (direct * dirOcc + (skyAmbient + groundAmbient) * ambOcc + blockLight);

    if (entity) {
        lit += albedoLin * vec3(0.028, 0.030, 0.026);
    }
    lit += albedoLin * nightVision * vec3(0.20, 0.28, 0.16);
    lit += albedoLin * vec3(0.006, 0.007, 0.009) * (1.0 - skyAmt);

    if (wet > 0.001) {
        vec3 halfDir = safeNormalize(lightDir + viewDir);
        float specPower = mix(64.0, 24.0, rainStrength);
        float spec = pow(clamp(dot(n, halfDir), 0.0, 1.0), specPower);
        float ndotv = clamp(dot(n, viewDir), 0.0, 1.0);
        float fres = 0.04 + 0.30 * pow(1.0 - ndotv, 5.0);
        vec3 specCol = sunDiscColor() * sunIntensity() + moonDiscColor() * moonIntensity();
        lit += specCol * spec * fres * wet * shadow * 0.85;
    }

    return max(lit, vec3(0.0));
}

#endif
