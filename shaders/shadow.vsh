#version 330 compatibility
#include "/lib/wind.glsl"

in vec2 mc_Entity;

out vec2 texcoord;
out float blockId;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    blockId = mc_Entity.x;

    vec4 view0 = gl_ModelViewMatrix * gl_Vertex;
    vec3 player = (gbufferModelViewInverse * view0).xyz;
    player = applyWind(player, blockId);

    vec4 clip = shadowProjection * shadowModelView * vec4(player, 1.0);
    clip.xy = distortShadow(clip.xy);
    gl_Position = clip;
}
