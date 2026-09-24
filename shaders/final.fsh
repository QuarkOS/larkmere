#version 330 compatibility
#include "/lib/tonemap.glsl"
#include "/lib/sky.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex3;

in vec2 texcoord;

// Final writes the backbuffer, not a colortex.
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 fragColor;

void main() {
    vec3 color = texture(colortex0, texcoord).rgb;
    vec3 bloom = texture(colortex3, texcoord).rgb;
    color += bloom * BLOOM_STRENGTH;
    color = gradeAndTonemap(
        color,
        rainStrength,
        thunderStrength,
        daylightFactor(),
        blueHourFactor(),
        nightVision,
        blindness,
        darknessFactor
    );
    fragColor = vec4(color, 1.0);
}
