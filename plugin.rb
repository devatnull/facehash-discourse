# frozen_string_literal: true

# name: discourse-facehash-avatars
# about: Replaces Discourse default avatars with deterministic Facehash avatars for users without uploaded profile pictures.
# version: 0.5.19
# authors: devatnull
# url: https://github.com/devatnull/facehash-discourse

module ::FacehashDiscourse
  PLUGIN_NAME = "discourse-facehash-avatars"
end

require_relative "lib/facehash_discourse/engine"
require_relative "lib/facehash_discourse/version"

enabled_site_setting :facehash_avatars_enabled
register_asset "stylesheets/common/facehash-inline-avatars.scss"

module ::FacehashDiscourse
  RUNTIME_INLINE_AVATAR_SCRIPT =
    File.read(File.expand_path("assets/runtime/facehash-inline-avatars-runtime.js", __dir__)).freeze
end

register_html_builder("server:before-head-close") do |controller|
  next "" unless SiteSetting.facehash_avatars_enabled
  next "" unless SiteSetting.facehash_avatars_inline_render

  <<~HTML
    <script nonce='#{controller.helpers.csp_nonce_placeholder}'>
    #{::FacehashDiscourse::RUNTIME_INLINE_AVATAR_SCRIPT}
    </script>
  HTML
end

after_initialize do
  require_dependency "user"

  module ::FacehashDiscourse
    class << self
      def avatar_template(username)
        normalized_username = User.normalize_username(username.to_s)
        normalized_username = "unknown" if normalized_username.blank?

        encoded_username = UrlHelper.encode_component(normalized_username)

        "#{Discourse.base_path}/facehash_avatar/#{encoded_username}/{size}/#{settings_version}.svg"
      end

      def settings_version
        Config.settings_version
      end

      def avatar_seed_cache_key(username_lower:, hash_source:, names_enabled_key:)
        +"facehash-discourse/avatar-seed/#{PLUGIN_VERSION}/#{hash_source}/#{names_enabled_key}/#{username_lower}"
      end

      def clear_avatar_seed_cache(username)
        username_lower = username.to_s.downcase
        return if username_lower.blank?

        Config::ALLOWED_HASH_SOURCES.each do |hash_source|
          next if hash_source == "username"

          %w[1 0 na].each do |names_enabled_key|
            Discourse.cache.delete(
              avatar_seed_cache_key(
                username_lower: username_lower,
                hash_source: hash_source,
                names_enabled_key: names_enabled_key,
              ),
            )
          end
        end
      end
    end
  end

  module ::FacehashDiscourse
    module UserDefaultTemplatePatch
      def default_template(username)
        return super unless SiteSetting.facehash_avatars_enabled

        ::FacehashDiscourse.avatar_template(username)
      end
    end
  end

  if !(User.singleton_class < ::FacehashDiscourse::UserDefaultTemplatePatch)
    User.singleton_class.prepend(::FacehashDiscourse::UserDefaultTemplatePatch)
  end

  if !defined?(::FacehashDiscourse::SEED_CACHE_HOOK_REGISTERED)
    DiscourseEvent.on(:user_updated) do |user|
      next if user.blank?

      ::FacehashDiscourse.clear_avatar_seed_cache(user.username_lower || user.username)
    end

    ::FacehashDiscourse.const_set(:SEED_CACHE_HOOK_REGISTERED, true)
  end

  Discourse::Application.routes.append do
    get "/facehash_avatar/:username/:size/:version.svg",
        to: "facehash_discourse/avatars#show",
        constraints: {
          username: /[^\/]+/,
          size: /\d+/,
          version: /[A-Za-z0-9_-]+/,
        }
  end
end
