#include "/lib/common.glsl"

uniform sampler2D gtexture;
uniform float alphaTestRef;

#ifdef LARK_ENTITY
uniform vec4 entityColor;
#endif

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
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outData;

void main() {
    vec4 albedo = texture(gtexture, texcoord) * tint;
    if (albedo.a < alphaTestRef) {
        discard;
    }

    float material = MAT_TERRAIN;

#ifdef LARK_ENTITY
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
    material = MAT_ENTITY;
#elif defined(LARK_BLOCK)
    material = MAT_ENTITY;
#elif defined(LARK_TERRAIN)
    if (abs(blockId - ID_LEAVES) < 0.5 || abs(blockId - ID_PLANTS) < 0.5) {
        material = MAT_FOLIAGE;
    } else if (abs(blockId - ID_EMISSIVE) < 0.5) {
        material = MAT_EMISSIVE;
    }
#endif

    vec2 lightLevel = decodeLightmap(lmcoord);
    outColor = vec4(albedo.rgb, 1.0);
    outNormal = vec4(viewNormal * 0.5 + 0.5, 1.0);
    outData = vec4(lightLevel, material, clamp(ao, 0.0, 1.0));
}
