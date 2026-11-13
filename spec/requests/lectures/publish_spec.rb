require "rails_helper"

RSpec.describe("Publishing a lecture", type: :request) do
  let(:lecture) { create(:lecture) }

  before { sign_in lecture.teacher }

  # The script is out from this moment on, and its "as of" date says so.
  it "stamps the release date on the media it publishes along" do
    script = create(:lecture_medium, :with_manuscript, teachable: lecture, sort: "Script")

    post publish_lecture_path(lecture),
         params: { medium: { publish_media: "1", released: "all" } }

    expect(script.reload.released).to eq("all")
    expect(script.manuscript_updated_at).to be_within(1.minute).of(Time.zone.now)
  end

  it "leaves the media unpublished unless asked to publish them" do
    script = create(:lecture_medium, :with_manuscript, teachable: lecture, sort: "Script")

    post publish_lecture_path(lecture), params: { medium: { publish_media: "0" } }

    expect(script.reload.released).to be_nil
    expect(script.released_at).to be_nil
  end
end
