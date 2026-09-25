require "rails_helper"

RSpec.describe(Rosters::UserPlaces) do
  let(:student) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:places) { described_class.new(student) }

  describe "#any?" do
    it "is false for a student without a roster or a registration" do
      expect(places.any?).to be(false)
    end

    it "is true on a tutorial, a talk, a cohort, an exam or a lecture roster" do
      rosterables = [create(:tutorial, lecture: lecture), create(:talk),
                     create(:cohort, context: lecture), create(:exam, lecture: lecture),
                     lecture]

      rosterables.each do |rosterable|
        rosterable.add_user_to_roster!(student)
        expect(described_class.new(student).any?).to be(true), rosterable.class.name
        rosterable.remove_user_from_roster!(student)
      end
    end

    it "is true with a registration in a campaign that has not finished" do
      [:open, :closed, :processing].each do |status|
        campaign = create(:registration_campaign, status, campaignable: lecture)
        registration = create(:registration_user_registration, :pending,
                              user: student, registration_campaign: campaign)

        expect(described_class.new(student).any?).to be(true), status.to_s
        registration.destroy
      end
    end

    it "is false for a rejected registration or one in a finished campaign" do
      open_campaign = create(:registration_campaign, :open)
      finished = create(:registration_campaign, :completed)
      create(:registration_user_registration, :rejected,
             user: student, registration_campaign: open_campaign)
      create(:registration_user_registration, :confirmed,
             user: student, registration_campaign: finished)

      expect(places.any?).to be(false)
    end
  end

  describe "#lectures" do
    it "names each lecture once, for its groups and its registrations alike" do
      create(:tutorial, lecture: lecture).add_user_to_roster!(student)
      lecture.add_user_to_roster!(student)
      other = create(:lecture)
      create(:registration_user_registration, :pending,
             user: student,
             registration_campaign: create(:registration_campaign, :open, campaignable: other))

      expect(places.lectures).to contain_exactly(lecture, other)
    end
  end

  describe "#give_up!" do
    it "leaves every roster and withdraws the running registrations" do
      tutorial = create(:tutorial, lecture: lecture)
      exam = create(:exam, lecture: lecture)
      [tutorial, exam, lecture].each { |rosterable| rosterable.add_user_to_roster!(student) }
      create(:registration_user_registration, :pending,
             user: student, registration_campaign: create(:registration_campaign, :open))

      places.give_up!

      expect(described_class.new(student).any?).to be(false)
    end

    it "keeps a registration of a finished campaign" do
      finished = create(:registration_user_registration, :confirmed,
                        user: student,
                        registration_campaign: create(:registration_campaign, :completed))

      places.give_up!

      expect(Registration::UserRegistration.exists?(finished.id)).to be(true)
    end

    it "gives up nothing when a talk already holds a grade for the student" do
      talk = create(:talk)
      talk.add_user_to_roster!(student)
      tutorial = create(:tutorial, lecture: lecture)
      tutorial.add_user_to_roster!(student)
      talk.ensure_assessment!(requires_points: false)
      Assessment::Participation.create!(assessment: talk.assessment, user: student)
                               .update!(grade_numeric: 2.0, grader: create(:confirmed_user),
                                        graded_at: Time.current, status: :reviewed)

      expect { places.give_up! }
        .to raise_error(Rosters::MaintenanceService::GradingDataPresentError)
      expect(tutorial.reload.members).to include(student)
    end
  end
end
