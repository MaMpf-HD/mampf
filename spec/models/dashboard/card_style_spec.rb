require "rails_helper"

RSpec.describe(Dashboard::CardStyle) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }

  it "keeps each color's number, whatever order the tape colors are listed in" do
    expect(described_class.tape_colors)
      .to eq("butter" => 0, "rose" => 1, "mint" => 2, "sky" => 3, "lavender" => 4, "peach" => 5)
  end

  it "refuses a color that is not a tape color" do
    style = described_class.new(user: user, lecture: lecture, tape_color: "chartreuse")

    expect(style).not_to be_valid
  end

  it "goes with the user who chose it" do
    described_class.create!(user: user, lecture: lecture, tape_color: "mint")

    expect { user.destroy! }.to change(described_class, :count).by(-1)
  end

  it "goes with the lecture it was chosen for" do
    described_class.create!(user: user, lecture: lecture, tape_color: "mint")

    expect { lecture.destroy! }.to change(described_class, :count).by(-1)
  end
end
