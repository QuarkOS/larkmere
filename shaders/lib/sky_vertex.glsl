#include "/lib/common.glsl"

// Celestial quads are already camera-facing in gl_ModelViewMatrix.
// Do not round-trip them through gbufferModelView — that drops the billboard.

out vec2 texcoord;
out vec4 tint;
out vec3 viewPos;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    tint = gl_Color;
    vec4 view = gl_ModelViewMatrix * gl_Vertex;
    viewPos = view.xyz;
    gl_Position = gl_ProjectionMatrix * view;
}
