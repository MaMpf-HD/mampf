require "rails_helper"

RSpec.describe(Assessment::Assessment, type: :model) do
  describe "factory" do
    it "creates a valid default assessment" do
      assessment = FactoryBot.create(:assessment)
      expect(assessment).to be_valid
      expect(assessment.requires_points).to be(false)
      expect(assessment.requires_submission).to be(false)
      expect(assessment.status).to eq("draft")
    end

    it "creates a valid assessment with points" do
      assessment = FactoryBot.create(:assessment, :with_points)
      expect(assessment).to be_valid
      expect(assessment.requires_points).to be(true)
    end

    it "creates a valid open assessment" do
      assessment = FactoryBot.create(:assessment, :open)
      expect(assessment).to be_valid
      expect(assessment.status).to eq("open")
      expect(assessment.visible_from).to be_present
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
      expect(assessment.errors[:lecture_id]).to include(
        I18n.t("activerecord.errors.models.assessment/assessment.attributes.lecture_id.must_match_assessable_lecture")
      )
    end

    it "allows matching lecture" do
      assignment = FactoryBot.create(:assignment, :with_lecture)
      assessment = FactoryBot.build(:assessment,
                                    assessable: assignment,
                                    lecture: assignment.lecture)
      expect(assessment).to be_valid
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

  describe "status enum" do
    let(:assessment) { FactoryBot.create(:assessment) }

    it "supports all status values" do
      [:draft, :open, :closed, :graded, :archived].each do |status|
        assessment.status = status
        expect(assessment).to be_valid
      end
    end
  end
end
