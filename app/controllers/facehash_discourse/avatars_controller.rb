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

    def show
      is_asset_path
      no_cookies

      return render_blank unless SiteSetting.facehash_avatars_enabled
      requested_username = extract_username_param
      return render_blank if requested_username.blank?
      return render_blank unless valid_username_param?(requested_username)

      size = params[:size].to_i
      return render_blank if size < MIN_SIZE || size > MAX_SIZE

      normalized_username = User.normalize_username(requested_username) || requested_username.downcase
      avatar_seed = avatar_seed_for(normalized_username)
      immutable_for(1.year)
      return unless stale?(etag: avatar_etag(normalized_username, avatar_seed, size), public: true)

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

    def extract_username_param
      username = params[:username].to_s
      username.unicode_normalize
    rescue StandardError
      nil
    end

    def valid_username_param?(requested_username)
      # Keep route behavior aligned with Discourse's own username rules.
      UsernameValidator.new(requested_username).valid_format?
    end

    def avatar_etag(normalized_username, avatar_seed, size)
      payload =
        [
          ::FacehashDiscourse::Config.settings_version,
          normalized_username,
          avatar_seed,
          size,
        ].join("|")

      Digest::SHA1.hexdigest(payload)
    end

    def avatar_seed_for(normalized_username)
      hash_source = ::FacehashDiscourse::Config.hash_source
      return normalized_username if hash_source == :username

      username_key = normalized_username
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
        user = find_user_by_username(normalized_username)
        next normalized_username if user.blank?
        next normalized_username if SiteSetting.respond_to?(:enable_names) && !SiteSetting.enable_names

        case hash_source
        when :name
          user.name.presence || normalized_username
        when :name_or_username
          user.name.presence || normalized_username
        else
          normalized_username
        end
      end
    end

    def find_user_by_username(normalized_username)
      User.find_by(username_lower: normalized_username)
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
