require "rails_helper"

RSpec.describe(MediumTagJoin, type: :model) do
  it "has a valid factory" do
    expect(FactoryBot.build(:medium_tag_join)).to be_valid
  end

  # test validations

  it "is invalid without a medium" do
    expect(FactoryBot.build(:medium_tag_join, medium: nil)).to be_invalid
  end

  it "is invalid without a tag" do
    expect(FactoryBot.build(:medium_tag_join, tag: nil)).to be_invalid
  end
end
