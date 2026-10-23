require "rails_helper"

RSpec.describe(Assessment::ResultsRelease, type: :model) do
  describe "for an exam" do
    let(:exam) { create(:exam) }
    let(:release) { described_class.new(exam: exam) }

    it "offers nothing to publish while nobody has a result" do
      create(:assessment_participation, assessment: exam.assessment, status: :pending)

      expect(release.to_publish).to be_empty
    end

    it "offers the exam once somebody has one" do
      create(:assessment_participation, assessment: exam.assessment, status: :reviewed)

      expect(release.to_publish).to eq([exam.assessment])
    end

    it "offers a published exam again while its mail was never queued" do
      create(:assessment_participation, assessment: exam.assessment, status: :reviewed)
      exam.assessment.update!(results_published_at: Time.current)

      expect(release.to_publish).to eq([exam.assessment])

      exam.assessment.update!(results_notified_at: Time.current)
      expect(described_class.new(exam: exam).to_publish).to be_empty
    end
  end

  describe "for a seminar" do
    let(:seminar) { create(:lecture, sort: "seminar") }
    let(:speaker) { create(:confirmed_user) }
    let(:release) { described_class.new(seminar: seminar) }

    def graded_talk(*users)
      talk = create(:talk, lecture: seminar)
      users.each do |user|
        create(:assessment_participation, assessment: talk.assessment, user: user,
                                          status: :reviewed)
      end
      talk
    end

    it "counts a speaker of two talks as one person" do
      graded_talk(speaker)
      graded_talk(speaker, create(:confirmed_user))

      expect(release.people_count).to eq(2)
    end

    # A talk taken back and published again was announced the first time.
    it "counts only those who were not told before as mailed" do
      told = graded_talk(speaker)
      told.assessment.publish_results!
      told.assessment.withdraw_results!
      graded_talk(create(:confirmed_user))

      expect([release.people_count, release.mail_count]).to eq([2, 1])
    end
  end
end
