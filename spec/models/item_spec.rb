require "rails_helper"

RSpec.describe(Item, type: :model) do
  it "has a valid factory" do
    expect(FactoryBot.build(:item)).to be_valid
  end

  # test validations - SOME ARE MISSING

  it "is invalid with inadmissible sort" do
    expect(FactoryBot.build(:item, sort: "some BS")).to be_invalid
  end

  # test traits and subfactories

  describe "with start time" do
    it "has a start time" do
      item = FactoryBot.build(:item, :with_start_time)
      expect(item.start_time).to be_kind_of(TimeStamp)
    end
    it "has the correct start time when the starting_time param is used" do
      item = FactoryBot.build(:item, :with_start_time, starting_time: 1000)
      expect(item.start_time.total_seconds).to eq(1000)
    end
  end

  describe "with medium" do
    it "has a medium" do
      item = FactoryBot.build(:item, :with_medium)
      expect(item.medium).to be_kind_of(Medium)
    end
    it "has a medium with a video" do
      item = FactoryBot.build(:item, :with_medium)
      expect(item.medium.video).to be_kind_of(VideoUploader::UploadedFile)
    end
  end

  describe "item for sample video" do
    it "has a valid factory" do
      expect(FactoryBot.build(:item_for_sample_video)).to be_valid
    end
  end

  describe "#related_items_visible?" do
    let(:item) { create(:item, medium: create(:lecture_medium, :released)) }
    let(:guest_user) { User.new }

    it "returns false for guests when the related medium is not free" do
      related_medium = create(:lecture_medium, released: "users",
                                               released_at: Time.zone.now)
      related_item = create(:item, medium: related_medium)
      create(:item_self_join, item: item, related_item: related_item)

      expect(item.related_items_visible?).to be(false)
      expect(item.related_items_visible?(guest_user)).to be(false)
    end

    it "returns true for guests when the related medium is free" do
      related_medium = create(:lecture_medium, :released)
      related_item = create(:item, medium: related_medium)
      create(:item_self_join, item: item, related_item: related_item)

      expect(item.related_items_visible?).to be(true)
      expect(item.related_items_visible?(guest_user)).to be(true)
    end
  end
end
