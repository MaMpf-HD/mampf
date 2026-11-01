require "rails_helper"

RSpec.describe(RosterRemovalModalComponent, type: :component) do
  let(:lecture) { create(:lecture) }
  let(:student) { create(:confirmed_user, name_in_tutorials: "Lina Berg") }
  let(:mo) { create(:tutorial, lecture: lecture, title: "Mo 10", skip_campaigns: true) }
  let(:waitlist) { create(:cohort, context: lecture, title: "Warteliste") }
  let(:campaign) { create(:registration_campaign, :open, campaignable: lecture) }

  def render_for(rosterable)
    render_inline(described_class.new(user: student, rosterable: rosterable, url: "/remove"))
  end

  def badges(rendered)
    rendered.css(".modal-body .badge").map { |badge| badge.text.squish }
  end

  def body_text(rendered)
    rendered.at_css(".modal-body").text.squish
  end

  before do
    lecture.add_user_to_roster!(student)
    mo.add_user_to_roster!(student)
  end

  describe "removal from the lecture" do
    let(:rendered) { render_for(lecture) }

    before do
      create(:exam, :without_campaign, lecture: lecture, title: "Final")
        .add_user_to_roster!(student)
      waitlist.add_user_to_roster!(student)
      create(:registration_user_registration, :pending, user: student,
                                                        registration_campaign: campaign)
    end

    it "names the groups, exam lists and registrations the person loses" do
      expect(badges(rendered)).to eq(["Mo 10", "Final", campaign.student_facing_title])
    end

    it "offers to keep each flexible group without enrollment, unticked" do
      box = rendered.at_css("input[type=checkbox][name='keep_list_ids[]']")

      expect(box["value"]).to eq(waitlist.id.to_s)
      expect(box["checked"]).to be_nil
      expect(rendered.at_css("label[for='#{box["id"]}']").text).to eq("Warteliste")
    end

    it "asks whether to notify the person, ticked" do
      expect(rendered.at_css("input[type=checkbox][name='notify']")["checked"]).to be_present
    end

    it "sends the removal to the given address" do
      expect(rendered.at_css("form[action='/remove'] input[name='_method']")["value"])
        .to eq("delete")
    end
  end

  describe "removal from a group" do
    it "says that removal from the last group ends the enrollment and names what stays" do
      waitlist.add_user_to_roster!(student)
      create(:registration_user_registration, :pending, user: student,
                                                        registration_campaign: campaign)

      rendered = render_for(mo)

      expect(body_text(rendered)).to include(I18n.t("roster.removal_modal.last_place_group"),
                                             I18n.t("roster.removal_modal.move_hint"))
      expect(badges(rendered)).to eq(
        ["Warteliste",
         I18n.t("roster.left.registered_for", title: campaign.student_facing_title)]
      )
    end

    # The exam list keeps them in the lecture.
    it "says the person stays enrolled while they are on an exam list" do
      create(:exam, :without_campaign, lecture: lecture).add_user_to_roster!(student)

      text = body_text(render_for(mo))

      expect(text).to include(I18n.t("roster.removal_modal.stays_enrolled"))
      expect(text).not_to include(I18n.t("roster.removal_modal.last_place_group"))
    end

    it "says the person stays enrolled while another group with enrollment remains" do
      create(:cohort, :enrollment, context: lecture).add_user_to_roster!(student)

      expect(body_text(render_for(mo))).to include(I18n.t("roster.removal_modal.stays_enrolled"))
    end

    it "says nothing about the enrollment for a flexible group without enrollment" do
      waitlist.add_user_to_roster!(student)

      text = body_text(render_for(waitlist))

      expect(text).not_to include(I18n.t("roster.removal_modal.stays_enrolled"))
      expect(text).not_to include(I18n.t("roster.removal_modal.last_place_group"))
    end
  end

  it "says that removal from the only exam list ends the enrollment, without the move hint" do
    exam = create(:exam, :without_campaign, lecture: lecture, title: "Final")
    exam.add_user_to_roster!(student)
    mo.remove_user_from_roster!(student)

    text = body_text(render_for(exam))

    expect(text).to include(I18n.t("roster.removal_modal.last_place_exam"))
    expect(text).not_to include(I18n.t("roster.removal_modal.move_hint"))
  end
end
