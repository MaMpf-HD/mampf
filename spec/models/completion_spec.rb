require "rails_helper"

RSpec.describe(Completion, type: :model) do
  describe "Factory validation" do
    it "has a valid default factory" do
      expect(FactoryBot.build(:completion)).to be_valid
    end

    it "is valid with the section trait" do
      expect(FactoryBot.build(:completion, :with_section)).to be_valid
    end

    it "is valid with the assignment trait" do
      expect(FactoryBot.build(:completion, :with_assignment)).to be_valid
    end
  end

  describe "Validations" do
    it "is invalid without a user" do
      completion = FactoryBot.build(:completion, user: nil)
      expect(completion).not_to be_valid
    end

    it "is invalid without a lecture" do
      completion = FactoryBot.build(:completion, lecture: nil)
      expect(completion).not_to be_valid
    end

    it "is invalid without a completable" do
      completion = FactoryBot.build(:completion, completable: nil)
      expect(completion).not_to be_valid
    end

    describe "uniqueness constraints" do
      let(:user) { FactoryBot.create(:user) }
      let(:section) { FactoryBot.create(:section) }
      let(:assignment) { FactoryBot.create(:assignment) }

      it "fails when a user completes the same section twice" do
        FactoryBot.create(:completion, user: user, completable: section)

        duplicate = FactoryBot.build(:completion, user: user, completable: section)

        expect(duplicate).not_to be_valid
      end

      xit "allows a user to complete a section and an assignment for the same lecture" do
        # TODO: implemment
      end
    end
  end
end
