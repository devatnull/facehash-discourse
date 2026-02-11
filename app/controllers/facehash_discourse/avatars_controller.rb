# frozen_string_literal: true

require "digest"

module ::FacehashDiscourse
  class AvatarsController < ::ApplicationController
    requires_plugin ::FacehashDiscourse::PLUGIN_NAME

    skip_before_action :preload_json,
                       :redirect_to_login_if_required,
                       :redirect_to_profile_if_required,
                       :check_xhr,
                       :verify_authenticity_token,
                       only: %i[show]

    before_action :apply_cdn_headers, only: %i[show]

    MIN_SIZE = 8
    MAX_SIZE = 1000
    MAX_USERNAME_LENGTH = 200

    def show
      is_asset_path
      no_cookies

      return render_blank unless SiteSetting.facehash_avatars_enabled
      requested_username = params[:username].to_s
      return render_blank if requested_username.blank? || requested_username.length > MAX_USERNAME_LENGTH

      size = params[:size].to_i
      return render_blank if size < MIN_SIZE || size > MAX_SIZE

      avatar_seed = avatar_seed_for(requested_username)
      immutable_for(1.year)
      return unless stale?(etag: avatar_etag(requested_username, avatar_seed, size), public: true)

      image =
        ::FacehashDiscourse::AvatarRenderer.new(
          name: avatar_seed,
          size: size,
          variant: ::FacehashDiscourse::Config.variant,
          show_initial: ::FacehashDiscourse::Config.show_initial?,
          colors: ::FacehashDiscourse::Config.colors,
        ).to_svg

      response.headers["X-Content-Type-Options"] = "nosniff"
      response.headers["Content-Length"] = image.bytesize.to_s
      render plain: image, content_type: "image/svg+xml"
    rescue StandardError => e
      Rails.logger.warn(
        "[#{::FacehashDiscourse::PLUGIN_NAME}] Failed to render avatar for username=#{params[:username]} size=#{params[:size]} version=#{params[:version]}: #{e.class}: #{e.message}",
      )
      render_blank
    end

    private

    def avatar_etag(requested_username, avatar_seed, size)
      payload =
        [
          ::FacehashDiscourse::Config.settings_version,
          requested_username.downcase,
          avatar_seed,
          size,
        ].join("|")

      Digest::SHA1.hexdigest(payload)
    end

    def avatar_seed_for(requested_username)
      hash_source = ::FacehashDiscourse::Config.hash_source
      return requested_username if hash_source == :username

      username_key = requested_username.downcase
      names_enabled_key =
        if SiteSetting.respond_to?(:enable_names)
          SiteSetting.enable_names ? "1" : "0"
        else
          "na"
        end
      cache_key =
        ::FacehashDiscourse.avatar_seed_cache_key(
          username_lower: username_key,
          hash_source: hash_source,
          names_enabled_key: names_enabled_key,
        )

      Discourse.cache.fetch(cache_key, expires_in: 1.hour) do
        user = find_user_by_username(requested_username)
        next requested_username if user.blank?
        next requested_username if SiteSetting.respond_to?(:enable_names) && !SiteSetting.enable_names

        case hash_source
        when :name
          user.name.presence || requested_username
        when :name_or_username
          user.name.presence || requested_username
        else
          requested_username
        end
      end
    end

    def find_user_by_username(requested_username)
      User.find_by(username_lower: requested_username.downcase)
    end

    def render_blank
      path = Rails.root + "public/images/avatar.png"

      expires_in 10.minutes, public: true
      response.headers["Last-Modified"] = Time.new(1990, 1, 1).httpdate
      response.headers["Content-Length"] = File.size(path).to_s

      send_file path, disposition: nil
    end
  end
end
