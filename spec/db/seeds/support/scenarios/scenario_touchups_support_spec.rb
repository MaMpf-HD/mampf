require "rails_helper"

RSpec.describe(Scenarios::ScenarioTouchupsSupport, type: :model) do
  let(:teacher) { create(:confirmed_user, email: Scenarios::LectureSupport::TEACHER_EMAIL) }
  let(:active_term) { create(:term, :active, :summer) }

  describe ".add_running_campaigns!" do
    it "opens a tutorial campaign on a lecture in the term after the active one" do
      teacher
      active_term

      described_class.add_running_campaigns!

      next_term = Term.find_by(year: active_term.year, season: "WS")
      lecture = Lecture.find_by(term: next_term, sort: "lecture")
      expect(lecture).to be_present
      expect(Registration::Campaign.where(campaignable: lecture).sole)
        .to be_open
    end

    it "does not open a second campaign when one already exists" do
      teacher
      active_term
      described_class.add_running_campaigns!

      expect { described_class.add_running_campaigns! }
        .not_to change(Registration::Campaign, :count)
    end
  end

  describe ".settle_current_term_campaigns!" do
    it "discards a campaign on the active term's lecture that has not completed" do
      lecture = create(:lecture, term: active_term)
      campaign = create(:registration_campaign, :open, campaignable: lecture)

      described_class.settle_current_term_campaigns!

      expect(Registration::Campaign.exists?(campaign.id)).to be(false)
    end

    it "leaves a completed campaign alone" do
      lecture = create(:lecture, term: active_term)
      campaign = create(:registration_campaign, :completed, campaignable: lecture)

      described_class.settle_current_term_campaigns!

      expect(Registration::Campaign.exists?(campaign.id)).to be(true)
    end
  end

  describe ".extend_open_deadlines!" do
    it "pushes an open campaign's deadline a year out" do
      campaign = create(:registration_campaign, :open, registration_deadline: 3.days.from_now)

      described_class.extend_open_deadlines!

      expect(campaign.reload.registration_deadline).to be_within(1.day).of(1.year.from_now)
    end
  end

  describe ".stage_password_policy!" do
    it "puts the two stale-password accounts back on the outdated policy" do
      described_class::STALE_PASSWORD_ACCOUNTS.each do |email|
        create(:confirmed_user, email: email,
                                password_policy_version: User::CURRENT_PASSWORD_POLICY_VERSION)
      end

      described_class.stage_password_policy!

      described_class::STALE_PASSWORD_ACCOUNTS.each do |email|
        expect(User.find_by(email: email).password_policy_version).to eq(0)
      end
    end

    it "leaves every other account on the current policy" do
      other = create(:confirmed_user, email: "student1@mampf.edu",
                                      password_policy_version: User::CURRENT_PASSWORD_POLICY_VERSION)

      described_class.stage_password_policy!

      expect(other.reload.password_policy_version).to eq(User::CURRENT_PASSWORD_POLICY_VERSION)
    end
  end
end
