#include "/lib/common.glsl"
#include "/lib/wind.glsl"

#ifdef LARK_TERRAIN
in vec2 mc_Entity;
#endif

out vec2 texcoord;
out vec2 lmcoord;
out vec4 tint;
out vec3 viewPos;
out vec3 playerPos;
out vec3 worldNormal;
out vec3 viewNormal;
out float blockId;
out float ao;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    vec3 rawNormal = gl_Normal;
    if (length(rawNormal) > 0.0) {
        viewNormal = normalize(gl_NormalMatrix * rawNormal);
    } else {
        viewNormal = vec3(0.0, 0.0, 1.0);
    }
    worldNormal = safeNormalize(mat3(gbufferModelViewInverse) * viewNormal);

    vec4 view0 = gl_ModelViewMatrix * gl_Vertex;
    playerPos = (gbufferModelViewInverse * view0).xyz;

#ifdef LARK_TERRAIN
    blockId = mc_Entity.x;
    playerPos = applyWind(playerPos, blockId);
    ao = gl_Color.a;
    tint = vec4(gl_Color.rgb, 1.0);
#else
    blockId = 0.0;
    ao = 1.0;
    tint = gl_Color;
#endif

    vec4 view = gbufferModelView * vec4(playerPos, 1.0);
    viewPos = view.xyz;
    gl_Position = gl_ProjectionMatrix * view;
}
