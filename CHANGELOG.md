# Changelog

All notable changes to this project are documented in this file.

## [0.5.7] - 2026-02-11

### Added

- New site setting: `facehash_avatars_force_non_center_interactive_tilt` (client setting, default `true`).
- Docs updates for publish readiness:
  - direct Meta topic placeholder in `README.md`
  - updated Meta topic template with the new setting and suggested defaults
  - this changelog file

### Changed

- Center-pose avatars (`0,0`) now use deterministic non-center interactive tilt when the new setting is enabled, preserving visible hover feedback.

## [0.5.6] - 2026-02-11

### Changed

- Improved hover consistency by ensuring center-slot avatars still show motion feedback.

## [0.5.5] - 2026-02-11

### Changed

- Hover transform now targets face layer only (not full SVG/image wrapper), matching Facehash interaction model more closely.
- Removed dead `intensity_3d` plumbing.

## [0.5.4] - 2026-02-11

### Changed

- Updated inline avatar runtime and interaction behavior.

