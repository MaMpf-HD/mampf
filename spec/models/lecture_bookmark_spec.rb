require "rails_helper"

RSpec.describe(LectureBookmark, type: :model) do
  include ActiveSupport::Testing::TimeHelpers

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

  it "touches the user when a lecture is bookmarked and when the bookmark goes" do
    user = create(:confirmed_user)
    lecture = create(:lecture, :released_for_all)

    travel_to(1.hour.from_now) do
      expect { user.bookmark_lecture!(lecture) }.to(change { user.reload.updated_at })
    end
    travel_to(2.hours.from_now) do
      expect { user.unbookmark_lecture!(lecture) }.to(change { user.reload.updated_at })
    end
  end
end
