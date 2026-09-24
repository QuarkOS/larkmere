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

    if (geoWorld.y > 0.65 && (fluid || ice) && !ice) {
        nWorld = waveNormal(worldPos.xz, lava ? ID_LAVA : blockId);
        nView = safeNormalize(mat3(gbufferModelView) * nWorld);
    }

    if (lava) {
        float crest = clamp(nWorld.y, 0.0, 1.0);
        vec3 hot = albedo.rgb * vec3(1.30, 0.52, 0.15) * mix(0.70, 1.40, crest);
        vec3 lit = applyAerial(hot * 2.3, playerPos, viewPos, 1.0);
        outColor = vec4(lit, 1.0);
        return;
    }

    float surfaceDepth = gl_FragCoord.z;
    vec2 refrOffset = nView.xy * (ice ? 0.0035 : 0.011);
    if (!ice) {
        refrOffset *= 1.0 + rainStrength;
    }
    vec2 refrUV = clamp(screenUV + refrOffset, vec2(0.001), vec2(0.999));
    float refrDepth = texture(depthtex1, refrUV).r;
    if (refrDepth < surfaceDepth) {
        refrUV = screenUV;
        refrDepth = texture(depthtex1, screenUV).r;
    }

    vec3 behind = texture(colortex5, refrUV).rgb;
    vec3 behindView = viewPosFromDepth(refrDepth, refrUV);
    float thickness = clamp(length(behindView) - length(viewPos), 0.0, 18.0);

    if (!(fluid || ice)) {
        vec3 tinted = mix(behind, behind * albedo.rgb, clamp(albedo.a, 0.20, 0.85));
        float ndotv = clamp(dot(geoView, -safeNormalize(viewPos)), 0.0, 1.0);
        float fresnel = 0.04 + 0.18 * pow(1.0 - ndotv, 5.0);
        vec3 reflection = atmosphereColor(reflect(safeNormalize(viewPos), geoView));
        outColor = vec4(mix(tinted, reflection, fresnel), 1.0);
        return;
    }

    vec3 sigma = ice ? vec3(0.07, 0.05, 0.035) : vec3(0.20, 0.09, 0.065);
    if (!ice) {
        sigma *= mix(1.0, 1.35, rainStrength);
    }
    vec3 deep = ice ? vec3(0.50, 0.64, 0.70) : vec3(0.025, 0.085, 0.105);
    vec3 absorbed = behind * exp(-thickness * sigma);
    absorbed = mix(absorbed, deep, 1.0 - exp(-thickness * (ice ? 0.07 : 0.15)));

    vec3 incident = safeNormalize(viewPos);
    vec3 reflectView = reflect(incident, nView);
    vec3 reflection = atmosphereColor(reflectView);

    float stepLen = max(0.50, length(viewPos) * 0.055);
    vec3 march = viewPos;
    vec3 marchDir = safeNormalize(reflectView);
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
            reflection = mix(reflection, texture(colortex5, uv).rgb, edgeFade * (ice ? 0.40 : 0.78));
            break;
        }
        stepLen *= 1.30;
    }

    vec3 lightDirView = safeNormalize(shadowLightPosition);
    vec3 halfDir = safeNormalize(lightDirView - incident);
    float specPower = ice ? 72.0 : mix(150.0, 32.0, rainStrength);
    float spec = pow(clamp(dot(nView, halfDir), 0.0, 1.0), specPower);
    float shadow = sampleShadow(playerPos, nWorld);
    vec3 glint = (sunDiscColor() * sunIntensity() + moonDiscColor() * moonIntensity()) * spec * shadow;

    float ndotv = clamp(dot(nView, -incident), 0.0, 1.0);
    float f0 = ice ? 0.08 : 0.02;
    float fresnel = f0 + (1.0 - f0) * pow(1.0 - ndotv, 5.0);
    if (!ice) {
        fresnel *= mix(1.0, 0.82, rainStrength);
    }

    vec3 color = mix(absorbed, reflection, clamp(fresnel, 0.0, 1.0));
    color += glint * (ice ? 0.35 : 0.80);
    color = applyAerial(color, playerPos, viewPos, hasSkylight ? 1.0 : 0.0);
    outColor = vec4(color, 1.0);
}
