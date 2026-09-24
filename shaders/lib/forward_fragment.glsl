#include "/lib/lighting.glsl"
#include "/lib/fog.glsl"

uniform sampler2D gtexture;
uniform float alphaTestRef;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 tint;
in vec3 viewPos;
in vec3 playerPos;
in vec3 worldNormal;
in vec3 viewNormal;
in float blockId;
in float ao;

layout(location = 0) out vec4 outColor;

void main() {
    vec4 albedo = texture(gtexture, texcoord) * tint;
#ifndef LARK_BLEND
    if (albedo.a < alphaTestRef) {
        discard;
    }
#else
    if (albedo.a < 0.01) {
        discard;
    }
#endif

    vec2 lightLevel = decodeLightmap(lmcoord);
#ifdef LARK_HAND
    bool castShadow = false;
#else
    bool castShadow = true;
#endif
    vec3 lit = lightScene(albedo.rgb, worldNormal, playerPos, lightLevel, MAT_ENTITY, 1.0, castShadow);
#ifndef LARK_HAND
    lit = applyAerial(lit, playerPos, viewPos, lightLevel.y);
#endif

#ifdef LARK_BLEND
    outColor = vec4(lit, albedo.a);
#else
    outColor = vec4(lit, 1.0);
#endif
}
