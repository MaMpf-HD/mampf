require "rails_helper"

RSpec.describe("Ending a registration campaign without allocation", type: :request) do
  let(:lecture) { create(:lecture) }
  let(:editor) { create(:confirmed_user) }
  let(:campaign) { create(:registration_campaign, :closed, campaignable: lecture, items_count: 1) }
  let!(:tutorial) { campaign.registration_items.first.registerable }
  let(:item) { campaign.registration_items.first }
  let(:registrant) { create(:confirmed_user) }
  let(:rejected) { create(:confirmed_user) }

  before do
    create(:editable_user_join, user: editor, editable: lecture)
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

  def expect_nothing_changed
    expect(Registration::Campaign.exists?(campaign.id)).to be(true)
    expect(campaign.user_registrations.count).to eq(2)
    expect(Tutorial.exists?(tutorial.id)).to be(true)
    expect(StudentMessage.count).to eq(0)
    expect(ActionMailer::Base.deliveries).to be_empty
    expect(enqueued_jobs).to be_empty
  end

  context "as an editor" do
    before { sign_in editor }

    # Rejected people had their answer; the mail goes to those still waiting.
    it "writes to those registered, then ends the campaign and keeps the group" do
      pending_one = create(:confirmed_user)
      create(:registration_user_registration, :pending, registration_campaign: campaign,
                                                        registration_item: item,
                                                        user: pending_one)

      expect { end_campaign }
        .to change(StudentMessage, :count).by(1)
        .and(have_enqueued_mail(StudentMessageMailer, :student_message_email))

      expect(StudentMessage.last.recipient_emails)
        .to contain_exactly(registrant.email, pending_one.email)
      expect(Registration::Campaign.exists?(campaign.id)).to be(false)
      expect(tutorial.reload.skip_campaigns?).to be(true)
    end

    it "ends it silently with the group deleted" do
      expect { end_campaign(notify: "0", delete_groups: "1") }
        .not_to change(StudentMessage, :count)

      expect(Tutorial.exists?(tutorial.id)).to be(false)
    end

    it "ends it without a mail where only rejected people are left" do
      campaign.user_registrations.where(user: registrant).destroy_all

      expect { end_campaign }.not_to have_enqueued_mail(StudentMessageMailer)

      expect(Registration::Campaign.exists?(campaign.id)).to be(false)
    end

    it "keeps everything when the mail lacks a subject" do
      end_campaign(subject: "")

      subject_name = StudentMessage.human_attribute_name(:subject)
      expect(response.body).to include(CGI.escapeHTML(subject_name))
      expect_nothing_changed
    end

    it "keeps everything and sends nothing where the campaign may no longer end this way" do
      campaign.update_columns(last_allocation_calculated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations

      end_campaign

      expect(response.body).to include(I18n.t("registration.campaign.end.not_possible"))
      expect_nothing_changed
    end

    # Somebody joins the group between the check and the deletion: the group's
    # own guard refuses, and the whole ending is undone.
    it "keeps everything and names the group that turned out to hold members" do
      allow_any_instance_of(Registration::Campaign)
        .to receive(:groups_blocking_deletion) do
        tutorial.add_user_to_roster!(create(:confirmed_user))
        []
      end

      end_campaign(delete_groups: "1")

      expect(response.body).to include(tutorial.title)
      expect_nothing_changed
    end

    it "does not offer the choice for a campaign that may not end this way" do
      campaign.update_columns(last_allocation_calculated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations

      get confirm_end_registration_campaign_path(campaign), as: :turbo_stream

      expect(response.body).to include(I18n.t("registration.campaign.end.not_possible"))
    end
  end

  it "refuses whoever may not edit the lecture" do
    sign_in registrant

    end_campaign

    expect(response).to redirect_to(root_path)
    expect_nothing_changed
  end
end
