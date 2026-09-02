require "rails_helper"

RSpec.describe(Seeds::CourseworkSupport, type: :model) do
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:assignment) { create(:assignment, lecture: lecture) }
  let(:assessment) { assignment.assessment }
  let(:tutorial) { create(:tutorial, lecture: lecture) }

  before do
    allow(described_class).to receive(:manuscript_copy) do
      File.open("#{SPEC_FILES}/manuscript.pdf", "rb")
    end
  end

  describe ".hand_in!" do
    # A file on record with no hand-in against it is a state the student's page
    # has to flag in red, and the seeds used to build one per team per sheet.
    it "tells the gradebook that the sheet was handed in" do
      user = create(:confirmed_user)
      participation = create(:assessment_participation, :pending,
                             assessment: assessment, user: user)

      described_class.hand_in!(assignment, tutorial, [user], correction: nil)

      expect(participation.reload.submitted_at).to be_present
    end

    # `Assessment::AbsenceHandling` clears the stamp when it sets either status,
    # and it means it: a stamp back would say the sheet was handed in after all.
    it "leaves somebody who was marked absent or exempt alone" do
      absent = create(:confirmed_user)
      exempt = create(:confirmed_user)
      absent_participation = create(:assessment_participation, :absent,
                                    assessment: assessment, user: absent)
      exempt_participation = create(:assessment_participation, :exempt,
                                    assessment: assessment, user: exempt)

      described_class.hand_in!(assignment, tutorial, [absent, exempt],
                               correction: nil)

      expect(absent_participation.reload.submitted_at).to be_nil
      expect(exempt_participation.reload.submitted_at).to be_nil
    end
  end
end
