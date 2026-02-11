# frozen_string_literal: true

require "rails_helper"

describe FacehashDiscourse::AvatarRenderer do
  let(:colors) { %w[#111111 #222222 #333333] }

  it "is deterministic for the same name and settings" do
    renderer_a = described_class.new(name: "alice", size: 64, variant: :gradient, show_initial: true, colors: colors)
    renderer_b = described_class.new(name: "alice", size: 64, variant: :gradient, show_initial: true, colors: colors)

    expect(renderer_a.to_svg).to eq(renderer_b.to_svg)
  end

  it "changes output for different names" do
    renderer_a = described_class.new(name: "alice", size: 64, variant: :gradient, show_initial: true, colors: colors)
    renderer_b = described_class.new(name: "bob", size: 64, variant: :gradient, show_initial: true, colors: colors)

    expect(renderer_a.to_svg).not_to eq(renderer_b.to_svg)
  end

  it "can render without initial" do
    renderer = described_class.new(name: "alice", size: 64, variant: :solid, show_initial: false, colors: colors)

    expect(renderer.to_svg).to include("<svg")
    expect(renderer.to_svg).not_to include("<text")
  end
end
