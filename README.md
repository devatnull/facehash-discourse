# discourse-facehash-avatars

Deterministic Facehash avatars for Discourse default avatar slots.

This plugin replaces Discourse default avatars for users without an uploaded profile picture. Users with uploaded avatars are unchanged.

## Official Links

- Repository: https://github.com/devatnull/facehash-discourse
- Meta topic: TODO (add after publishing on Meta)
- Changelog: `CHANGELOG.md`

## Installation

Follow the official Discourse plugin installation guide:
- https://meta.discourse.org/t/install-a-plugin/19157

### Docker Launcher (`app.yml`)

Add the plugin clone command under `hooks -> after_code`:

```yml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/devatnull/facehash-discourse.git discourse-facehash-avatars
```

Then rebuild:

```bash
cd /var/discourse
./launcher rebuild app
```

### Docker Compose (custom deployments)

1. Clone the plugin on the host:

```bash
mkdir -p plugins
git clone https://github.com/devatnull/facehash-discourse.git plugins/discourse-facehash-avatars
```

2. Mount it into the Discourse container:

```yml
services:
  discourse:
    volumes:
      - ${DISCOURSE_DATA_PATH}:/shared
      - ./plugins/discourse-facehash-avatars:/var/www/discourse/plugins/discourse-facehash-avatars
```

3. Recreate the Discourse service:

```bash
docker compose --env-file discourse/.env up -d --force-recreate discourse
```

## How To Use

1. Go to `Admin -> Settings`.
2. Search for `facehash_avatars`.
3. Configure settings below.

## Settings

| Setting | Default | Description |
| --- | --- | --- |
| `facehash_avatars_enabled` | `true` | Enable Facehash avatars for default avatar fallback. |
| `facehash_avatars_gradient_overlay` | `true` | Use gradient style (off = solid style). |
| `facehash_avatars_show_initial` | `true` | Show initial character on avatar. |
| `facehash_avatars_inline_render` | `true` | Inline render Facehash SVG in browser for reliable animation/interactions. |
| `facehash_avatars_hover_effect` | `true` | Enable subtle hover interaction on inline-rendered avatars. |
| `facehash_avatars_force_non_center_interactive_tilt` | `true` | If the deterministic pose is center (`0,0`), use a deterministic non-center interactive tilt so hover feedback remains visible. |
| `facehash_avatars_enable_blink` | `false` | Enable deterministic blink animation on face marks. |
| `facehash_avatars_blink_interval_seconds` | `8` | Blink loop interval in seconds (clamped to 2..30). |
| `facehash_avatars_blink_duration_ms` | `140` | Blink close/open duration in milliseconds (clamped to 80..2000). |
| `facehash_avatars_shape` | `round` | Avatar mask shape: `round`, `squircle`, or `square`. |
| `facehash_avatars_font_family` | `system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif` | Initial text `font-family` used in SVG output. |
| `facehash_avatars_font_weight` | `600` | Initial text `font-weight` (`100`..`900` or `normal/bold`). |
| `facehash_avatars_auto_foreground_contrast` | `true` | Auto-select black/white foreground for legibility. |
| `facehash_avatars_foreground_color` | `#111827` | Manual foreground color when auto contrast is disabled. |
| `facehash_avatars_hash_source` | `username` | Seed source: `username`, `name`, `name_or_username`. |
| `facehash_avatars_palette` | `#0f766e|#0ea5a4|#2563eb|#4f46e5|#9333ea|#be185d|#ea580c|#ca8a04|#15803d|#334155` | Color palette (pipe/comma/space/newline separated hex values). |

## Behavior

- Route shape: `/facehash_avatar/:username/{size}/:version.svg`
- Response type: `image/svg+xml`
- Cache: `immutable` 1-year cache with `ETag` support
- Uploaded avatars: unchanged

## Security And Validation

- Username parsing/validation is aligned with Discourse `UsernameValidator`.
- Invalid username payloads fall back safely to the core blank avatar image.
- Name-based hash source lookups are cached and invalidated on user updates.

## Compatibility Notes

- Compatible with valid Discourse usernames (including dotted usernames).
- For stable plugin identity, mount/clone into `discourse-facehash-avatars` directory.

## Production Ops

Facehash avatars are generated dynamically and then cached aggressively. On instances with strict global request throttling, admin sessions (especially with browser DevTools source maps enabled) can burst enough requests to trigger temporary `429` blocks.

If needed, tune Discourse global limits using your deployment config:

```env
DISCOURSE_MAX_REQS_PER_IP_PER_10_SECONDS=120
DISCOURSE_MAX_REQS_PER_IP_PER_MINUTE=1200
DISCOURSE_MAX_ASSET_REQS_PER_IP_PER_10_SECONDS=1000
DISCOURSE_MAX_REQS_PER_IP_MODE=block
```

Docker Compose note:
- Ensure these variables are present in `.env`.
- Ensure they are also passed in `docker-compose.yml` under the `discourse.environment` list.

## Known Scope

- Replaces only default fallback avatars.
- Does not modify uploaded user profile pictures.
- Avatars stay deterministic by design (same seed always returns the same avatar).
- `facehash_avatars_palette` is a deterministic color pool. Each user maps to a stable color from that pool.
- Client-side inline render mode is enabled by default so hover/blink interactions can run in the browser on Facehash fallback avatars.

## Testing

Run inside a Discourse checkout:

```bash
bundle exec rspec plugins/discourse-facehash-avatars/spec
```

## Meta Topic

Use this template to publish your official Meta topic:
- `docs/META_TOPIC_TEMPLATE.md`

After posting, replace `TODO` in the **Official Links** section above with the live Meta URL.

## License

MIT
