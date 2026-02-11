# discourse-facehash-avatars

A production-oriented Discourse plugin that replaces default avatars with deterministic Facehash-style avatars.

Users with uploaded profile pictures are not affected.

## What it does

- Replaces core default letter avatars with deterministic Facehash avatars.
- Keeps uploaded avatars unchanged.
- Serves generated avatars from a local Discourse route as `image/svg+xml`.
- Uses immutable CDN-friendly caching (`1 year`) with settings-based versioning.
- Supports `ETag`/`304 Not Modified` conditional requests for browser/proxy efficiency.
- Supports configurable palette, initial visibility, and gradient vs solid mode.

## Install

Add this plugin repo to your Discourse `app.yml`:

```yml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/devatnull/facehash-discourse.git
```

Then rebuild:

```bash
./launcher rebuild app
```

## Settings

- `facehash_avatars_enabled` (default: `true`)
- `facehash_avatars_gradient_overlay` (default: `true`)
- `facehash_avatars_show_initial` (default: `true`)
- `facehash_avatars_hash_source` (default: `username`)  
  Allowed values: `username`, `name`, `name_or_username`
- `facehash_avatars_palette` (default: `#ec4899|#f59e0b|#3b82f6|#f97316|#10b981`)

Palette accepts pipe, comma, whitespace, or newline separators.

## Avatar URL shape

When enabled, users without uploaded avatars resolve to:

```text
/facehash_avatar/:username/{size}/:version.svg
```

`version` changes when plugin display settings change, allowing safe cache busting.

## Test

Run plugin specs inside your Discourse dev/test environment:

```bash
bundle exec rspec plugins/facehash-discourse/spec
```

## Notes

- This plugin intentionally overrides `User.default_template` so all default avatar fallbacks use Facehash.
- If the plugin is disabled, core avatar behavior resumes.
- When `facehash_avatars_hash_source` is set to `name`/`name_or_username`, the avatar seed is derived from `User#name` when available.
- Name-based seed lookups are cached and invalidated when a user is updated.
- Username parsing/validation follows Discourse's `UsernameValidator`, so valid forum usernames are supported while unsafe/invalid path input is rejected.
