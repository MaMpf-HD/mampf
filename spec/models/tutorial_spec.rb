require "rails_helper"

RSpec.describe(Tutorial, type: :model) do
  describe "Registration::Registerable" do
    it_behaves_like "a registerable model"
  end

  describe "Rosters::Rosterable" do
    it_behaves_like "a rosterable model"
  end

  it "has a valid factory" do
    expect(FactoryBot.build(:tutorial)).to be_valid
  end

  # test validations

  it "is invalid without a lecture" do
    expect(FactoryBot.build(:tutorial, lecture: nil)).to be_invalid
  end

  it "is invalid without a title" do
    expect(FactoryBot.build(:tutorial, title: nil)).to be_invalid
  end

  it "is invalid with duplicate title in same lecture" do
    tutorial = FactoryBot.create(:tutorial)
    lecture = tutorial.lecture
    title = tutorial.title
    new_tutorial = FactoryBot.build(:tutorial, lecture: lecture, title: title)
    expect(new_tutorial).to be_invalid
  end

  # test traits

  describe "with tutors" do
    it "has a tutor" do
      tutorial = FactoryBot.build(:tutorial, :with_tutors)
      expect(tutorial.tutors.size).to eq(1)
    end
    it "has the correct number of tutors if tutors_count is supplied" do
      tutorial = FactoryBot.build(:tutorial, :with_tutors, tutors_count: 3)
      expect(tutorial.tutors.size).to eq(3)
    end
  end

  describe "#materialize_allocation!" do
    let(:lecture) { create(:lecture) }
    let(:tutorial) { create(:tutorial, lecture: lecture) }
    let(:campaign) { create(:registration_campaign) }
    let(:user) { create(:confirmed_user) }
    let(:user2) { create(:confirmed_user) }

    it "propagates users to the lecture roster" do
      expect(lecture.lecture_memberships.where(user: [user, user2])).to be_empty

      tutorial.materialize_allocation!(user_ids: [user.id, user2.id], campaign: campaign)

      expect(lecture.lecture_memberships.where(user: user)).to exist
      expect(lecture.lecture_memberships.where(user: user2)).to exist
    end
  end
end
