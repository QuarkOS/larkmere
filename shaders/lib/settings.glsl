#ifndef LARKMERE_SETTINGS
#define LARKMERE_SETTINGS

// User options. Iris lists these in Shader Pack Settings.
// Every program includes this file so the defines stay identical.

#define VOLUMETRIC_LIGHT // Light shafts through leaves and low sun

const int shadowMapResolution = 2048; // [1024 2048 4096]
const float shadowDistance = 120.0;
const float shadowDistanceRenderMul = 1.0;
const float shadowIntervalSize = 2.0;
// Tilt the sun path so shadows stay long instead of vanishing at noon.
const float sunPathRotation = -15.0;
const bool shadowHardwareFiltering0 = false;
const bool shadowHardwareFiltering1 = false;

#define SHADOW_SOFTNESS 1.00 // [0.50 1.00 1.60]
#define VOL_STEPS 12 // [6 12 24]
#define BLOOM_STRENGTH 0.35 // [0.00 0.15 0.35 0.55 0.80]
#define FOG_DENSITY 1.00 // [0.40 0.70 1.00 1.40 1.80]

// Encoded in colortex2 blue. Values are exact in an 8-bit buffer.
const float MAT_TERRAIN = 0.20;
const float MAT_ENTITY = 0.40;
const float MAT_FOLIAGE = 0.60;
const float MAT_EMISSIVE = 0.80;
const float MAT_CLOUD = 1.00;

// block.properties ids.
const float ID_LEAVES = 100.0;
const float ID_PLANTS = 110.0;
const float ID_EMISSIVE = 200.0;
const float ID_LAVA = 210.0;
const float ID_ICE = 300.0;

#endif
