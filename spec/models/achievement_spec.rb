require "rails_helper"

RSpec.describe(Achievement, type: :model) do
  describe "factory" do
    it "creates a valid boolean achievement" do
      achievement = FactoryBot.create(:achievement)
      expect(achievement).to be_valid
      expect(achievement).to be_boolean
      expect(achievement.threshold).to be_nil
    end

    it "creates a valid numeric achievement" do
      achievement = FactoryBot.create(:achievement, :numeric)
      expect(achievement).to be_valid
      expect(achievement).to be_numeric
      expect(achievement.threshold).to eq(12)
    end

    it "creates a valid percentage achievement" do
      achievement = FactoryBot.create(:achievement, :percentage)
      expect(achievement).to be_valid
      expect(achievement).to be_percentage
      expect(achievement.threshold).to eq(75.0)
    end
  end

  describe "associations" do
    it "belongs to a lecture" do
      achievement = FactoryBot.build(:achievement, lecture: nil)
      expect(achievement).not_to be_valid
    end
  end

  describe "validations" do
    it "requires title" do
      achievement = FactoryBot.build(:achievement, title: nil)
      expect(achievement).not_to be_valid
      expect(achievement.errors[:title]).to be_present
    end

    it "requires value_type" do
      achievement = FactoryBot.build(:achievement, value_type: nil)
      expect(achievement).not_to be_valid
      expect(achievement.errors[:value_type]).to be_present
    end

    it "requires threshold for numeric type" do
      achievement = FactoryBot.build(:achievement, :numeric, threshold: nil)
      expect(achievement).not_to be_valid
      expect(achievement.errors[:threshold]).to be_present
    end

    it "requires threshold for percentage type" do
      achievement = FactoryBot.build(:achievement, :percentage, threshold: nil)
      expect(achievement).not_to be_valid
    end

    it "rejects threshold for boolean type" do
      achievement = FactoryBot.build(:achievement, :boolean, threshold: 5)
      expect(achievement).not_to be_valid
      expect(achievement.errors[:threshold]).to be_present
    end

    it "rejects non-positive threshold" do
      achievement = FactoryBot.build(:achievement, :numeric, threshold: 0)
      expect(achievement).not_to be_valid
    end

    it "rejects percentage threshold above 100" do
      achievement = FactoryBot.build(:achievement, :percentage,
                                     threshold: 101)
      expect(achievement).not_to be_valid
    end

    it "allows percentage threshold of 100" do
      achievement = FactoryBot.build(:achievement, :percentage,
                                     threshold: 100)
      expect(achievement).to be_valid
    end

    it "allows percentage threshold of 0" do
      achievement = FactoryBot.build(:achievement, :percentage,
                                     threshold: 0)
      expect(achievement).to be_valid
    end
  end

  describe "enums" do
    it "defines value_type enum" do
      expect(described_class.value_types).to eq(
        "boolean" => 0, "numeric" => 1, "percentage" => 2
      )
    end
  end

  describe "validations" do
    it "refuses a second achievement with the same title in one lecture" do
      lecture = FactoryBot.create(:lecture)
      FactoryBot.create(:achievement, lecture: lecture, title: "Blackboard Talk")

      duplicate = FactoryBot.build(:achievement, lecture: lecture,
                                                 title: "Blackboard Talk")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:title]).to be_present
    end

    # The validation reads the sibling rows, so two simultaneous creates can
    # both find none. The index is what actually holds the rule.
    it "refuses it at the database level too" do
      lecture = FactoryBot.create(:lecture)
      FactoryBot.create(:achievement, lecture: lecture, title: "Blackboard Talk")

      duplicate = FactoryBot.build(:achievement, lecture: lecture,
                                                 title: "Blackboard Talk")

      expect { duplicate.save(validate: false) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows the same title in another lecture" do
      FactoryBot.create(:achievement, title: "Blackboard Talk")

      expect(FactoryBot.build(:achievement, title: "Blackboard Talk")).to be_valid
    end
  end

  describe "#met_by?" do
    context "when boolean" do
      let(:achievement) { FactoryBot.build(:achievement, :boolean) }

      it "is met by the recorded pass value" do
        expect(achievement.met_by?(Achievement::PASSED)).to be(true)
      end

      it "is not met by anything else" do
        expect(achievement.met_by?("fail")).to be(false)
        expect(achievement.met_by?("Pass")).to be(false)
      end
    end

    context "when numeric" do
      let(:achievement) { FactoryBot.build(:achievement, :numeric, threshold: 10) }

      it "is met at and above the threshold" do
        expect(achievement.met_by?("10")).to be(true)
        expect(achievement.met_by?("12")).to be(true)
      end

      it "is not met below it" do
        expect(achievement.met_by?("5")).to be(false)
      end

      it "compares decimals rather than truncating them" do
        achievement.threshold = 12.5
        expect(achievement.met_by?("12.6")).to be(true)
        expect(achievement.met_by?("12.4")).to be(false)
      end

      # A German keyboard writes it this way, and reading it as zero would
      # silently deny the student their exam admission.
      it "reads a decimal comma as a decimal point" do
        achievement.threshold = 3
        expect(achievement.met_by?("3,5")).to be(true)
      end

      it "refuses a value that is no number, and says so" do
        allow(Rails.logger).to receive(:warn)

        expect(achievement.met_by?("somewhat")).to be(false)
        expect(Rails.logger).to have_received(:warn)
      end
    end

    context "when percentage" do
      let(:achievement) { FactoryBot.build(:achievement, :percentage, threshold: 75) }

      it "is met at and above the threshold" do
        expect(achievement.met_by?("80.0")).to be(true)
      end

      it "is not met below it" do
        expect(achievement.met_by?("50.0")).to be(false)
      end

      it "reads a decimal comma here too" do
        expect(achievement.met_by?("75,5")).to be(true)
      end
    end

    it "is not met while nothing has been recorded" do
      achievement = FactoryBot.build(:achievement, :boolean)

      expect(achievement.met_by?(nil)).to be(false)
      expect(achievement.met_by?("")).to be(false)
      expect(achievement.met_by?("   ")).to be(false)
    end

    # Only reachable by writing past the validations, but the three readers
    # used to disagree about it — one guarded, two raised.
    it "is not met when a numeric achievement has lost its threshold" do
      achievement = FactoryBot.build(:achievement, :numeric, threshold: nil)

      expect(achievement.met_by?("5")).to be(false)
    end
  end
end
