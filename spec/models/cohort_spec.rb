require "rails_helper"

RSpec.describe(Cohort, type: :model) do
  it "has a valid factory" do
    expect(build(:cohort)).to be_valid
  end

  it "is not roster-exclusive within a lecture (memberships can coexist)" do
    expect(build(:cohort).roster_exclusive_within_lecture?).to be(false)
  end

  describe "validations" do
    it "is invalid without a title" do
      cohort = build(:cohort, title: nil)
      expect(cohort).not_to be_valid
      expect(cohort.errors[:title]).to be_present
    end

    it "is invalid with a negative capacity" do
      cohort = build(:cohort, capacity: -1)
      expect(cohort).not_to be_valid
      expect(cohort.errors[:capacity]).to be_present
    end

    it "is valid with a nil capacity" do
      cohort = build(:cohort, capacity: nil)
      expect(cohort).to be_valid
    end

    it "is invalid with duplicate title in the same context" do
      cohort = create(:cohort)
      duplicate = build(:cohort, context: cohort.context, title: cohort.title)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:title]).to be_present
    end

    it "allows the same title in different contexts" do
      cohort = create(:cohort)
      other_context = create(:lecture)
      other_cohort = build(:cohort, context: other_context, title: cohort.title)
      expect(other_cohort).to be_valid
    end
  end

  describe "propagate_to_lecture immutability" do
    it "cannot be changed after creation" do
      cohort = create(:cohort, propagate_to_lecture: false)

      expect { cohort.propagate_to_lecture = true }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end
  end

  describe "associations" do
    it "belongs to a context" do
      association = described_class.reflect_on_association(:context)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "Registerable interface" do
    it_behaves_like "a registerable model"
  end

  describe "Rosterable interface" do
    it_behaves_like "a rosterable model"
  end

  describe "Registerable interface" do
    it "includes Registration::Registerable" do
      expect(Cohort.ancestors).to include(Registration::Registerable)
    end

    it "includes Rosters::Rosterable" do
      expect(Cohort.ancestors).to include(Rosters::Rosterable)
    end

    it "implements roster_entries" do
      cohort = build(:cohort)
      expect(cohort).to respond_to(:roster_entries)
    end
  end

  describe "#lecture" do
    it "returns the context as lecture if it is a Lecture" do
      lecture = build(:lecture)
      cohort = build(:cohort, context: lecture)
      expect(cohort.lecture).to eq(lecture)
    end

    it "returns nil for lecture if context is not a Lecture" do
      cohort = build(:cohort, context: nil)
      expect(cohort.lecture).to be_nil
    end
  end

  describe "#lecture_id" do
    it "returns the context id if the context is a Lecture" do
      lecture = create(:lecture)
      cohort = build(:cohort, context: lecture)
      expect(cohort.lecture_id).to eq(lecture.id)
    end

    it "returns nil if the context is not a Lecture" do
      cohort = build(:cohort, context: create(:course))
      expect(cohort.lecture_id).to be_nil
    end
  end

  describe "#materialize_allocation!" do
    let(:lecture) { create(:lecture) }
    let(:campaign) { create(:registration_campaign) }
    let(:user) { create(:confirmed_user) }

    context "when cohort is isolated (propagate_to_lecture = false)" do
      let(:cohort) { create(:cohort, context: lecture, propagate_to_lecture: false) }

      it "does NOT propagate users to the lecture roster" do
        expect(lecture.lecture_memberships.where(user: user)).to be_empty
        cohort.materialize_allocation!(user_ids: [user.id], campaign: campaign)
        expect(lecture.lecture_memberships.where(user: user)).not_to exist
      end
    end

    context "when cohort propagates (propagate_to_lecture = true)" do
      let(:cohort) { create(:cohort, context: lecture, propagate_to_lecture: true) }

      it "propagates users to the lecture roster" do
        expect(lecture.lecture_memberships.where(user: user)).to be_empty
        cohort.materialize_allocation!(user_ids: [user.id], campaign: campaign)
        expect(lecture.lecture_memberships.where(user: user)).to exist
      end
    end
  end

  describe "propagate_to_lecture immutability" do
    it "can be set on create" do
      cohort = create(:cohort, propagate_to_lecture: true)
      expect(cohort.propagate_to_lecture).to be(true)
    end

    it "does not change on update" do
      cohort = create(:cohort, propagate_to_lecture: false)
      expect { cohort.update!(propagate_to_lecture: true) }
        .to raise_error(ActiveRecord::ReadonlyAttributeError)

      expect(cohort.reload.propagate_to_lecture).to be(false)
    end
  end

  describe "#destroy_with_members" do
    let(:lecture) { create(:lecture) }
    let(:cohort) { create(:cohort, context: lecture, propagate_to_lecture: true) }
    let(:member) { create(:confirmed_user) }

    before { Rosters::MaintenanceService.new.add_user!(member, cohort) }

    it "deletes the cohort with its memberships, keeping the lecture enrollment" do
      expect(cohort.destroy_with_members).to eq([member])

      expect(cohort).to be_destroyed
      expect(CohortMembership.where(user: member)).to be_empty
      expect(lecture.members).to include(member)
    end

    it "keeps cohort and members while a campaign holds the cohort" do
      create(:registration_item, registerable: cohort,
                                 registration_campaign: create(:registration_campaign,
                                                               campaignable: lecture))

      expect(cohort.destroy_with_members).to be_nil
      expect(cohort.reload.members).to contain_exactly(member)
    end
  end

  describe "#members_without_other_group" do
    let(:lecture) { create(:lecture) }
    let(:cohort) { create(:cohort, context: lecture) }

    it "counts only the members in no tutorial, talk or other cohort of the lecture" do
      alone, tutored, elsewhere = create_list(:confirmed_user, 3)
      [alone, tutored, elsewhere].each { |user| cohort.add_user_to_roster!(user) }
      create(:tutorial, lecture: lecture).add_user_to_roster!(tutored)
      create(:cohort, context: lecture).add_user_to_roster!(elsewhere)

      expect(cohort.members_without_other_group).to contain_exactly(alone)
    end
  end
end
