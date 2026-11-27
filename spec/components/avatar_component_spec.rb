require "rails_helper"

RSpec.describe(AvatarComponent, type: :component) do
  def initials_for(**attributes)
    user = build(:user, first_name: nil, last_name: nil, name: nil,
                        **attributes)
    render_inline(described_class.new(user: user)).at_css(".user-avatar").text
  end

  it "takes the first letters of the first and last name" do
    expect(initials_for(first_name: "ada", last_name: "Lovelace")).to eq("AL")
  end

  it "uses first and last word of a longer display name" do
    expect(initials_for(name: "Jean Luc Picard")).to eq("JP")
  end

  it "uses a single letter for a one-word name" do
    expect(initials_for(name: "max")).to eq("M")
  end

  it "falls back to the email" do
    expect(initials_for(email: "x@example.com")).to eq("X")
  end

  it "prefers first and last name over the display name" do
    expect(initials_for(first_name: "Ada", last_name: "Lovelace",
                        name: "Countess")).to eq("AL")
  end

  it "ignores surrounding whitespace and leading non-letters" do
    expect(initials_for(name: " (Ada) 🇩🇪　Lovelace ")).to eq("AL")
  end

  it "shows a question mark if there is nothing to take letters from" do
    expect(initials_for(name: "🎉", email: "")).to eq("?")
  end
end
