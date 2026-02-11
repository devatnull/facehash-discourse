# discourse-facehash-avatars

Plugin repo: https://github.com/devatnull/facehash-discourse

## Summary

`discourse-facehash-avatars` replaces Discourse default avatars with deterministic Facehash avatars for users who do not have an uploaded profile picture.

Uploaded profile pictures are not changed.

## Why Use This Plugin

- Deterministic avatars without external avatar APIs
- Works for all default avatar contexts using Discourse avatar templates
- Lightweight SVG responses with cache-friendly headers

## Installation

Follow the official plugin installation guide:
https://meta.discourse.org/t/install-a-plugin/19157

### Docker Launcher

Add to `app.yml`:

```yml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/devatnull/facehash-discourse.git discourse-facehash-avatars
```

Rebuild:

```bash
./launcher rebuild app
```

### Docker Compose

Mount plugin into Discourse container:

```yml
services:
  discourse:
    volumes:
      - ${DISCOURSE_DATA_PATH}:/shared
      - ./plugins/discourse-facehash-avatars:/var/www/discourse/plugins/discourse-facehash-avatars
```

Recreate service:

```bash
docker compose --env-file discourse/.env up -d --force-recreate discourse
```

## Settings

- `facehash_avatars_enabled`
- `facehash_avatars_gradient_overlay`
- `facehash_avatars_show_initial`
- `facehash_avatars_hash_source` (`username`, `name`, `name_or_username`)
- `facehash_avatars_palette`

## Technical Notes

- Avatar route: `/facehash_avatar/:username/{size}/:version.svg`
- MIME type: `image/svg+xml`
- Caching: immutable + ETag/304 support
- Username validation follows Discourse core `UsernameValidator`

## Screenshots

Add screenshots here:

1. Topic list with generated default avatars
2. Post stream with generated default avatars
3. User card/profile fallback avatar
4. Admin settings page (`facehash_avatars_*`)

## Troubleshooting

- If avatars look missing after rollout, hard refresh browser cache.
- Ensure plugin directory inside container is `plugins/discourse-facehash-avatars`.
- Check Discourse logs for plugin load errors on boot.

## Support

Post issues and bug reports in this topic or GitHub issues:
https://github.com/devatnull/facehash-discourse/issues

## License

MIT
