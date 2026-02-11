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

  it "renders a visible background gradient when variant is gradient" do
    renderer = described_class.new(name: "alice", size: 64, variant: :gradient, show_initial: true, colors: colors)

    expect(renderer.to_svg).to include("linearGradient")
    expect(renderer.to_svg).to include("facehash-gradient-")
  end

  it "renders a circular clip by default" do
    renderer = described_class.new(name: "alice", size: 64, variant: :solid, show_initial: true, colors: colors)

    expect(renderer.to_svg).to include("<clipPath")
    expect(renderer.to_svg).to include("<circle")
  end

  it "supports square shape without clipping" do
    renderer =
      described_class.new(
        name: "alice",
        size: 64,
        variant: :solid,
        show_initial: true,
        colors: colors,
        shape: :square,
      )

    expect(renderer.to_svg).not_to include("<clipPath")
    expect(renderer.to_svg).not_to include("clip-path=")
  end

  it "supports disabling 3d intensity" do
    renderer =
      described_class.new(
        name: "alice",
        size: 64,
        variant: :solid,
        show_initial: true,
        colors: colors,
        intensity_3d: :none,
      )

    expect(renderer.to_svg).not_to include("feDropShadow")
    expect(renderer.to_svg).not_to include("facehash-highlight-")
  end
end
