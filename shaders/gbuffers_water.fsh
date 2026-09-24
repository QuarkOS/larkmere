#version 330 compatibility
//
// Forward water. gbuffers cannot sample colortex0-3 (those units are the
// atlas), so refraction reads the deferred copy in colortex5.

#include "/lib/lighting.glsl"
#include "/lib/fog.glsl"
#include "/lib/waves.glsl"

uniform sampler2D gtexture;
uniform sampler2D depthtex1;
uniform sampler2D colortex5;

in vec2 texcoord;
in vec4 tint;
in vec3 viewPos;
in vec3 playerPos;
in vec3 worldPos;
in vec3 worldNormal;
in vec3 viewNormal;
in float blockId;
in float fluidFlag;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec4 albedo = texture(gtexture, texcoord) * tint;
    bool lava = abs(blockId - ID_LAVA) < 0.5;
    bool ice = abs(blockId - ID_ICE) < 0.5;
    bool fluid = fluidFlag > 0.5 || lava;

    if (!fluid && !ice && albedo.a < 0.02) {
        discard;
    }

    vec2 screenUV = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    vec3 geoWorld = safeNormalize(worldNormal);
    vec3 geoView = safeNormalize(viewNormal);
    vec3 nWorld = geoWorld;
    vec3 nView = geoView;

    if (geoWorld.y > 0.65 && fluid && !ice) {
        nWorld = waveNormal(worldPos.xz, lava ? ID_LAVA : blockId);
        nView = safeNormalize(mat3(gbufferModelView) * nWorld);
    }

    if (lava) {
        vec3 hot = srgbToLinear(albedo.rgb);
        float crest = clamp(nWorld.y, 0.0, 1.0);
        vec3 crust = hot * vec3(1.05, 0.22, 0.04);
        vec3 molten = hot * vec3(1.55, 0.62, 0.12);
        vec3 glow = mix(crust, molten, crest) * 5.2;
        outColor = vec4(applyAerial(glow, playerPos, viewPos, 1.0), 1.0);
        return;
    }

    float surfaceDepth = gl_FragCoord.z;
    vec2 refrOffset = nView.xy * (ice ? 0.0030 : 0.012);
    if (!ice) {
        refrOffset *= mix(1.0, 1.65, rainStrength);
    }
    vec2 refrUV = clamp(screenUV + refrOffset, vec2(0.001), vec2(0.999));
    float refrDepth = texture(depthtex1, refrUV).r;
    if (refrDepth < surfaceDepth) {
        refrUV = screenUV;
        refrDepth = texture(depthtex1, screenUV).r;
    }

    vec3 behind = texture(colortex5, refrUV).rgb;
    vec3 behindView = viewPosFromDepth(refrDepth, refrUV);
    float thickness = clamp(length(behindView) - length(viewPos), 0.0, 16.0);

    if (!(fluid || ice)) {
        vec3 tintLin = srgbToLinear(albedo.rgb);
        float cover = clamp(albedo.a, 0.15, 0.85);
        vec3 tinted = mix(behind, behind * tintLin, cover);
        float ndotv = clamp(dot(geoView, -safeNormalize(viewPos)), 0.0, 1.0);
        float fresnel = 0.04 + 0.16 * pow(1.0 - ndotv, 5.0);
        vec3 reflection = atmosphereColor(reflect(safeNormalize(viewPos), geoView));
        vec3 glass = mix(tinted, reflection, fresnel);
        glass = applyAerial(glass, playerPos, viewPos, hasSkylight ? 1.0 : 0.0);
        outColor = vec4(glass, 1.0);
        return;
    }

    vec3 sigma = ice ? vec3(0.055, 0.040, 0.030) : vec3(0.24, 0.105, 0.075);
    if (!ice) {
        sigma *= mix(1.0, 1.30, rainStrength);
    }
    vec3 deep = ice ? vec3(0.42, 0.55, 0.62) : vec3(0.010, 0.032, 0.040);
    if (!ice) {
        deep = mix(deep, deep * 0.65, rainStrength);
    }
    vec3 absorbed = behind * exp(-thickness * sigma);
    absorbed = mix(absorbed, deep, 1.0 - exp(-thickness * (ice ? 0.06 : 0.13)));

    vec3 incident = safeNormalize(viewPos);
    vec3 reflectView = reflect(incident, nView);
    vec3 reflection = atmosphereColor(reflectView) * (ice ? 0.85 : 0.90);

    float stepLen = max(0.45, length(viewPos) * 0.050);
    vec3 march = viewPos;
    vec3 marchDir = safeNormalize(reflectView);
    float ssrWeight = ice ? 0.45 : mix(0.82, 0.38, rainStrength);
    for (int i = 0; i < 8; i++) {
        march += marchDir * stepLen;
        vec4 clip = gbufferProjection * vec4(march, 1.0);
        if (clip.w <= 0.0) {
            break;
        }
        vec2 uv = clip.xy / clip.w * 0.5 + 0.5;
        if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
            break;
        }
        float sceneDepth = texture(depthtex1, uv).r;
        vec3 sceneView = viewPosFromDepth(sceneDepth, uv);
        float gap = sceneView.z - march.z;
        if (march.z < sceneView.z && gap < stepLen * 2.0 && sceneView.z < viewPos.z - 0.30) {
            float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
            float edgeFade = smoothstep(0.0, 0.08, edge);
            reflection = mix(reflection, texture(colortex5, uv).rgb, edgeFade * ssrWeight);
            break;
        }
        stepLen *= 1.32;
    }

    vec3 lightDirView = safeNormalize(shadowLightPosition);
    vec3 halfDir = safeNormalize(lightDirView - incident);
    float ndoth = clamp(dot(nView, halfDir), 0.0, 1.0);
    float tightPower = ice ? 80.0 : mix(140.0, 28.0, rainStrength);
    float widePower = ice ? 18.0 : mix(14.0, 6.0, rainStrength);
    float spec = pow(ndoth, tightPower) * 0.90 + pow(ndoth, widePower) * 0.07;
    float shadow = sampleShadow(playerPos, nWorld);
    vec3 glint = sunDiscColor() * spec * shadow * sunIntensity();
    glint += moonDiscColor() * pow(ndoth, tightPower) * shadow * moonIntensity() * 0.65;

    float ndotv = clamp(dot(nView, -incident), 0.0, 1.0);
    float f0 = ice ? 0.09 : 0.020;
    float fresnel = f0 + (1.0 - f0) * pow(1.0 - ndotv, 5.0);
    if (!ice) {
        fresnel *= mix(1.0, 0.72, rainStrength);
    }
    fresnel = clamp(fresnel, 0.0, 1.0);

    vec3 color = mix(absorbed, reflection, fresnel);
    color += glint * (ice ? 0.40 : 0.75);
    color = applyAerial(color, playerPos, viewPos, hasSkylight ? 1.0 : 0.0);
    outColor = vec4(color, 1.0);
}
