#version 330 compatibility
#include "/lib/sky.glsl"

uniform sampler2D colortex0;

in vec2 texcoord;

/* RENDERTARGETS: 3 */
layout(location = 0) out vec4 outColor;

void main() {
    vec3 color = texture(colortex0, texcoord).rgb;
    float luma = dot(color, vec3(0.22, 0.67, 0.11));
    // High threshold at noon so only the sun, lava, and hard glints bloom.
    // The knee drops when the sun is low and at night.
    float elev = max(sunElevation(), 0.0);
    float threshold = mix(0.92, 1.72, smoothstep(0.16, 0.62, elev));
    threshold = mix(threshold, 1.15, rainStrength * 0.5);
    float knee = 0.24;
    float over = luma - threshold;
    float soft = clamp(over + knee, 0.0, 2.0 * knee);
    soft = (soft * soft) / (4.0 * knee);
    float response = max(over, 0.0) + soft;
    vec3 bright = color * response / max(luma, 1e-3);
    outColor = vec4(max(bright, vec3(0.0)), 1.0);
}
