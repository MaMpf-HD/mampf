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

  it "is valid without a location" do
    expect(FactoryBot.build(:tutorial, location: nil)).to be_valid
  end

  it "persists location" do
    tutorial = FactoryBot.create(:tutorial, location: "INF 205")
    expect(tutorial.reload.location).to eq("INF 205")
  end

  it "is invalid if lecture is a seminar" do
    lecture = FactoryBot.create(:seminar)
    tutorial = FactoryBot.build(:tutorial, lecture: lecture)
    expect(tutorial).to be_invalid
    expect(tutorial.errors[:lecture])
      .to include(I18n.t("activerecord.errors.models.tutorial.attributes." \
                         "lecture.must_not_be_seminar"))
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

    context "when user is in another tutorial of the same lecture" do
      let(:other_tutorial) { create(:tutorial, lecture: lecture) }

      before do
        create(:tutorial_membership, user: user, tutorial: other_tutorial)
      end

      it "removes the user from other tutorials in the same lecture" do
        expect(other_tutorial.members).to include(user)

        tutorial.materialize_allocation!(user_ids: [user.id], campaign: campaign)

        expect(other_tutorial.reload.members).not_to include(user)
        expect(tutorial.reload.members).to include(user)
      end
    end

    context "when user is in a tutorial of another lecture" do
      let(:other_lecture) { create(:lecture) }
      let(:other_lecture_tutorial) { create(:tutorial, lecture: other_lecture) }

      before do
        create(:tutorial_membership, user: user, tutorial: other_lecture_tutorial)
      end

      it "does not remove the user from tutorials in other lectures" do
        tutorial.materialize_allocation!(user_ids: [user.id], campaign: campaign)

        expect(other_lecture_tutorial.reload.members).to include(user)
      end
    end
  end

  describe "#add_tutor" do
    it "creates at most one join under concurrent calls" do
      tutorial = create(:tutorial)
      tutor = create(:confirmed_user)

      values = run_concurrently do
        Tutorial.find(tutorial.id).add_tutor(User.find(tutor.id))
      end

      expect(values).to contain_exactly(true, false)
      expect(TutorTutorialJoin.where(tutorial: tutorial, tutor: tutor).count).to eq(1)
    end
  end

  describe "#add_user_to_roster!" do
    let(:lecture) { create(:lecture) }
    let(:tutorial) { create(:tutorial, lecture: lecture) }
    let(:other_tutorial) { create(:tutorial, lecture: lecture) }
    let(:user) { create(:confirmed_user) }

    context "when the DB unique index fires under concurrency" do
      before do
        # Insert directly to simulate the state a concurrent transaction would
        # leave: a conflicting membership that bypasses model validations.
        # rubocop:disable Rails/SkipsModelValidations
        TutorialMembership.insert_all([{
                                        user_id: user.id,
                                        tutorial_id: other_tutorial.id,
                                        lecture_id: lecture.id,
                                        created_at: Time.current,
                                        updated_at: Time.current
                                      }])
        # rubocop:enable Rails/SkipsModelValidations
      end

      it "raises UserAlreadyInBundleError instead of RecordNotUnique" do
        allow_any_instance_of(TutorialMembership)
          .to receive(:unique_membership_per_lecture)

        expect do
          tutorial.add_user_to_roster!(user)
        end.to raise_error(Rosters::UserAlreadyInBundleError)
      end
    end
  end

  describe "lecture_id immutability" do
    let(:tutorial) { create(:tutorial) }
    let(:other_lecture) { create(:lecture) }

    it "cannot be changed after creation" do
      tutorial.lecture_id = other_lecture.id

      expect(tutorial).to be_invalid
      expect(tutorial.errors.added?(:lecture_id, :immutable)).to be(true)
    end
  end
end
