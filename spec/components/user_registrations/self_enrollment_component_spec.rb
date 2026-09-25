require "rails_helper"

RSpec.describe(SelfEnrollmentComponent, type: :component) do
  around do |example|
    I18n.with_locale(:en) { example.run }
  end

  let(:lecture) { create(:lecture, :released_for_all) }
  let(:user) { create(:confirmed_user) }
  let(:current) do
    create(:tutorial, lecture: lecture, title: "Monday Tutorial",
                      self_materialization_mode: "add_and_remove")
  end
  let(:destination) do
    create(:tutorial, lecture: lecture, title: "Friday Tutorial",
                      self_materialization_mode: "add_and_remove")
  end

  before { current.add_user_to_roster!(user) }

  def render_body
    with_controller_class(Lectures::HomeController) do
      allow(vc_test_controller).to receive(:current_user).and_return(user)
      render_inline(described_class.new(lecture: lecture, user: user,
                                        rosterables: [current, destination], part: :body))
    end
  end

  it "offers to switch to an open group" do
    expect(render_body.css("button[aria-label='Switch to Friday Tutorial']")).to be_present
  end

  it "does not offer to switch to a group a running campaign has locked" do
    allow(destination).to receive(:locked?).and_return(true)

    expect(render_body.css("button[aria-label='Switch to Friday Tutorial']")).to be_empty
  end
end
