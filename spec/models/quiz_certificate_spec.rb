require "rails_helper"

RSpec.describe(QuizCertificate, type: :model) do
  # test validations - this is done on the level of the parent Medium model

  it "has a valid factory" do
    expect(FactoryBot.build(:quiz_certificate)).to be_valid
  end

  it "is invalid without a quiz" do
    expect(FactoryBot.build(:quiz_certificate, quiz: nil)).to be_invalid
  end

  # test traits and subfactories

  describe "with user" do
    it "has a user" do
      quiz_certificate = FactoryBot.build(:quiz_certificate, :with_user)
      expect(quiz_certificate.user).to be_kind_of(User)
    end
  end

  describe "with valid quiz" do
    it "has a valid quiz" do
      quiz_certificate = FactoryBot.build(:quiz_certificate, :with_valid_quiz)
      expect(quiz_certificate.quiz).to be_valid
    end
  end

  # test callbacks

  it "gets a code afeter being created" do
    quiz_certificate = FactoryBot.create(:quiz_certificate, :with_valid_quiz)
    expect(quiz_certificate.code).to be_truthy
  end

  # test methods - NEEDS TO BE IMPLEMENTED
end
