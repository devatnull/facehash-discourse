# frozen_string_literal: true

require "rails_helper"

describe FacehashDiscourse::Config do
  it "parses configured palette and filters invalid colors" do
    SiteSetting.facehash_avatars_palette = "#112233|invalid|#abcdef"

    expect(described_class.colors).to eq(%w[#112233 #abcdef])
  end

  it "falls back to defaults when palette is invalid" do
    SiteSetting.facehash_avatars_palette = "invalid"

    expect(described_class.colors).to eq(described_class::DEFAULT_COLORS)
  end

  it "supports a valid hash source setting" do
    SiteSetting.facehash_avatars_hash_source = "name_or_username"

    expect(described_class.hash_source).to eq(:name_or_username)
  end

  it "falls back to username hash source when invalid" do
    SiteSetting.facehash_avatars_hash_source = "bad-value"

    expect(described_class.hash_source).to eq(:username)
  end

  it "supports a valid shape setting" do
    SiteSetting.facehash_avatars_shape = "squircle"

    expect(described_class.shape).to eq(:squircle)
  end

  it "falls back to round shape when invalid" do
    SiteSetting.facehash_avatars_shape = "bad-shape"

    expect(described_class.shape).to eq(:round)
  end

  it "uses a fixed flat 3d intensity" do
    expect(described_class.intensity_3d).to eq(:none)
  end

  it "clamps blink interval to safe bounds" do
    SiteSetting.facehash_avatars_blink_interval_seconds = 500

    expect(described_class.blink_interval_seconds).to eq(described_class::MAX_BLINK_INTERVAL_SECONDS)
  end

  it "clamps blink duration to safe bounds" do
    SiteSetting.facehash_avatars_blink_duration_ms = 1

    expect(described_class.blink_duration_ms).to eq(described_class::MIN_BLINK_DURATION_MS)
  end

  it "sanitizes invalid font family" do
    SiteSetting.facehash_avatars_font_family = "bad; value"

    expect(described_class.font_family).to eq("monospace")
  end

  it "supports numeric font weight values" do
    SiteSetting.facehash_avatars_font_weight = "600"

    expect(described_class.font_weight).to eq("600")
  end

  it "falls back to default font weight when invalid" do
    SiteSetting.facehash_avatars_font_weight = "heavy"

    expect(described_class.font_weight).to eq("700")
  end

  it "falls back to default foreground color when invalid" do
    SiteSetting.facehash_avatars_foreground_color = "red"

    expect(described_class.foreground_color).to eq("#000000")
  end

  it "deduplicates and caps palette colors for safety" do
    color_list = (1..50).map { |i| format("#%06x", i) }
    SiteSetting.facehash_avatars_palette = ([color_list.first] + color_list).join("|")

    parsed = described_class.colors

    expect(parsed.length).to eq(described_class::MAX_COLORS)
    expect(parsed.first).to eq(color_list.first)
    expect(parsed.uniq.length).to eq(parsed.length)
  end
end
