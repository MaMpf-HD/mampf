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

  it "is invalid if lecture is a seminar" do
    lecture = FactoryBot.create(:seminar)
    tutorial = FactoryBot.build(:tutorial, lecture: lecture)
    expect(tutorial).to be_invalid
    expect(tutorial.errors[:lecture]).to include(I18n.t("activerecord.errors.models.tutorial.attributes.lecture.must_not_be_seminar"))
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
    let(:other_tutorial) { create(:tutorial, lecture: lecture) }
    let(:campaign) { create(:registration_campaign) }
    let(:user) { create(:user) }

    before do
      # User is in another tutorial of the same lecture
      create(:tutorial_membership, user: user, tutorial: other_tutorial)
    end

    it "removes the user from other tutorials in the same lecture" do
      expect(other_tutorial.members).to include(user)

      tutorial.materialize_allocation!(user_ids: [user.id], campaign: campaign)

      expect(other_tutorial.reload.members).not_to include(user)
      expect(tutorial.reload.members).to include(user)
    end

    it "does not remove the user from tutorials in other lectures" do
      other_lecture = create(:lecture)
      other_lecture_tutorial = create(:tutorial, lecture: other_lecture)
      create(:tutorial_membership, user: user, tutorial: other_lecture_tutorial)

      tutorial.materialize_allocation!(user_ids: [user.id], campaign: campaign)

      expect(other_lecture_tutorial.reload.members).to include(user)
    end
  end
end
