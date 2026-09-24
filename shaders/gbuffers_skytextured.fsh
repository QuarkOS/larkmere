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
    if (tex.a < 0.40) {
        discard;
    }

    vec3 color = tex.rgb;
    if (renderStage == MC_RENDER_STAGE_SUN) {
        vec2 p = texcoord * 2.0 - 1.0;
        if (dot(p, p) > 0.90) {
            discard;
        }
        float lum = dot(tex.rgb, vec3(0.30, 0.59, 0.11));
        if (lum < 0.08) {
            discard;
        }
        // Flat disc color. Multiplying the ringed sun texture blows the quad up.
        color = sunDiscColor() * 1.65 * mix(1.0, 0.40, rainStrength);
    } else if (renderStage == MC_RENDER_STAGE_MOON) {
        color *= moonDiscColor() * 1.25 * mix(1.0, 0.45, rainStrength);
    }

    outColor = vec4(color, 1.0);
}
