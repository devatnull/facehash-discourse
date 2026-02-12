# frozen_string_literal: true

require "digest"
require "zlib"

module ::FacehashDiscourse
  module Config
    BUNDLED_GEIST_PIXEL_FONT_FAMILY = "FacehashGeistPixel".freeze
    BUNDLED_GEIST_PIXEL_FONT_FILENAME = "GeistPixel-Square.woff2".freeze
    BUNDLED_GEIST_PIXEL_FONT_PATH =
      File.expand_path("../../assets/fonts/#{BUNDLED_GEIST_PIXEL_FONT_FILENAME}", __dir__)
    DEFAULT_COLORS =
      %w[
        #ff5555
        #ff79c6
        #bd93f9
        #644ac9
        #6272a4
        #e06b4a
        #d4813f
        #c49b2a
        #4aad5b
        #2a9d8f
        #3a8fd4
        #e05a8a
        #9b6ed0
        #5b8c6e
        #c75a8a
        #4a90a4
      ].freeze
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
      raw = SiteSetting.facehash_avatars_palette
      candidates =
        if raw.is_a?(Array)
          raw
        else
          raw.to_s.split(/[\n,|\s]+/)
        end

      parsed =
        candidates
          .map { |color| color.to_s.strip.gsub(/\A["']+|["']+\z/, "") }
          .reject(&:empty?)
          .map(&:downcase)
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

    def bundled_geist_pixel_font_family
      BUNDLED_GEIST_PIXEL_FONT_FAMILY
    end

    def bundled_geist_pixel_font_data
      return nil unless File.file?(BUNDLED_GEIST_PIXEL_FONT_PATH)

      @bundled_geist_pixel_font_data ||= File.binread(BUNDLED_GEIST_PIXEL_FONT_PATH).freeze
    rescue StandardError
      nil
    end

    def bundled_geist_pixel_font_etag
      data = bundled_geist_pixel_font_data
      return nil if data.nil?

      @bundled_geist_pixel_font_etag ||= Digest::SHA1.hexdigest(data)
    end

    def bundled_geist_pixel_font_url
      "#{Discourse.base_path}/facehash_avatar/font/#{BUNDLED_GEIST_PIXEL_FONT_FILENAME}"
    end
  end
end
