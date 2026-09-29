require "rails_helper"

RSpec.describe(Assessment::ResultNoticesController, type: :request) do
  let(:student) { create(:confirmed_user) }
  let(:exam) { create(:exam) }
  let!(:participation) do
    create(:assessment_participation, assessment: exam.assessment, user: student,
                                      status: :reviewed, grade_numeric: 2.0)
  end
  let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  it "closes the student's own new result and takes its block off the page" do
    exam.assessment.update!(results_published_at: Time.current)
    sign_in student

    patch result_seen_participation_path(participation), headers: turbo_stream_headers

    expect(participation.reload.result_seen_at).to be_present
    expect(response.body).to include(
      %(action="remove" target="#{NewResultsComponent.dom_id_for(participation)}")
    )
  end

  # Closed before it is out, the block would never show once it is.
  it "does not close a result that is not published yet" do
    sign_in student

    patch result_seen_participation_path(participation), headers: turbo_stream_headers

    expect(response).to have_http_status(:not_found)
    expect(participation.reload.result_seen_at).to be_nil
  end

  it "leaves someone else's result alone" do
    sign_in create(:confirmed_user)

    patch result_seen_participation_path(participation), headers: turbo_stream_headers

    expect(response).to have_http_status(:not_found)
    expect(participation.reload.result_seen_at).to be_nil
  end
end
