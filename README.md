# discourse-facehash-avatars

Deterministic Facehash avatars for Discourse default avatar slots.

This plugin replaces Discourse default avatars for users without an uploaded profile picture. Users with uploaded avatars are unchanged.

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
| `facehash_avatars_hash_source` | `username` | Seed source: `username`, `name`, `name_or_username`. |
| `facehash_avatars_palette` | `#ec4899|#f59e0b|#3b82f6|#f97316|#10b981` | Color palette (pipe/comma/space/newline separated hex values). |

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

## Testing

Run inside a Discourse checkout:

```bash
bundle exec rspec plugins/discourse-facehash-avatars/spec
```

## Meta Topic

Use this template to publish your official Meta topic:
- `docs/META_TOPIC_TEMPLATE.md`

After posting, add the Meta topic link here.

## License

MIT
