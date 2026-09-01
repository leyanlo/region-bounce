# RegionBounce

RegionBounce is a native macOS screen saver where moving particles reshape a map of connected color territories. Each particle carries its starting region's color, rebounds from foreign boundaries, and gradually converts cells after repeated impacts.

Every world starts from randomly placed seeds that grow into connected, irregular regions. The result is less like a random checkerboard and more like a tiny evolving map.

![RegionBounce preview](docs/region-bounce.webp)

## Features

- Native universal `arm64` and `x86_64` `.saver` bundle
- Standalone preview app with **World → New World** (`⌘N`) and full-screen mode
- Connected random starting regions generated with randomized multi-source growth
- Four palettes: Earth, Sorbet, Ocean, and Monochrome
- Screen saver settings for regions, particles, grid size, conversion resistance, speed, automatic reseeding, and particle visibility
- Deterministic, platform-independent C++ simulation with connectivity and lifecycle tests
- Silent operation, suitable for a screen saver

## Build

RegionBounce requires macOS 12 or newer, Xcode command-line tools, and CMake 3.21 or newer.

```sh
./scripts/build-release.sh
```

This builds and tests both bundles, ad-hoc signs them for local use, verifies their signatures, and creates `dist/RegionBounce-macOS.zip`.

To run the preview app:

```sh
open build-release/RegionBounce.app
```

To install the screen saver, open `build-release/RegionBounce.saver` in Finder or double-click it and let macOS add it to **System Settings → Screen Saver**. Local ad-hoc signing is intended for development; downloadable releases should be Developer ID signed and notarized.

## How it works

1. Random seed cells are assigned distinct region identities.
2. A randomized frontier grows each seed one neighboring cell at a time. Every resulting starting region is connected.
3. Particles spawn inside the completed map and inherit the region beneath them.
4. A particle bounces when its leading edge encounters another region and applies one impact to that boundary cell.
5. Once the cell's resistance is exhausted, it switches ownership. The contested square drawn inside a cell shows conversion progress.
6. The world is regenerated after the configured interval.

## Inspiration

The interaction is inspired by [Keef U's 2021 Bounceorama experiment](https://x.com/keef_u/status/1390274784882085889), which in turn credited [@jagarikin](https://x.com/jagarikin/status/1388660839205326851). RegionBounce is an independent native implementation with a connected-region generator and no source-code dependency on the web experiment.

## License

[MIT](LICENSE)
