require "rails_helper"

RSpec.describe("Ending a registration campaign without allocation", type: :request) do
  let(:lecture) { create(:lecture) }
  let(:editor) { create(:confirmed_user) }
  let(:campaign) { create(:registration_campaign, :closed, campaignable: lecture, items_count: 1) }
  let!(:tutorial) { campaign.registration_items.first.registerable }
  let(:registrant) { create(:confirmed_user) }
  let(:rejected) { create(:confirmed_user) }

  before do
    create(:editable_user_join, user: editor, editable: lecture)
    item = campaign.registration_items.first
    create(:registration_user_registration, :confirmed, registration_campaign: campaign,
                                                        registration_item: item,
                                                        user: registrant)
    create(:registration_user_registration, :rejected, registration_campaign: campaign,
                                                       registration_item: item,
                                                       user: rejected)
  end

  def end_campaign(**fields)
    delete(end_without_allocation_registration_campaign_path(campaign),
           params: { notify: "1", delete_groups: "0", subject: "Ended",
                     body: "Nothing comes of it." }.merge(fields),
           as: :turbo_stream)
  end

  context "as an editor" do
    before { sign_in editor }

    it "offers the choice in the campaign's header" do
      get confirm_end_registration_campaign_path(campaign)

      form = Nokogiri::HTML(response.body)
      expect(form.at_css("input[name='notify'][type='checkbox']")["checked"]).to be_present
      expect(form.at_css("input[name='delete_groups'][value='0']")["checked"]).to be_present
    end

    # Rejected people had their answer; the mail goes to those still waiting.
    it "writes to those registered, then ends the campaign and keeps the group" do
      expect { end_campaign }
        .to change(StudentMessage, :count).by(1)
        .and(have_enqueued_mail(StudentMessageMailer, :student_message_email))

      expect(StudentMessage.last.recipient_emails).to eq([registrant.email])
      expect(Registration::Campaign.exists?(campaign.id)).to be(false)
      expect(tutorial.reload.skip_campaigns?).to be(true)
    end

    it "ends it silently with the group deleted" do
      expect { end_campaign(notify: "0", delete_groups: "1") }
        .not_to change(StudentMessage, :count)

      expect(Tutorial.exists?(tutorial.id)).to be(false)
    end

    it "sends nothing where the campaign may no longer end this way" do
      campaign.update_columns(last_allocation_calculated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations

      expect { end_campaign }.not_to change(StudentMessage, :count)

      expect(response.body).to include(I18n.t("registration.campaign.end.not_possible"))
      expect(campaign.reload.user_registrations.count).to eq(2)
    end
  end

  it "refuses whoever may not edit the lecture" do
    sign_in registrant

    expect { end_campaign }.not_to change(Registration::Campaign, :count)
  end
end
