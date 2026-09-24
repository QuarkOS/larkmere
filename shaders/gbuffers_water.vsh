#version 330 compatibility
#include "/lib/waves.glsl"

in vec2 mc_Entity;

out vec2 texcoord;
out vec4 tint;
out vec3 viewPos;
out vec3 playerPos;
out vec3 worldPos;
out vec3 worldNormal;
out vec3 viewNormal;
out float blockId;
out float fluidFlag;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    tint = gl_Color;
    blockId = mc_Entity.x;
    fluidFlag = mc_Entity.y;

    vec3 rawNormal = gl_Normal;
    if (length(rawNormal) > 0.0) {
        viewNormal = normalize(gl_NormalMatrix * rawNormal);
    } else {
        viewNormal = vec3(0.0, 0.0, 1.0);
    }
    worldNormal = safeNormalize(mat3(gbufferModelViewInverse) * viewNormal);

    vec4 view0 = gl_ModelViewMatrix * gl_Vertex;
    playerPos = (gbufferModelViewInverse * view0).xyz;
    worldPos = playerPos + cameraPosition;

    bool lava = abs(blockId - ID_LAVA) < 0.5;
    bool ice = abs(blockId - ID_ICE) < 0.5;
    if (fluidFlag > 0.5 || lava || ice) {
        playerPos.y += waterHeight(worldPos.xz, lava ? ID_LAVA : blockId);
        worldPos = playerPos + cameraPosition;
    }

    vec4 view = gbufferModelView * vec4(playerPos, 1.0);
    viewPos = view.xyz;
    gl_Position = gl_ProjectionMatrix * view;
}
