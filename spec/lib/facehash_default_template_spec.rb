# frozen_string_literal: true

require "rails_helper"

describe "Facehash default avatar template" do
  it "uses facehash template when enabled" do
    SiteSetting.facehash_avatars_enabled = true

    template = User.default_template("alice")

    expect(template).to include("/facehash_avatar/")
    expect(template).to include("/{size}/")
    expect(template).to end_with(".svg")
  end

  it "falls back to core behavior when disabled" do
    SiteSetting.facehash_avatars_enabled = false

    template = User.default_template("alice")

    expect(template).not_to include("/facehash_avatar/")
  end

  it "keeps uploaded avatar templates untouched" do
    SiteSetting.facehash_avatars_enabled = true
    template = User.avatar_template("alice", 42)

    expect(template).to include("/user_avatar/")
    expect(template).not_to include("/facehash_avatar/")
  end
end
