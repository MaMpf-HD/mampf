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

    it "counts a roster of a past term, whose lists still show the name" do
      past = create(:lecture, term: create(:term, year: 2020, season: "SS"))
      past.add_user_to_roster!(student)

      expect(places.any?).to be(true)
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

    it "is true with a recorded result, even without a roster" do
      create(:assessment_participation, :reviewed, user: student)

      expect(places.any?).to be(true)
    end

    it "leaves out a cohort outside a lecture, which names no lecture to give up" do
      create(:cohort, context: create(:course)).add_user_to_roster!(student)

      expect(places.any?).to be(false)
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

  describe "#results?" do
    it "is false without points, a grade or a decided admission" do
      create(:assessment_participation, :submitted, user: student)
      create(:student_performance_certification, :pending, user: student)

      expect(places.results?).to be(false)
    end

    it "is true once a sheet is marked for the student" do
      create(:assessment_participation, :reviewed, user: student)

      expect(places.results?).to be(true)
    end

    it "is true with a decided exam admission" do
      create(:student_performance_certification, :passed, :manual, user: student)

      expect(places.results?).to be(true)
    end
  end

  describe "#give_up!" do
    it "leaves every roster of the named lectures and withdraws their registrations" do
      tutorial = create(:tutorial, lecture: lecture)
      exam = create(:exam, lecture: lecture)
      [tutorial, exam, lecture].each { |rosterable| rosterable.add_user_to_roster!(student) }
      create(:registration_user_registration, :pending,
             user: student,
             registration_campaign: create(:registration_campaign, :open, campaignable: lecture))

      places.give_up!([lecture])

      expect(described_class.new(student).any?).to be(false)
    end

    it "counts a withdrawn confirmed registration off its item" do
      campaign = create(:registration_campaign, :closed, campaignable: lecture)
      registration = create(:registration_user_registration, :confirmed,
                            user: student, registration_campaign: campaign)
      item = registration.registration_item

      expect { places.give_up!([lecture]) }
        .to change { item.reload.confirmed_registrations_count }.by(-1)
    end

    it "sends no removal mail, since the student gave the places up themselves" do
      create(:tutorial, lecture: lecture).add_user_to_roster!(student)
      lecture.add_user_to_roster!(student)

      expect { places.give_up!([lecture]) }.not_to have_enqueued_mail
    end

    it "keeps a registration of a finished campaign" do
      finished = create(:registration_user_registration, :confirmed,
                        user: student,
                        registration_campaign: create(:registration_campaign, :completed,
                                                      campaignable: lecture))

      places.give_up!([lecture])

      expect(Registration::UserRegistration.exists?(finished.id)).to be(true)
    end

    it "gives up nothing when a place outside the named lectures remains" do
      tutorial = create(:tutorial, lecture: lecture)
      tutorial.add_user_to_roster!(student)
      other = create(:lecture)
      other.add_user_to_roster!(student)

      expect { places.give_up!([lecture]) }
        .to raise_error(described_class::PlacesChangedError)
      expect(tutorial.reload.members).to include(student)
      expect(other.reload.members).to include(student)
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

      expect { places.give_up!([talk.lecture, lecture]) }
        .to raise_error(Rosters::MaintenanceService::GradingDataPresentError)
      expect(tutorial.reload.members).to include(student)
    end
  end
end
