#version 330 compatibility
#include "/lib/sky.glsl"

uniform sampler2D gtexture;
uniform int renderStage;

in vec2 texcoord;
in vec4 tint;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec4 tex = texture(gtexture, texcoord) * tint;
    if (tex.a < 0.10) {
        discard;
    }

    vec3 color = tex.rgb;
    if (renderStage == MC_RENDER_STAGE_SUN) {
        color *= sunDiscColor() * 5.5 * mix(1.0, 0.35, rainStrength);
    } else if (renderStage == MC_RENDER_STAGE_MOON) {
        color *= moonDiscColor() * 1.6 * mix(1.0, 0.40, rainStrength);
    }

    outColor = vec4(color, 1.0);
}
