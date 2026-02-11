# frozen_string_literal: true

require "cgi"
require "digest"

module ::FacehashDiscourse
  class AvatarRenderer
    FACE_TYPES = %i[round cross line curved].freeze
    ALLOWED_SHAPES = %i[square squircle round].freeze
    MIN_BLINK_INTERVAL_SECONDS = 2
    MAX_BLINK_INTERVAL_SECONDS = 30
    MIN_BLINK_DURATION_MS = 80
    MAX_BLINK_DURATION_MS = 2000
    SPHERE_POSITIONS = [
      { x: -1, y: 1 },
      { x: 1, y: 1 },
      { x: 1, y: 0 },
      { x: 0, y: 1 },
      { x: -1, y: 0 },
      { x: 0, y: 0 },
      { x: 0, y: -1 },
      { x: -1, y: -1 },
      { x: 1, y: -1 },
    ].freeze

    FACE_SVG_DATA = {
      round: {
        view_box: "0 0 63 15",
        paths: [
          "M62.4 7.2C62.4 11.1765 59.1765 14.4 55.2 14.4C51.2236 14.4 48 11.1765 48 7.2C48 3.22355 51.2236 0 55.2 0C59.1765 0 62.4 3.22355 62.4 7.2Z",
          "M14.4 7.2C14.4 11.1765 11.1765 14.4 7.2 14.4C3.22355 14.4 0 11.1765 0 7.2C0 3.22355 3.22355 0 7.2 0C11.1765 0 14.4 3.22355 14.4 7.2Z",
        ],
      },
      cross: {
        view_box: "0 0 71 23",
        paths: [
          "M11.5 0C12.9411 0 13.6619 0.000460386 14.1748 0.354492C14.3742 0.49213 14.547 0.664882 14.6846 0.864258C15.0384 1.37711 15.0391 2.09739 15.0391 3.53809V7.96094H19.4619C20.9027 7.96094 21.6229 7.9615 22.1357 8.31543C22.3352 8.45308 22.5079 8.62578 22.6455 8.8252C22.9995 9.3381 23 10.0589 23 11.5C23 12.9408 22.9995 13.661 22.6455 14.1738C22.5079 14.3733 22.3352 14.5459 22.1357 14.6836C21.6229 15.0375 20.9027 15.0381 19.4619 15.0381H15.0391V19.4619C15.0391 20.9026 15.0384 21.6229 14.6846 22.1357C14.547 22.3351 14.3742 22.5079 14.1748 22.6455C13.6619 22.9995 12.9411 23 11.5 23C10.0592 23 9.33903 22.9994 8.82617 22.6455C8.62674 22.5079 8.45309 22.3352 8.31543 22.1357C7.96175 21.6229 7.96191 20.9024 7.96191 19.4619V15.0381H3.53809C2.0973 15.0381 1.37711 15.0375 0.864258 14.6836C0.664834 14.5459 0.492147 14.3733 0.354492 14.1738C0.000498831 13.661 -5.88036e-08 12.9408 0 11.5C6.2999e-08 10.0589 0.000460356 9.3381 0.354492 8.8252C0.492144 8.62578 0.664842 8.45308 0.864258 8.31543C1.37711 7.9615 2.09731 7.96094 3.53809 7.96094H7.96191V3.53809C7.96191 2.09765 7.96175 1.37709 8.31543 0.864258C8.45309 0.664828 8.62674 0.492149 8.82617 0.354492C9.33903 0.000555366 10.0592 1.62347e-09 11.5 0Z",
          "M58.7695 0C60.2107 0 60.9314 0.000460386 61.4443 0.354492C61.6437 0.49213 61.8165 0.664882 61.9541 0.864258C62.308 1.37711 62.3086 2.09739 62.3086 3.53809V7.96094H66.7314C68.1722 7.96094 68.8924 7.9615 69.4053 8.31543C69.6047 8.45308 69.7774 8.62578 69.915 8.8252C70.2691 9.3381 70.2695 10.0589 70.2695 11.5C70.2695 12.9408 70.269 13.661 69.915 14.1738C69.7774 14.3733 69.6047 14.5459 69.4053 14.6836C68.8924 15.0375 68.1722 15.0381 66.7314 15.0381H62.3086V19.4619C62.3086 20.9026 62.308 21.6229 61.9541 22.1357C61.8165 22.3351 61.6437 22.5079 61.4443 22.6455C60.9314 22.9995 60.2107 23 58.7695 23C57.3287 23 56.6086 22.9994 56.0957 22.6455C55.8963 22.5079 55.7226 22.3352 55.585 22.1357C55.2313 21.6229 55.2314 20.9024 55.2314 19.4619V15.0381H50.8076C49.3668 15.0381 48.6466 15.0375 48.1338 14.6836C47.9344 14.5459 47.7617 14.3733 47.624 14.1738C47.27 13.661 47.2695 12.9408 47.2695 11.5C47.2695 10.0589 47.27 9.3381 47.624 8.8252C47.7617 8.62578 47.9344 8.45308 48.1338 8.31543C48.6466 7.9615 49.3668 7.96094 50.8076 7.96094H55.2314V3.53809C55.2314 2.09765 55.2313 1.37709 55.585 0.864258C55.7226 0.664828 55.8963 0.492149 56.0957 0.354492C56.6086 0.000555366 57.3287 1.62347e-09 58.7695 0Z",
        ],
      },
      line: {
        view_box: "0 0 82 8",
        paths: [
          "M3.53125 0.164063C4.90133 0.164063 5.58673 0.163893 6.08301 0.485352C6.31917 0.638428 6.52075 0.840012 6.67383 1.07617C6.99555 1.57252 6.99512 2.25826 6.99512 3.62891C6.99512 4.99911 6.99536 5.68438 6.67383 6.18066C6.52075 6.41682 6.31917 6.61841 6.08301 6.77148C5.58672 7.09305 4.90147 7.09277 3.53125 7.09277C2.16062 7.09277 1.47486 7.09319 0.978516 6.77148C0.742356 6.61841 0.540772 6.41682 0.387695 6.18066C0.0662401 5.68439 0.0664063 4.999 0.0664063 3.62891C0.0664063 2.25838 0.0660571 1.57251 0.387695 1.07617C0.540772 0.840012 0.742356 0.638428 0.978516 0.485352C1.47485 0.163744 2.16076 0.164063 3.53125 0.164063Z",
          "M25.1836 0.164063C26.5542 0.164063 27.24 0.163638 27.7363 0.485352C27.9724 0.638384 28.1731 0.8401 28.3262 1.07617C28.6479 1.57252 28.6484 2.25825 28.6484 3.62891C28.6484 4.99931 28.6478 5.68436 28.3262 6.18066C28.1731 6.41678 27.9724 6.61842 27.7363 6.77148C27.24 7.09321 26.5542 7.09277 25.1836 7.09277H11.3262C9.95557 7.09277 9.26978 7.09317 8.77344 6.77148C8.53728 6.61841 8.33569 6.41682 8.18262 6.18066C7.86115 5.68438 7.86133 4.99902 7.86133 3.62891C7.86133 2.25835 7.86096 1.57251 8.18262 1.07617C8.33569 0.840012 8.53728 0.638428 8.77344 0.485352C9.26977 0.163768 9.95572 0.164063 11.3262 0.164063H25.1836Z",
          "M78.2034 7.09325C76.8333 7.09325 76.1479 7.09342 75.6516 6.77197C75.4155 6.61889 75.2139 6.4173 75.0608 6.18114C74.7391 5.6848 74.7395 4.99905 74.7395 3.62841C74.7395 2.2582 74.7393 1.57294 75.0608 1.07665C75.2139 0.840493 75.4155 0.638909 75.6516 0.485832C76.1479 0.164271 76.8332 0.164543 78.2034 0.164543C79.574 0.164543 80.2598 0.164122 80.7561 0.485832C80.9923 0.638909 81.1939 0.840493 81.347 1.07665C81.6684 1.57293 81.6682 2.25831 81.6682 3.62841C81.6682 4.99894 81.6686 5.68481 81.347 6.18114C81.1939 6.4173 80.9923 6.61889 80.7561 6.77197C80.2598 7.09357 79.5739 7.09325 78.2034 7.09325Z",
          "M56.5511 7.09325C55.1804 7.09325 54.4947 7.09368 53.9983 6.77197C53.7622 6.61893 53.5615 6.41722 53.4085 6.18114C53.0868 5.6848 53.0862 4.99907 53.0862 3.62841C53.0862 2.258 53.0868 1.57296 53.4085 1.07665C53.5615 0.840539 53.7622 0.638898 53.9983 0.485832C54.4947 0.164105 55.1804 0.164543 56.5511 0.164543H70.4085C71.7791 0.164543 72.4649 0.164146 72.9612 0.485832C73.1974 0.638909 73.399 0.840493 73.552 1.07665C73.8735 1.57293 73.8733 2.25829 73.8733 3.62841C73.8733 4.99896 73.8737 5.68481 73.552 6.18114C73.399 6.4173 73.1974 6.61889 72.9612 6.77197C72.4649 7.09355 71.7789 7.09325 70.4085 7.09325H56.5511Z",
        ],
      },
      curved: {
        view_box: "0 0 63 9",
        paths: [
          "M0 5.06511C0 4.94513 0 4.88513 0.00771184 4.79757C0.0483059 4.33665 0.341025 3.76395 0.690821 3.46107C0.757274 3.40353 0.783996 3.38422 0.837439 3.34559C2.40699 2.21129 6.03888 0 10.5 0C14.9611 0 18.593 2.21129 20.1626 3.34559C20.216 3.38422 20.2427 3.40353 20.3092 3.46107C20.659 3.76395 20.9517 4.33665 20.9923 4.79757C21 4.88513 21 4.94513 21 5.06511C21 6.01683 21 6.4927 20.9657 6.6754C20.7241 7.96423 19.8033 8.55941 18.5289 8.25054C18.3483 8.20676 17.8198 7.96876 16.7627 7.49275C14.975 6.68767 12.7805 6 10.5 6C8.21954 6 6.02504 6.68767 4.23727 7.49275C3.18025 7.96876 2.65174 8.20676 2.47108 8.25054C1.19668 8.55941 0.275917 7.96423 0.0342566 6.6754C0 6.4927 0 6.01683 0 5.06511Z",
          "M42 5.06511C42 4.94513 42 4.88513 42.0077 4.79757C42.0483 4.33665 42.341 3.76395 42.6908 3.46107C42.7573 3.40353 42.784 3.38422 42.8374 3.34559C44.407 2.21129 48.0389 0 52.5 0C56.9611 0 60.593 2.21129 62.1626 3.34559C62.216 3.38422 62.2427 3.40353 62.3092 3.46107C62.659 3.76395 62.9517 4.33665 62.9923 4.79757C63 4.88513 63 4.94513 63 5.06511C63 6.01683 63 6.4927 62.9657 6.6754C62.7241 7.96423 61.8033 8.55941 60.5289 8.25054C60.3483 8.20676 59.8198 7.96876 58.7627 7.49275C56.975 6.68767 54.7805 6 52.5 6C50.2195 6 48.025 6.68767 46.2373 7.49275C45.1802 7.96876 44.6517 8.20676 44.4711 8.25054C43.1967 8.55941 42.2759 7.96423 42.0343 6.6754C42 6.4927 42 6.01683 42 5.06511Z",
        ],
      },
    }.freeze

    def initialize(
      name:,
      size:,
      variant:,
      show_initial:,
      colors:,
      shape: :round,
      enable_blink: false,
      blink_interval_seconds: 8,
      blink_duration_ms: 140,
      font_family: "monospace",
      font_weight: "700",
      foreground_color: "#000000",
      auto_foreground_contrast: true
    )
      @name = name.to_s
      @size = size.to_i
      @variant = variant.to_sym
      @show_initial = !!show_initial
      @colors = colors
      @shape = sanitize_shape(shape)
      @enable_blink = !!enable_blink
      @blink_interval_seconds =
        sanitize_int(blink_interval_seconds, MIN_BLINK_INTERVAL_SECONDS, MAX_BLINK_INTERVAL_SECONDS)
      @blink_duration_ms =
        sanitize_int(blink_duration_ms, MIN_BLINK_DURATION_MS, MAX_BLINK_DURATION_MS)
      @font_family = font_family.to_s.strip
      @font_family = "monospace" if @font_family.empty?
      @font_weight = sanitize_font_weight(font_weight)
      @foreground_color = foreground_color.to_s
      @auto_foreground_contrast = !!auto_foreground_contrast
    end

    def to_svg
      computed = compute
      face_data = FACE_SVG_DATA.fetch(computed[:face_type])

      view_box_parts = face_data[:view_box].split.map(&:to_f)
      view_box_width = view_box_parts[2]
      view_box_height = view_box_parts[3]
      aspect_ratio = view_box_width / view_box_height

      face_width = @size * 0.6
      face_height = face_width / aspect_ratio

      offset_magnitude = @size * 0.05
      offset_x = computed[:rotation][:y] * offset_magnitude
      offset_y = -computed[:rotation][:x] * offset_magnitude

      face_x = ((@size - face_width) / 2.0) + offset_x
      face_y = (@size * 0.36) - (face_height / 2.0) + offset_y
      font_size = @size * 0.26
      text_y = (@size * 0.76) + offset_y

      id_seed = Digest::MD5.hexdigest([@name, @size, @variant, @shape].join("|"))[0, 10]
      gradient_id = "facehash-gradient-#{id_seed}"
      clip_id = "facehash-clip-#{id_seed}"
      blink_animation_id = "facehash-blink-#{id_seed}"
      initial = CGI.escapeHTML(computed[:initial])
      base_color = computed[:color]
      foreground_color = computed_foreground_color(base_color)

      path_markup = face_data[:paths].map { |path| %(<path d="#{path}" fill="#{foreground_color}" />) }.join
      defs = []

      blink_interval = blink_interval_seconds_for_avatar

      svg =
        +%(<svg xmlns="http://www.w3.org/2000/svg" width="#{@size}" height="#{@size}" viewBox="0 0 #{@size} #{@size}" role="img" aria-label="Facehash avatar" data-facehash="">)
      svg << blink_style_markup(blink_animation_id, blink_interval) if @enable_blink

      if @variant == :gradient
        defs << <<~OVERLAY.strip
          <radialGradient id="#{gradient_id}" cx="50%" cy="50%" r="70%">
            <stop offset="0%" stop-color="#ffffff" stop-opacity="0.15" />
            <stop offset="60%" stop-color="#ffffff" stop-opacity="0" />
          </radialGradient>
        OVERLAY
      end

      if @shape != :square
        defs << shape_clip_markup(clip_id)
      end

      svg << %(<defs>#{defs.join}</defs>) if defs.any?
      svg << %(<g#{%Q( clip-path="url(##{clip_id})") if @shape != :square}>)

      svg << %(<g data-facehash-bg="">)
      svg << %(<rect width="100%" height="100%" fill="#{base_color}" />)
      if @variant == :gradient
        svg << %(<rect width="100%" height="100%" fill="url(##{gradient_id})" data-facehash-gradient="" />)
      end
      svg << %(</g>)

      svg << %(<g data-facehash-face="" data-facehash-rotation-x="#{computed[:rotation][:x]}" data-facehash-rotation-y="#{computed[:rotation][:y]}">)

      if @enable_blink
        svg << %(<g data-facehash-eyes="" class="#{blink_animation_id}" style="animation-duration:#{format_float(blink_interval)}s;animation-delay:-#{format_float(blink_delay_seconds(blink_interval))}s;">)
      else
        svg << %(<g data-facehash-eyes="">)
      end
      svg << %(<svg x="#{format_float(face_x)}" y="#{format_float(face_y)}" width="#{format_float(face_width)}" height="#{format_float(face_height)}" viewBox="#{face_data[:view_box]}" fill="none" aria-hidden="true">)
      svg << path_markup
      svg << %(</svg>)
      svg << %(</g>)

      if @show_initial
        svg << %(<text data-facehash-initial="" x="50%" y="#{format_float(text_y)}" text-anchor="middle" dominant-baseline="middle" font-family="#{CGI.escapeHTML(@font_family)}" font-weight="#{CGI.escapeHTML(@font_weight)}" font-size="#{format_float(font_size)}" fill="#{foreground_color}">#{initial}</text>)
      end

      svg << %(</g>)
      svg << %(</g>)
      svg << %(</svg>)
      svg
    end

    private

    def compute
      hash = string_hash(@name)
      color_index = hash % @colors.length
      face_type = FACE_TYPES[hash % FACE_TYPES.length]
      rotation = SPHERE_POSITIONS[hash % SPHERE_POSITIONS.length]

      {
        face_type: face_type,
        color: @colors[color_index],
        rotation: rotation,
        initial: avatar_initial,
      }
    end

    def avatar_initial
      first =
        if @name.to_s.respond_to?(:grapheme_clusters)
          @name.to_s.grapheme_clusters.first.to_s
        else
          @name.to_s[0].to_s
        end

      first = "?" if first.nil? || first.empty?
      first.upcase
    end

    # Matches facehash/hash.js behavior by constraining to signed 32-bit arithmetic.
    def string_hash(str)
      hash = 0

      str.each_codepoint do |char_code|
        hash = ((hash << 5) - hash + char_code) & 0xffff_ffff
        hash -= 0x1_0000_0000 if hash >= 0x8000_0000
      end

      hash.abs
    end

    def format_float(value)
      value.round(3)
    end

    def sanitize_shape(shape)
      candidate = shape.to_sym
      ALLOWED_SHAPES.include?(candidate) ? candidate : :round
    rescue StandardError
      :round
    end

    def shape_clip_markup(clip_id)
      case @shape
      when :round
        radius = @size / 2.0
        %(<clipPath id="#{clip_id}"><circle cx="#{format_float(radius)}" cy="#{format_float(radius)}" r="#{format_float(radius)}" /></clipPath>)
      when :squircle
        corner = @size * 0.28
        %(<clipPath id="#{clip_id}"><rect width="#{@size}" height="#{@size}" rx="#{format_float(corner)}" ry="#{format_float(corner)}" /></clipPath>)
      else
        ""
      end
    end

    def parse_hex(hex)
      normalized = hex.to_s.strip.sub("#", "")

      case normalized.length
      when 3
        r = (normalized[0] * 2).to_i(16)
        g = (normalized[1] * 2).to_i(16)
        b = (normalized[2] * 2).to_i(16)
      when 6
        r = normalized[0..1].to_i(16)
        g = normalized[2..3].to_i(16)
        b = normalized[4..5].to_i(16)
      else
        return nil
      end

      [r, g, b]
    rescue StandardError
      nil
    end

    def computed_foreground_color(base_color)
      return normalized_hex(@foreground_color) || "#000000" unless @auto_foreground_contrast

      rgb = parse_hex(base_color)
      return "#000000" if rgb.nil?

      yiq = ((rgb[0] * 299) + (rgb[1] * 587) + (rgb[2] * 114)) / 1000.0
      yiq >= 140 ? "#000000" : "#ffffff"
    end

    def normalized_hex(hex)
      rgb = parse_hex(hex)
      return nil if rgb.nil?

      format("#%02x%02x%02x", rgb[0], rgb[1], rgb[2])
    end

    def blink_style_markup(blink_animation_id, interval_seconds)
      close_ratio = [@blink_duration_ms.to_f / (interval_seconds * 1000.0), 0.18].min
      close_start = [0.48 - (close_ratio / 2.0), 0.35].max
      close_end = [close_start + close_ratio, 0.62].min

      <<~STYLE.strip
        <style>
          @keyframes #{blink_animation_id} {
            0%, #{percent(close_start)}%, 100% { transform: scaleY(1); }
            #{percent((close_start + close_end) / 2.0)}% { transform: scaleY(0.08); }
            #{percent(close_end)}% { transform: scaleY(1); }
          }
          .#{blink_animation_id} {
            transform-box: fill-box;
            transform-origin: center;
            animation-name: #{blink_animation_id};
            animation-timing-function: ease-in-out;
            animation-iteration-count: infinite;
          }
        </style>
      STYLE
    end

    def blink_interval_seconds_for_avatar
      base = @blink_interval_seconds.to_f
      return base if base <= 0

      # Deterministic per-avatar jitter prevents lockstep blinking across lists.
      jitter_source = ((blink_hash >> 8) % 1000) / 1000.0
      jitter_factor = 0.8 + (jitter_source * 0.4)
      interval = base * jitter_factor
      interval.clamp(MIN_BLINK_INTERVAL_SECONDS, MAX_BLINK_INTERVAL_SECONDS).to_f
    end

    def blink_delay_seconds(interval_seconds)
      return 0.0 if interval_seconds <= 0

      phase = (blink_hash % 10_000) / 10_000.0
      phase * interval_seconds
    end

    def blink_hash
      @blink_hash ||= string_hash("#{@name}|blink")
    end

    def percent(value)
      format_float(value * 100)
    end

    def sanitize_int(value, min, max)
      value.to_i.clamp(min, max)
    end

    def sanitize_font_weight(font_weight)
      candidate = font_weight.to_s.strip
      return "700" if candidate.empty?
      keyword = candidate.downcase
      return keyword if %w[normal bold bolder lighter].include?(keyword)
      return candidate if candidate.match?(/\A[1-9]00\z/)

      "700"
    end
  end
end
