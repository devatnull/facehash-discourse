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

    expect(renderer.to_svg).to include("radialGradient")
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

  it "renders a dedicated face layer for client-side interaction" do
    renderer =
      described_class.new(
        name: "alice",
        size: 64,
        variant: :solid,
        show_initial: true,
        colors: colors,
      )

    svg = renderer.to_svg
    expect(svg).to include('data-facehash=""')
    expect(svg).to include('data-facehash-face=""')
    expect(svg).to include('data-facehash-rotation-x="')
    expect(svg).to include('data-facehash-rotation-y="')
  end

  it "supports blink animation markup" do
    renderer =
      described_class.new(
        name: "alice",
        size: 64,
        variant: :solid,
        show_initial: true,
        colors: colors,
        enable_blink: true,
        blink_interval_seconds: 5,
        blink_duration_ms: 140,
      )

    svg = renderer.to_svg
    expect(svg).to include("@keyframes facehash-blink-")
    expect(svg).to include("animation-duration:")
    expect(svg).not_to include("animation-duration:5s")
    expect(svg).to include("animation-delay:-")
  end

  it "supports custom font family and weight" do
    renderer =
      described_class.new(
        name: "alice",
        size: 64,
        variant: :solid,
        show_initial: true,
        colors: colors,
        font_family: "Inter, sans-serif",
        font_weight: "600",
      )

    svg = renderer.to_svg
    expect(svg).to include('font-family="Inter, sans-serif"')
    expect(svg).to include('font-weight="600"')
  end

  it "uses white foreground when auto contrast is enabled on dark backgrounds" do
    renderer =
      described_class.new(
        name: "alice",
        size: 64,
        variant: :solid,
        show_initial: true,
        colors: ["#000000"],
      )

    svg = renderer.to_svg
    expect(svg).to include('fill="#ffffff"')
  end

  it "uses configured manual foreground color when auto contrast is disabled" do
    renderer =
      described_class.new(
        name: "alice",
        size: 64,
        variant: :solid,
        show_initial: true,
        colors: ["#ffffff"],
        auto_foreground_contrast: false,
        foreground_color: "#ff0000",
      )

    expect(renderer.to_svg).to include('fill="#ff0000"')
  end
end
