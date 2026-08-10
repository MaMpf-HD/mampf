require "rails_helper"

RSpec.describe("Vignettes::Codenames", type: :request) do
  let(:lecture) { create(:lecture, sort: "vignettes") }
  let(:participant) { create(:confirmed_user) }
  let(:outsider) { create(:confirmed_user) }

  before { participant.lectures << lecture }

  def set_codename_params
    { pseudonym: "codename-x" }
  end

  it "lets a participant of the vignettes lecture set their codename" do
    sign_in participant
    expect do
      post(set_lecture_codename_path(lecture), params: set_codename_params)
    end.to change(Vignettes::Codename, :count).by(1)
  end

  it "does not let a non-participant set a codename" do
    sign_in outsider
    expect do
      post(set_lecture_codename_path(lecture), params: set_codename_params)
    end.not_to change(Vignettes::Codename, :count)
  end
end
