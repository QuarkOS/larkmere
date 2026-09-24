#version 330 compatibility
#include "/lib/settings.glsl"

uniform sampler2D gtexture;
uniform float alphaTestRef;
uniform int renderStage;

in vec2 texcoord;
in float blockId;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 shadowColor;

void main() {
    // Water, rain, and the viewmodel should not stamp the shadow map.
    if (renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT
        || renderStage == MC_RENDER_STAGE_RAIN_SNOW
        || renderStage == MC_RENDER_STAGE_PARTICLES
        || renderStage == MC_RENDER_STAGE_HAND_SOLID
        || renderStage == MC_RENDER_STAGE_HAND_TRANSLUCENT) {
        discard;
    }

    vec4 albedo = texture(gtexture, texcoord);
    if (albedo.a < alphaTestRef) {
        discard;
    }

    shadowColor = vec4(1.0);
}
