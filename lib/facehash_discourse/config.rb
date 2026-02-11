# frozen_string_literal: true

require "zlib"

module ::FacehashDiscourse
  module Config
    DEFAULT_COLORS = %w[#ec4899 #f59e0b #3b82f6 #f97316 #10b981].freeze
    COLOR_REGEX = /\A#[0-9A-Fa-f]{3,8}\z/
    ALLOWED_HASH_SOURCES = %w[username name name_or_username].freeze
    ALLOWED_SHAPES = %w[square squircle round].freeze
    ALLOWED_FONT_WEIGHTS = %w[normal bold bolder lighter].freeze
    FONT_WEIGHT_REGEX = /\A[1-9]00\z/
    FONT_FAMILY_REGEX = /\A[\w\s,'"-]+\z/
    MIN_BLINK_INTERVAL_SECONDS = 2
    MAX_BLINK_INTERVAL_SECONDS = 30
    MIN_BLINK_DURATION_MS = 80
    MAX_BLINK_DURATION_MS = 2000
    MAX_COLORS = 32

    module_function

    def settings_version
      payload = [
        FacehashDiscourse::PLUGIN_VERSION,
        SiteSetting.facehash_avatars_gradient_overlay,
        SiteSetting.facehash_avatars_show_initial,
        enable_blink?,
        blink_interval_seconds,
        blink_duration_ms,
        hash_source,
        shape,
        font_family,
        font_weight,
        auto_foreground_contrast?,
        foreground_color,
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

    def enable_blink?
      SiteSetting.facehash_avatars_enable_blink
    end

    def hash_source
      candidate = SiteSetting.facehash_avatars_hash_source.to_s.strip
      ALLOWED_HASH_SOURCES.include?(candidate) ? candidate.to_sym : :username
    end

    def shape
      candidate = SiteSetting.facehash_avatars_shape.to_s.strip
      ALLOWED_SHAPES.include?(candidate) ? candidate.to_sym : :round
    end

    def intensity_3d
      :dramatic
    end

    def blink_interval_seconds
      value = SiteSetting.facehash_avatars_blink_interval_seconds.to_i
      value.clamp(MIN_BLINK_INTERVAL_SECONDS, MAX_BLINK_INTERVAL_SECONDS)
    end

    def blink_duration_ms
      value = SiteSetting.facehash_avatars_blink_duration_ms.to_i
      value.clamp(MIN_BLINK_DURATION_MS, MAX_BLINK_DURATION_MS)
    end

    def font_family
      candidate = SiteSetting.facehash_avatars_font_family.to_s.strip
      return "monospace" if candidate.empty?
      return "monospace" unless FONT_FAMILY_REGEX.match?(candidate)

      candidate
    end

    def font_weight
      candidate = SiteSetting.facehash_avatars_font_weight.to_s.strip.downcase
      return candidate if ALLOWED_FONT_WEIGHTS.include?(candidate)
      return candidate if FONT_WEIGHT_REGEX.match?(candidate)

      "700"
    end

    def auto_foreground_contrast?
      SiteSetting.facehash_avatars_auto_foreground_contrast
    end

    def foreground_color
      candidate = SiteSetting.facehash_avatars_foreground_color.to_s.strip
      COLOR_REGEX.match?(candidate) ? candidate : "#000000"
    end
  end
end
