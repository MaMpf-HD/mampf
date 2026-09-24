require "rails_helper"

RSpec.describe(LectureBookmark, type: :model) do
  it "has a valid factory" do
    expect(FactoryBot.build(:lecture_bookmark)).to be_valid
  end

  # test validations

  it "is invalid without a lecture" do
    expect(FactoryBot.build(:lecture_bookmark, lecture: nil)).to be_invalid
  end

  it "is invalid without a user" do
    expect(FactoryBot.build(:lecture_bookmark, user: nil)).to be_invalid
  end
end
