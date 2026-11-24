require "rails_helper"

RSpec.describe(AvatarComponent, type: :component) do
  def initials_for(**attributes)
    user = build(:user, first_name: nil, last_name: nil, name: nil,
                        **attributes)
    render_inline(described_class.new(user: user)).at_css(".avatar").text
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
end
