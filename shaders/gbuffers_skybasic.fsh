#version 330 compatibility
#include "/lib/sky.glsl"

uniform sampler2D gtexture;
uniform int renderStage;

in vec2 texcoord;
in vec4 tint;
in vec3 viewPos;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    if (renderStage == MC_RENDER_STAGE_STARS) {
        vec3 star = tint.rgb * vec3(0.78, 0.84, 0.96);
        if (max(star.r, max(star.g, star.b)) < 0.04) {
            discard;
        }
        float night = 1.0 - daylightFactor();
        star *= 1.15 * mix(0.15, 1.0, night);
        star *= mix(1.0, 0.25, rainStrength);
        outColor = vec4(star, 1.0);
        return;
    }

    if (renderStage == MC_RENDER_STAGE_VOID) {
        outColor = vec4(vec3(0.004, 0.004, 0.006), 1.0);
        return;
    }

    if (renderStage == MC_RENDER_STAGE_CUSTOM_SKY) {
        vec4 tex = texture(gtexture, texcoord) * tint;
        if (tex.a < 0.01) {
            discard;
        }
        outColor = vec4(tex.rgb, 1.0);
        return;
    }

    // Vanilla sunrise/sunset is a tilted card. Painting a radial glow on it
    // draws a square with rings in the sky. The dome gradient covers that light.
    if (renderStage == MC_RENDER_STAGE_SUNSET) {
        discard;
    }

    outColor = vec4(atmosphereColor(safeNormalize(viewPos)), 1.0);
}
