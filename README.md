# Larkmere

An original Iris shader pack for Minecraft Java **1.21.11**. The look is a quiet valley: pewter mist that thickens with distance, long soft shadows, warm light when the sun is low, and water that holds the sky.

It is not a cartoon pack and not a neon pack. Shadows stay cool. Noon is clear rather than yellow. Rain darkens the air and the ground. Nights stay readable.

## Requirements

- Minecraft Java **1.21.11**
- [Iris](https://irisshaders.dev/) and [Sodium](https://modrinth.com/mod/sodium)

OptiFine is not supported. The pack uses Iris program order and Iris uniforms (`hasSkylight`, `thunderStrength`, translucent entity splits).

Resource pack format is **75.0** (`min_format` / `max_format` `[75, 0]`), which is the resource-pack format in Minecraft 1.21.11's `version.json`.

## Install

1. Install Iris and Sodium on a 1.21.11 instance.
2. Copy this folder into your `shaderpacks` directory, or zip the repository root and drop the zip there.
3. The zip root must contain `pack.mcmeta` and `shaders/` directly. Do not wrap them in an extra folder.
4. In Minecraft: Options → Video Settings → Shader Packs → **Larkmere**.

Default options are the Balanced look. In shader settings you can also pick Fast or Cinematic.

| Option | What it changes |
| --- | --- |
| Shadow resolution | 1024, 2048, or 4096. Default 2048. |
| Shadow softness | Width of the soft shadow edge. |
| Volumetric light | Shafts from the shadow map. On by default. |
| Volumetric steps | 6, 12, or 24 samples along each ray. |
| Bloom strength | Halo on the sun, lava, and other bright surfaces. |
| Fog density | How fast valley mist and distance haze build up. |

## Pipeline

The pack is a small deferred path. Shared code lives in `shaders/lib/`.

1. **Shadow.** The world is drawn from the sun or moon into a shadow map. Leaves cut out. Water, rain, and the hand do not. A little distortion spends more texels near the camera. Shadows are an 8-tap soft sample.
2. **Gbuffers.** Terrain, entities, and block entities write albedo, a view-space normal, and lightmap / material into `colortex0`–`colortex2`. The sky, sun, moon, and clouds are shaded on their own.
3. **Deferred.** One fullscreen pass lights opaque pixels: warm sun or cool moon, blue-gray sky fill, warm block light, wet surfaces in rain, then aerial perspective. The lit image is copied to `colortex5`.
4. **Water.** Runs after deferred. Refraction reads `colortex5` (gbuffers cannot sample `colortex0`–`3`). Absorption, a short screen-space reflection, and a sky fallback sit under a Fresnel mix. Rain raises the chop. Lava is emissive. Ice is a harder, clearer surface. Other translucents tint the scene behind them.
5. **Composite.** If volumetric light is on, a short ray march through the shadow map adds shafts, mostly in forests and toward a low sun. Three more passes extract and blur bloom at half resolution.
6. **Final.** Bloom is added, rain and thunder settle the grade, and a filmic curve plus gamma writes the frame.

`sunPathRotation` is -15° so shadows stay long at midday.

## Limits

This environment cannot launch Minecraft, so the pack has not been seen in game. File layout, option names, include paths, and GLSL syntax were checked offline.

- Reflections are a few screen-space steps and then the sky. They miss anything off screen.
- No caustics, parallax, or temporal anti-aliasing.
- Volumetric light is a short march, not a froxel volume. It is off in the Nether and the End.
- The Nether and the End get their own ambient color and fog, not overworld sun shafts.
- Beacon beams keep a bright core. The soft vanilla halo is not rebuilt.
- Enchantment glint is added onto the item before lighting, so it stays subtle.
- Foliage sway moves the whole sprite a little, including the base.
- `separateEntityDraws` is set so translucent entities and block entities can light after deferred. On Iris versions where that split is ignored, those objects fall back to the forward shaders whenever Iris still routes them there.
