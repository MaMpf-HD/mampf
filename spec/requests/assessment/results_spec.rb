require "rails_helper"

RSpec.describe(Assessment::ResultsController, type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  describe "an exam's results" do
    let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
    let(:exam) { create(:exam, lecture: lecture) }
    let(:assessment) { exam.assessment }

    before do
      create(:assessment_participation, assessment: assessment, status: :reviewed)
      create(:assessment_participation, assessment: assessment, status: :pending)
    end

    def publish
      patch(assessment_assessment_results_path(assessment), headers: turbo_stream_headers)
    end

    it "are published by the teacher, who is told so in place" do
      sign_in teacher

      expect { publish }
        .to have_enqueued_mail(Assessment::ResultsMailer, :published_email).once

      expect(assessment.reload.results_published?).to be(true)
      release = Nokogiri::HTML(response.body)
                        .at_css("turbo-stream[target=#{ResultsReleaseComponent::ID}]")
      expect(release.text).to include("Take back")
    end

    it "are taken back by the teacher" do
      assessment.publish_results!
      sign_in teacher

      delete assessment_assessment_results_path(assessment), headers: turbo_stream_headers

      expect(assessment.reload.results_published?).to be(false)
    end

    it "cannot be published by a tutor of the lecture" do
      tutor = create(:confirmed_user)
      create(:tutorial, lecture: lecture, tutors: [tutor])
      sign_in tutor

      publish

      expect(assessment.reload.results_published?).to be(false)
    end

    it "cannot be published by a student" do
      sign_in create(:confirmed_user)

      publish

      expect(assessment.reload.results_published?).to be(false)
    end
  end

  # What a tutor saves on a sheet the student sees at once; there is nothing
  # to publish.
  it "refuses to publish a sheet" do
    lecture = create(:lecture, teacher: teacher)
    assignment = create(:assignment, lecture: lecture)
    sign_in teacher

    patch assessment_assessment_results_path(assignment.assessment),
          headers: turbo_stream_headers

    expect(response).to have_http_status(:not_found)
    expect(assignment.assessment.reload.results_published?).to be(false)
  end

  describe "a seminar's talk results" do
    let(:seminar) { create(:lecture, :released_for_all, sort: "seminar", teacher: teacher) }

    def talk_with(status)
      talk = create(:talk, lecture: seminar)
      create(:assessment_participation, assessment: talk.assessment, status: status)
      talk
    end

    it "are published for the talks that are fully graded" do
      graded = talk_with(:reviewed)
      open = talk_with(:pending)
      sign_in teacher

      patch assessment_talk_results_path(lecture_id: seminar.id), headers: turbo_stream_headers

      expect(graded.assessment.reload.results_published?).to be(true)
      expect(open.assessment.reload.results_published?).to be(false)
    end

    it "are taken back together" do
      talks = [talk_with(:reviewed), talk_with(:reviewed)]
      talks.each { |talk| talk.assessment.publish_results! }
      sign_in teacher

      delete assessment_talk_results_path(lecture_id: seminar.id), headers: turbo_stream_headers

      expect(talks.map { |talk| talk.assessment.reload.results_published? }).to eq([false, false])
    end
  end
end
