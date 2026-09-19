require "rails_helper"

RSpec.describe(UserSubmissionJoin, type: :model) do
  it "has a valid factory" do
    expect(FactoryBot.build(:user_submission_join)).to be_valid
  end

  # test validations - INCOMPLETE

  it "is invalid without a user" do
    expect(FactoryBot.build(:user_submission_join, user: nil)).to be_invalid
  end

  describe "the team size" do
    it "refuses a member beyond the lecture's limit, in one sentence per language" do
      lecture = FactoryBot.create(:lecture, submission_max_team_size: 1)
      assignment = FactoryBot.create(:assignment, lecture: lecture)
      tutorial = FactoryBot.create(:tutorial, lecture: lecture)
      submission = FactoryBot.create(:submission, assignment: assignment, tutorial: tutorial)
      UserSubmissionJoin.create!(submission: submission, user: FactoryBot.create(:confirmed_user))
      join = FactoryBot.build(:user_submission_join, submission: submission.reload,
                                                     user: FactoryBot.create(:confirmed_user))

      expect(join).to be_invalid
      I18n.available_locales.each do |locale|
        message = I18n.with_locale(locale) { join.tap(&:valid?).errors[:base].join }
        expect(message).not_to include(":")
        expect(message.lines.size).to eq(1)
      end
    end
  end
end
