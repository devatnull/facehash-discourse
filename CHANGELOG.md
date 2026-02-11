# Changelog

All notable changes to this project are documented in this file.

## [0.5.11] - 2026-02-11

### Fixed

- Disabled `perspective` on tiny inline avatars (<= 28px) to avoid residual square 3D plane artifacts in Safari/WebKit preview contexts.

## [0.5.10] - 2026-02-11

### Fixed

- Corrected small-avatar safety path detection by using resolved avatar size during inline wrapper build.
- 24px poster avatars now correctly receive reduced motion depth (`translateZ: 0`) instead of full depth.

## [0.5.9] - 2026-02-11

### Fixed

- Reduced Safari/WebKit square-plane artifacts around small (e.g. 24px) inline avatars by:
  - using `translateZ(0)` for small avatars in interactive mode
  - lowering rotation range for small avatars
  - removing SVG `preserve-3d` transform style on the face layer
  - enabling overflow clipping and backface hiding on inline avatar wrappers

## [0.5.8] - 2026-02-11

### Added

- Rails engine/autoloading structure:
  - `lib/facehash_discourse/engine.rb`
  - root `::FacehashDiscourse::PLUGIN_NAME` declaration in `plugin.rb`
- Plugin acceptance test scaffold:
  - `test/javascripts/acceptance/facehash-inline-avatar-runtime-test.js`

### Changed

- Removed explicit `require_relative` loading of plugin Ruby classes now covered by autoloading.
- Expanded README testing section with plugin QUnit command.

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
