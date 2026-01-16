require "rails_helper"

RSpec.describe(Cohort, type: :model) do
  it "has a valid factory" do
    expect(build(:cohort)).to be_valid
  end

  describe "validations" do
    it "is invalid without a title" do
      cohort = build(:cohort, title: nil)
      expect(cohort).not_to be_valid
      expect(cohort.errors[:title]).to be_present
    end

    it "is invalid without a purpose" do
      cohort = build(:cohort, purpose: nil)
      expect(cohort).not_to be_valid
      expect(cohort.errors[:purpose]).to be_present
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
  end

  describe "purpose enum" do
    it "supports general purpose" do
      cohort = create(:cohort, :general)
      expect(cohort.general?).to be(true)
    end

    it "supports enrollment purpose" do
      cohort = create(:cohort, :enrollment)
      expect(cohort.enrollment?).to be(true)
    end

    it "supports planning purpose" do
      cohort = create(:cohort, :planning)
      expect(cohort.planning?).to be(true)
    end
  end

  describe "propagate_to_lecture immutability" do
    it "cannot be changed after creation" do
      cohort = create(:cohort, propagate_to_lecture: false)

      expect { cohort.propagate_to_lecture = true }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end
  end

  describe "purpose change validation" do
    context "when changing to enrollment purpose" do
      it "is valid if propagate_to_lecture is true" do
        cohort = create(:cohort, purpose: :general, propagate_to_lecture: true)
        cohort.purpose = :enrollment

        expect(cohort).to be_valid
      end

      it "is invalid if propagate_to_lecture is false" do
        cohort = create(:cohort, purpose: :general, propagate_to_lecture: false)
        cohort.purpose = :enrollment

        expect(cohort).not_to be_valid
        expect(cohort.errors[:purpose]).to be_present
      end
    end

    context "when changing to planning purpose" do
      it "is valid if propagate_to_lecture is false" do
        cohort = create(:cohort, purpose: :general, propagate_to_lecture: false)
        cohort.purpose = :planning

        expect(cohort).to be_valid
      end

      it "is invalid if propagate_to_lecture is true" do
        cohort = create(:cohort, purpose: :general, propagate_to_lecture: true)
        cohort.purpose = :planning

        expect(cohort).not_to be_valid
        expect(cohort.errors[:purpose]).to be_present
      end
    end

    context "when changing to general purpose" do
      it "is always valid regardless of propagate_to_lecture" do
        cohort_with_propagate = create(:cohort, purpose: :enrollment, propagate_to_lecture: true)
        cohort_with_propagate.purpose = :general
        expect(cohort_with_propagate).to be_valid

        cohort_without_propagate = create(:cohort, purpose: :planning, propagate_to_lecture: false)
        cohort_without_propagate.purpose = :general
        expect(cohort_without_propagate).to be_valid
      end
    end

    context "when purpose is not changed" do
      it "does not run validation" do
        cohort = create(:cohort, purpose: :general, propagate_to_lecture: false)
        cohort.title = "New Title"

        expect(cohort).to be_valid
      end
    end
  end

  describe "database constraints" do
    it "prevents planning cohorts from propagating" do
      expect do
        create(:cohort, purpose: :planning, propagate_to_lecture: true)
      end.to raise_error(ActiveRecord::StatementInvalid, /planning_cohorts_must_not_propagate/)
    end

    it "enforces enrollment cohorts must propagate" do
      expect do
        create(:cohort, purpose: :enrollment, propagate_to_lecture: false)
      end.to raise_error(ActiveRecord::StatementInvalid, /enrollment_cohorts_must_propagate/)
    end

    it "allows general cohorts with either propagation setting" do
      expect(create(:cohort, purpose: :general, propagate_to_lecture: false)).to be_valid
      expect(create(:cohort, purpose: :general, propagate_to_lecture: true)).to be_valid
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
end
