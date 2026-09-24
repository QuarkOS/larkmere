#version 330 compatibility
#include "/lib/sky.glsl"

uniform sampler2D gtexture;
uniform int renderStage;

in vec2 texcoord;
in vec4 tint;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    if (renderStage == MC_RENDER_STAGE_SUN) {
        if (sunElevation() < -0.02) {
            discard;
        }
        // Camera-facing billboard, but only a small disc. The vanilla
        // texture is a wide card with a ring; ignore it.
        vec2 p = texcoord * 2.0 - 1.0;
        float r = length(p);
        if (r > 0.22) {
            discard;
        }
        float edge = 1.0 - smoothstep(0.11, 0.22, r);
        float core = 1.0 - smoothstep(0.0, 0.10, r);
        vec3 color = sunDiscColor() * (3.2 * edge + 11.0 * core);
        color *= mix(1.0, 0.20, rainStrength);
        color *= mix(1.0, 0.45, thunderStrength);
        outColor = vec4(color, 1.0);
        return;
    }

    vec4 tex = texture(gtexture, texcoord) * tint;
    if (tex.a < 0.40) {
        discard;
    }

    vec3 color = srgbToLinear(tex.rgb);
    if (renderStage == MC_RENDER_STAGE_MOON) {
        float moonElev = dot(safeNormalize(moonPosition), safeNormalize(upPosition));
        if (moonElev < -0.04) {
            discard;
        }
        color *= moonDiscColor() * 1.20;
        color *= mix(1.0, 0.40, rainStrength);
    }

    outColor = vec4(color, 1.0);
}
