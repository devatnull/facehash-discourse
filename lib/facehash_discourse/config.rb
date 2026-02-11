# frozen_string_literal: true

require "zlib"

module ::FacehashDiscourse
  module Config
    DEFAULT_COLORS = %w[#ec4899 #f59e0b #3b82f6 #f97316 #10b981].freeze
    COLOR_REGEX = /\A#[0-9A-Fa-f]{3,8}\z/
    ALLOWED_HASH_SOURCES = %w[username name name_or_username].freeze
    MAX_COLORS = 32

    module_function

    def settings_version
      payload = [
        FacehashDiscourse::PLUGIN_VERSION,
        SiteSetting.facehash_avatars_gradient_overlay,
        SiteSetting.facehash_avatars_show_initial,
        hash_source,
        SiteSetting.facehash_avatars_palette,
      ].join("|")

      Zlib.crc32(payload).to_s
    end

    def colors
      parsed =
        SiteSetting.facehash_avatars_palette
          .to_s
          .split(/[\n,|\s]+/)
          .map(&:strip)
          .select { |color| COLOR_REGEX.match?(color) }
          .uniq
          .first(MAX_COLORS)

      parsed.empty? ? DEFAULT_COLORS : parsed
    end

    def variant
      SiteSetting.facehash_avatars_gradient_overlay ? :gradient : :solid
    end

    def show_initial?
      SiteSetting.facehash_avatars_show_initial
    end

    def hash_source
      candidate = SiteSetting.facehash_avatars_hash_source.to_s.strip
      ALLOWED_HASH_SOURCES.include?(candidate) ? candidate.to_sym : :username
    end
  end
end
