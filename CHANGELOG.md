# Changelog

All notable changes to this project are documented in this file.

## [0.5.20] - 2026-02-11

### Added

- Bundled official `GeistPixel-Square.woff2` font asset (SIL OFL 1.1).
- New font delivery endpoint: `/facehash_avatar/font/GeistPixel-Square.woff2` with immutable caching and ETag.
- Third-party font license file: `licenses/third_party/Geist-OFL-1.1.txt`.

### Changed

- Avatar SVG output now includes `@font-face` mapping for bundled Geist Pixel when rendering initials, so the pixel font is available consistently across devices without requiring local font installation.
- Default `facehash_avatars_font_family` now prefers bundled Geist Pixel with monospace fallbacks.

## [0.5.21] - 2026-02-12

### Fixed

- Fixed `facehash_avatars_palette` parsing for list settings so uppercase hex values (and list storage formats) do not incorrectly fall back to defaults.

### Changed

- Updated default `facehash_avatars_palette` to a broader 16-color saturated palette.

## [0.5.19] - 2026-02-11

### Fixed

- Fixed tiny-avatar regression in non-header contexts by anchoring overlays to the actual image box (`offsetLeft/offsetTop/offsetWidth/offsetHeight`) instead of parent container bounds.
- Restored hover trigger compatibility with image-adjacent overlay structure.
- Added resize resync so overlay geometry stays aligned after layout changes.

## [0.5.18] - 2026-02-11

### Fixed

- Fixed double-face stacking regression by hiding the original Facehash `<img>` only after overlay mount succeeds.
- Restores fallback visibility automatically when overlay is removed or rebuilds.

## [0.5.17] - 2026-02-11

### Fixed

- Fixed inline overlay placement so Facehash avatars stay aligned in all contexts (post stream left column, topic lists, header/user menu) without horizontal overflow.
- Switched overlay mounting from sibling negative-margin strategy to host-anchored absolute overlay strategy.
- Restored hover interaction trigger by binding hover to the avatar host container.

## [0.5.16] - 2026-02-11

### Fixed

- Restored face-level hover interactions using a non-destructive inline overlay strategy.
- Keeps original Ember/Glimmer-managed avatar `<img>` nodes in place (no reparenting/replacement), avoiding `NotFoundError: removeChild` rerender conflicts.
- Added overlay lifecycle cleanup/re-sync logic for dynamic post stream updates.
- Preserved deterministic interactive tilt behavior, including non-center fallback for center-pose avatars.
- Keeps deprecated `Discourse.SiteSettings` access out of runtime path.

## [0.5.15] - 2026-02-11

### Fixed

- Reworked inline runtime to use a non-destructive enhancement mode:
  - removed avatar `<img>` node reparenting/replacement behavior
  - removed duplicate client-side fetch/parsing of avatar SVG URLs
- Prevents Glimmer/Ember DOM ownership conflicts (`NotFoundError: removeChild`) seen in post stream rerenders.
- Removed deprecated client setting access path (`Discourse.SiteSettings`) from runtime usage.

## [0.5.14] - 2026-02-11

### Fixed

- Removed Discourse topic-list/poster border/box-shadow/outline ring styles from Facehash inline wrappers.
- Prevents visible frame artifacts in preview/poster cells while preserving avatar rendering behavior.

## [0.5.13] - 2026-02-11

### Fixed

- Preserved original avatar border radius on inline wrapper elements.
- Prevents square focus/active border rings around round Facehash avatars in topic list/poster preview cells.

## [0.5.12] - 2026-02-11

### Fixed

- Switched tiny inline avatars (<= 28px) from 3D transform interaction to 2D micro-shift interaction.
- This removes remaining square-plane artifacts seen in preview/poster contexts across browsers (including Chrome/Safari).

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
