# Publish Checklist

## Repository

- [x] Plugin metadata in `plugin.rb` is correct (`name`, `about`, `version`, `authors`, `url`).
- [x] README includes installation, usage, settings, license.
- [x] README includes production operations notes (rate limit guidance and troubleshooting).
- [x] LICENSE file exists.
- [x] Repo is public.
- [x] No secrets, server IP credentials, or local absolute paths are committed.

## Testing

- [ ] Run plugin specs in a clean Discourse environment:
  - `bundle exec rspec plugins/discourse-facehash-avatars/spec`
- [ ] Run plugin acceptance tests in a clean Discourse environment:
  - `rake plugin:qunit['discourse-facehash-avatars']`
- [x] Verify avatars in staging:
  - topic list
  - post stream
  - user card/profile fallback
  - uploaded avatars still unchanged

## Documentation

- [ ] Publish Meta topic using `docs/META_TOPIC_TEMPLATE.md`.
- [ ] Replace Meta topic `TODO` in `README.md` with the live topic URL.
- [ ] Add screenshots to Meta topic.

## Release

- [ ] Tag release (`v0.5.7` or next).
- [x] Keep changelog in release notes (`CHANGELOG.md`).
- [ ] Monitor for regressions after rollout.
- [x] Verify global Discourse request limits are appropriate for your traffic profile.
