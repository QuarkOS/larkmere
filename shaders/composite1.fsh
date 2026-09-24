#version 330 compatibility
#include "/lib/settings.glsl"

uniform sampler2D colortex0;

in vec2 texcoord;

/* RENDERTARGETS: 3 */
layout(location = 0) out vec4 outColor;

void main() {
    vec3 color = texture(colortex0, texcoord).rgb;
    float luma = dot(color, vec3(0.22, 0.67, 0.11));
    float threshold = 1.55;
    float knee = 0.28;
    float over = luma - threshold;
    float soft = clamp(over + knee, 0.0, 2.0 * knee);
    soft = (soft * soft) / (4.0 * knee);
    float response = max(over, 0.0) + soft;
    vec3 bright = color * response / max(luma, 1e-3);
    outColor = vec4(max(bright, vec3(0.0)), 1.0);
}
