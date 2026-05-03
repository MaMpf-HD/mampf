require "rails_helper"

RSpec.describe(Assessment::Assessment, type: :model) do
  describe "factory" do
    it "creates a valid default assessment" do
      assessment = FactoryBot.create(:assessment)
      expect(assessment).to be_valid
      expect(assessment.requires_points).to be(false)
      expect(assessment.requires_submission).to be(false)
      expect(assessment.results_published?).to be(false)
    end

    it "creates a valid assessment with points" do
      assessment = FactoryBot.create(:assessment, :with_points)
      expect(assessment).to be_valid
      expect(assessment.requires_points).to be(true)
    end

    it "creates a valid published assessment" do
      assessment = FactoryBot.create(:assessment, :published)
      expect(assessment).to be_valid
      expect(assessment.results_published_at).to be_present
      expect(assessment.results_published?).to be(true)
    end

    it "creates a valid assessment with tasks" do
      assessment = FactoryBot.create(:assessment, :with_tasks)
      expect(assessment).to be_valid
      expect(assessment.tasks.count).to eq(3)
      expect(assessment.requires_points).to be(true)
    end
  end

  describe "validations" do
    it "validates lecture matches assessable lecture" do
      assignment = FactoryBot.create(:assignment, :with_lecture)
      different_lecture = FactoryBot.create(:lecture)
      assessment = FactoryBot.build(:assessment,
                                    assessable: assignment,
                                    lecture: different_lecture)
      expect(assessment).not_to be_valid
      error_key = "activerecord.errors.models.assessment/assessment" \
                  ".attributes.lecture_id.must_match_assessable_lecture"
      expect(assessment.errors[:lecture_id]).to include(I18n.t(error_key))
    end

    it "allows matching lecture" do
      assignment = FactoryBot.create(:assignment, :with_lecture)
      assessment = FactoryBot.build(:assessment,
                                    assessable: assignment,
                                    lecture: assignment.lecture)
      expect(assessment).to be_valid
    end

    describe "requires_submission locking after deadline" do
      let(:assignment) do
        FactoryBot.create(:assignment, :with_lecture,
                          deadline: 1.hour.from_now)
      end
      let(:assessment) do
        FactoryBot.create(:assessment,
                          assessable: assignment,
                          lecture: assignment.lecture,
                          requires_submission: true)
      end

      it "prevents changing requires_submission after deadline" do
        assessment
        Timecop.travel(2.hours.from_now) do
          assessment.requires_submission = false
          expect(assessment).to be_invalid
          expect(assessment.errors[:requires_submission]).to be_present
        end
      end

      it "allows saving without changing requires_submission" do
        assessment.total_points = 100
        expect(assessment).to be_valid
      end
    end
  end

  describe "delegation" do
    it "delegates title to assessable" do
      assignment = FactoryBot.create(:assignment, :with_lecture, title: "Homework 5")
      assessment = FactoryBot.create(:assessment, assessable: assignment,
                                                  lecture: assignment.lecture)
      expect(assessment.title).to eq("Homework 5")
    end
  end

  describe "publication" do
    let(:assessment) { FactoryBot.create(:assessment) }

    it "is not published by default" do
      expect(assessment.results_published?).to be(false)
      expect(assessment.results_published_at).to be_nil
    end

    it "is published when results_published_at is set" do
      assessment.update(results_published_at: Time.current)
      expect(assessment.results_published?).to be(true)
    end
  end
end
