# Publish Checklist

## Repository

- [ ] Plugin metadata in `plugin.rb` is correct (`name`, `about`, `version`, `authors`, `url`).
- [ ] README includes installation, usage, settings, license.
- [ ] LICENSE file exists.
- [ ] Repo is public.

## Testing

- [ ] Run plugin specs in a Discourse environment:
  - `bundle exec rspec plugins/discourse-facehash-avatars/spec`
- [ ] Verify avatars in staging:
  - topic list
  - post stream
  - user card/profile fallback
  - uploaded avatars still unchanged

## Documentation

- [ ] Publish Meta topic using `docs/META_TOPIC_TEMPLATE.md`.
- [ ] Add Meta topic link to `README.md`.
- [ ] Add screenshots to Meta topic.

## Release

- [ ] Tag release (`v0.1.0` or next).
- [ ] Keep changelog in release notes.
- [ ] Monitor for regressions after rollout.
