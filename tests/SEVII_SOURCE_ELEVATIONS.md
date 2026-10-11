# Sevii source movement elevations

Original FRLG movement elevations are discrete collision labels, not physical world heights. The importer now preserves every original nibble in compact native-cell rows. Revision 8 requires a valid owned adapter; malformed or absent rows fail explicitly instead of silently weakening collisions. Revision 6/7 fixtures retain their existing compatibility path.

The movement hook only narrows an already allowed collision result. It rejects unequal nonzero movement labels, preserving source/destination 0 and destination 15 exceptions. Native admitted directional stair warps and surfing onto bank label 3 preserve their existing target, occupancy and dismount decisions. Original source elevation 15 retains previous actor state in FRLG; the independent oracle establishes that this imported region contains no traversable label-15 cells. This implementation therefore does not claim a general solution for regions with traversable label 15.

Native connection crossings bypass `movement.collision`. A mod-owned wrapper checks the actual connection landing before the host mutates map or actor state. Foreign maps retain the exact original crossing call. Rows and warp lookup tables are prepared once; movement checks create no tables. Engine source files are unchanged.

References: [IsElevationMismatchAt / ObjectEventUpdateElevation](https://github.com/pret/pokefirered/blob/master/src/event_object_movement.c), [CheckForPlayerAvatarCollision / CanStopSurfing](https://github.com/pret/pokefirered/blob/master/src/field_player_avatar.c). Host directional stair entry is deliberately adapted to the native Gen1 stepping convention; this does not recreate all FRLG engine behavior.

## Repeatable checks

`sevii_source_elevation_test.lua` checks compatible labels, stair/Surf exceptions, existing blocked results, strict metadata, foreign maps and one-time connection wrapping. `sevii_source_elevation_oracle.py` independently decodes the authenticated BPRD source, source-layout overrides and authored cell-copy overrides. Its output contains metadata only: no ROM, source pixels, savegame or NAS log is committed.

`sevii_source_elevation_native_driver.lua` loads the oracle through `SEVII_ELEVATION_ORACLE`; `SEVII_ELEVATION_FIXED=1` requires exact labels and no mismatches, and `SEVII_ELEVATION_CAMERA=0/1` selects 2D/Voxel. Set a dedicated `vasc-sevii-...-qa` identity and `HABITAT_QA_ROOT`. The driver covers all 266 maps / 73,868 labels, 2,022 eligible differing-label local transitions, 1,406 passable dry connection landings, five real blocked-direction inputs, a rock-stair traversal and the admitted Center stair warp. It uses QA teleports, a prepared champion/team and disabled encounters. Native ZIP receipts, screenshots and completion markers are kept under `evidence/sevii-source-elevations-20261008`.

The journey navigator uses the collision/crossing verdict when planning. The completed regression retained a QA helper initialization gap for local edges: the continuous driver initializes its own game instead of calling Q.setup, so Q.K was unset. Actual blocked inputs were logged and replanned through legitimate routes; the helper now also resolves the current mod export without Q.setup. This QA correction does not alter production physics or invalidate actual completed movement receipts. Continuous seven-island regression runs separately use actual inputs, ferries, per-island save/load and return to Orania. Initial champion/team and disabled encounters remain explicit fixtures; this is not a travel resource-balance test.

## Scope still open

This fix restores movement topology. It does not certify every geometry surface, camera/settings combination, original Android transition, optional follower sheet or Groudon wing/provider state. Center furniture and descending stair support differences from the separate geometry probe remain REVIEW. Historical completed receipts remain attached to their actual ZIP versions; they are not relabelled as new runs.
