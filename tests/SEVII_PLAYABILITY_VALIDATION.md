# Sevii playability validation

Production causes are separated into five stacked review branches: camera/save preference, arrival briefing, rescued crew clearance, canonical species metadata, and native animation compositions. This QA change retains real native navigation, waits for actual scene readiness, chooses healthy replacements through native menus, and fills the native Bag with ordinary registered item stacks when testing deferred rewards. Fixtures are explicitly declared; they do not prove game balance.

Shared screenshots, measured audits and exact Kanto comparisons are in the VASC review branch `codex/sevii-validation-20261008`, under `tests/evidence/sevii-playability-20261008`. Each cause PR links the relevant before/after receipts. The continuing optional-event sweep is reported separately from the completed seven-chapter main-story checks.

Keep isolated `POKEPORT_IDENTITY` profiles ending in `-qa`. Use the complete matching mod packages, including ignored local assets. Set `SEVII_KASC_ROOT` and `SEVII_QA_OUTPUT` before running a native driver through the unchanged engine's `POKEPORT_DRIVER` entry point. A zero process exit alone is insufficient: require the driver's explicit final PASS and persisted completion receipt, because closing a LÖVE window can also return zero.
