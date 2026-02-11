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

  it "deduplicates and caps palette colors for safety" do
    color_list = (1..50).map { |i| format("#%06x", i) }
    SiteSetting.facehash_avatars_palette = ([color_list.first] + color_list).join("|")

    parsed = described_class.colors

    expect(parsed.length).to eq(described_class::MAX_COLORS)
    expect(parsed.first).to eq(color_list.first)
    expect(parsed.uniq.length).to eq(parsed.length)
  end
end
