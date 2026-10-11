# Authenticated Sevii source animations

The static BPRD importer omitted visible source animation on 42 original maps / 135 runtime fragments. The exporter now authenticates the German revision-0 ROM, frame pointer tables, callback references and complete frame-bank hashes before composing both original metatile layers, flips and palettes. Water, sand, flowers and steam use the native 640-tick wrapping clock. No new map, atlas slot, warp, flag or variable IDs are assigned.

Generated PNGs remain private and ignored. The exact ROM, saves and raw animation banks must not be committed. Static map definitions, other tileset fields and existing static PNG bytes must equal the frozen baseline.

From the repository root, with a legally available private BPRD ROM and Python/Pillow:

```sh
python3 scripts/import_sevii_bprd.py "$SEVII_PRIVATE_ROM" --output "$SEVII_EXPORT"
python3 tests/sevii_source_animation_oracle.py --importer scripts/import_sevii_bprd.py --rom "$SEVII_PRIVATE_ROM" --export "$SEVII_EXPORT" --baseline "$SEVII_FROZEN_EXPORT" --output "$SEVII_PROOF_JSON"
```

The independent oracle replays the last callback update by walking backward in the wrapping counter, then invokes the original static compositor with patched VRAM. It checks all 7,227 distinct visible states, including flipped tiles and secondary palettes, and 58 foreground underlays. The loader checks native PNG decoding, 8/16-pixel dimensions, source ownership, slots and sequences before registration. A corrupt frame rejects the mod explicitly with map, tile and asset context; it cannot silently become a static tile.

On native gen1recomp 0.3.61 / LÖVE 11.5, the paired VASC drivers in `tests/sevii_native_*animation*_driver.lua` verify actual 2D TileRenderer output, GPU atlas composition, foreground cell placement, complete animation cycles without new GPU/pixel resources, ownership and eviction. The source renderer is admitted only for authenticated KASC Sevii tilesets. Existing Kanto clock and material paths remain unchanged.

Desktop proof covers 266 definitions, 135 animated tilesets, 3,176 native streams and 36,443 claimed slots. It does not establish Android FPS, the original Adreno 830 transition timeout, every camera angle, or authentic missing follower artwork. Main-story/optional-event proofs retain their documented fixtures and scope.
