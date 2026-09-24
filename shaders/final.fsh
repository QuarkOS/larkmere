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

    float elev = sunElevation();
    float noon = smoothstep(0.28, 0.68, max(elev, 0.0));
    float lowSun = smoothstep(-0.02, 0.12, elev) * (1.0 - smoothstep(0.16, 0.46, elev));
    float bloomGain = mix(0.68, 1.20, clamp(lowSun, 0.0, 1.0));
    bloomGain = mix(bloomGain, 0.40, noon);
    bloomGain *= mix(1.0, 0.55, rainStrength);
    color += bloom * BLOOM_STRENGTH * bloomGain;

    color = gradeAndTonemap(
        color,
        rainStrength,
        thunderStrength,
        daylightFactor(),
        goldenFactor(),
        blueHourFactor(),
        nightVision,
        blindness,
        darknessFactor
    );
    fragColor = vec4(color, 1.0);
}
