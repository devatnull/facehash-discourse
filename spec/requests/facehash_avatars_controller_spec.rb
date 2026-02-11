# frozen_string_literal: true

require "rails_helper"

describe FacehashDiscourse::AvatarsController do
  fab!(:user) { Fabricate(:user, username: "alice") }

  def avatar_path(username: "alice", size: 80, version: FacehashDiscourse::Config.settings_version)
    "/facehash_avatar/#{username}/#{size}/#{version}.svg"
  end

  before do
    Discourse.cache.clear
    SiteSetting.facehash_avatars_enabled = true
    SiteSetting.facehash_avatars_gradient_overlay = true
    SiteSetting.facehash_avatars_show_initial = true
    SiteSetting.facehash_avatars_hash_source = "username"
  end

  it "serves deterministic svg avatars" do
    get avatar_path

    expect(response.status).to eq(200)
    expect(response.media_type).to eq("image/svg+xml")
    expect(response.body).to include("<svg")
    expect(response.body).to include("aria-label=\"Facehash avatar\"")
    expect(response.headers["Cache-Control"]).to include("immutable")
    expect(response.headers["ETag"]).to be_present
    expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
  end

  it "supports conditional GET and returns 304 for unchanged avatars" do
    get avatar_path
    etag = response.headers["ETag"]

    get avatar_path, headers: { "If-None-Match" => etag }

    expect(response.status).to eq(304)
  end

  it "returns fallback image when disabled" do
    SiteSetting.facehash_avatars_enabled = false

    get avatar_path

    expect(response.status).to eq(200)
    expect(response.media_type).to eq("image/png")
  end

  it "still serves an svg for old versioned URLs" do
    get avatar_path(version: "999")

    expect(response.status).to eq(200)
    expect(response.media_type).to eq("image/svg+xml")
  end

  it "returns fallback image on out-of-range size" do
    get avatar_path(size: 4000)

    expect(response.status).to eq(200)
    expect(response.media_type).to eq("image/png")
  end

  it "returns fallback image for invalid username input length" do
    get avatar_path(username: "a" * 500)

    expect(response.status).to eq(200)
    expect(response.media_type).to eq("image/png")
  end

  it "serves avatars for usernames containing dots" do
    get avatar_path(username: "yunus.gunes")

    expect(response.status).to eq(200)
    expect(response.media_type).to eq("image/svg+xml")
    expect(response.body).to include("<svg")
  end

  it "uses user full name as seed when hash_source is name" do
    user.update!(name: "Zed Example")
    SiteSetting.facehash_avatars_hash_source = "name"

    get avatar_path(username: user.username)

    expect(response.status).to eq(200)
    expect(response.media_type).to eq("image/svg+xml")
    expect(response.body).to include(">Z</text>")
  end

  it "falls back to username seed when names are disabled" do
    SiteSetting.facehash_avatars_hash_source = "name"
    user.update!(name: "Zed Example")

    if SiteSetting.respond_to?(:enable_names=)
      SiteSetting.enable_names = false
    end

    get avatar_path(username: user.username)

    expect(response.status).to eq(200)
    expect(response.media_type).to eq("image/svg+xml")
    expect(response.body).to include(">A</text>")
  ensure
    SiteSetting.enable_names = true if SiteSetting.respond_to?(:enable_names=)
  end
end
