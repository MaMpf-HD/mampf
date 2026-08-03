require "rails_helper"

RSpec.describe(Assessment::Assessment, type: :model) do
  describe "factory" do
    it "creates a valid default assessment" do
      assessment = FactoryBot.create(:assessment)
      expect(assessment).to be_valid
      expect(assessment.requires_points).to be(false)
      expect(assessment.requires_submission).to be(false)
      expect(assessment.results_published_at).to be_nil
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
        assessment
        Timecop.travel(2.hours.from_now) do
          assessment.results_published_at = Time.zone.now
          expect(assessment).to be_valid
        end
      end
    end
  end

  describe "#results_published?" do
    it "is false until a publication timestamp is set" do
      assessment = FactoryBot.create(:assessment)

      expect(assessment.results_published?).to be(false)
    end

    it "is true once one is" do
      assessment = FactoryBot.create(:assessment, :published)

      expect(assessment.results_published?).to be(true)
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

  describe "#effective_total_points" do
    let(:assessment) { FactoryBot.create(:assessment, :with_points) }

    it "sums the tasks' max_points" do
      FactoryBot.create(:assessment_task, assessment: assessment, max_points: 10)
      FactoryBot.create(:assessment_task, assessment: assessment, max_points: 15)

      expect(assessment.effective_total_points).to eq(25)
    end

    it "is 0 without tasks" do
      expect(assessment.effective_total_points).to eq(0)
    end

    # The task form builds a blank task into the association before saving it;
    # summing in Ruby would otherwise trip over its nil max_points.
    it "ignores a task that is only built, not saved" do
      FactoryBot.create(:assessment_task, assessment: assessment, max_points: 10)
      assessment.tasks.build

      expect(assessment.effective_total_points).to eq(10)
    end

    def count_queries(&)
      queries = 0
      counter = lambda { |*, payload|
        queries += 1 unless payload[:name].to_s.match?(/SCHEMA|TRANSACTION/)
      }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
      queries
    end

    # sum(:max_points) would issue one query per assessment even here, which is
    # what defeats the includes(:tasks) in the records controller.
    it "does not query when the association is preloaded" do
      FactoryBot.create(:assessment_task, assessment: assessment, max_points: 10)
      preloaded = Assessment::Assessment.where(id: assessment.id)
                                        .includes(:tasks).first

      expect(count_queries { preloaded.effective_total_points }).to eq(0)
    end

    # …and the other way round: without a preload it must aggregate in SQL
    # rather than load every task row.
    it "aggregates in SQL when the association is not loaded" do
      FactoryBot.create(:assessment_task, assessment: assessment, max_points: 10)
      fresh = Assessment::Assessment.find(assessment.id)

      expect(count_queries { fresh.effective_total_points }).to eq(1)
      expect(fresh.tasks).not_to be_loaded
    end
  end
end
