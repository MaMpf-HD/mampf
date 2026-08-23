require "rails_helper"

RSpec.describe("Lecture deletion", type: :request) do
  let(:lecture) { create(:lecture) }
  let(:editor) { create(:confirmed_user) }

  before do
    create(:editable_user_join, user: editor, editable: lecture)
    sign_in editor
  end

  context "without registration processes" do
    it "deletes the lecture and its notifications" do
      notification = create(:notification, notifiable: lecture)

      expect { delete(lecture_path(lecture)) }.to change(Lecture, :count).by(-1)

      expect(response).to redirect_to(administration_path)
      expect(Notification.exists?(notification.id)).to be(false)
    end
  end

  context "with an assignment that has uploads" do
    before do
      tutorial = create(:tutorial, lecture: lecture)
      create(:valid_submission, :with_manuscript,
             tutorial: tutorial, assignment: create(:assignment, lecture: lecture))
    end

    it "keeps the lecture and says so instead of raising" do
      expect { delete(lecture_path(lecture)) }.not_to change(Lecture, :count)

      expect(response).to redirect_to(edit_lecture_path(lecture, tab: "groups"))
      expect(flash[:alert]).to eq(I18n.t("controllers.lectures.destruction_failed"))
    end
  end

  context "with an empty assignment" do
    before { create(:assignment, lecture: lecture) }

    it "deletes the lecture together with it" do
      expect { delete(lecture_path(lecture)) }.to change(Lecture, :count).by(-1)
                                                                         .and(change(Assignment,
                                                                                     :count).by(-1))
    end
  end

  # A campaign exists because of its lecture. Deleting the lecture is guarded by
  # the lecture's own rules, and what only lives underneath it goes along.
  context "with a campaign that students already registered for" do
    let!(:campaign) { create(:registration_campaign, :open, campaignable: lecture) }

    before do
      create(:registration_user_registration,
             registration_campaign: campaign,
             registration_item: campaign.registration_items.first)
    end

    it "deletes the lecture, the campaign and its registrations" do
      delete(lecture_path(lecture))

      expect(Lecture.exists?(lecture.id)).to be(false)
      expect(Registration::Campaign.exists?(campaign.id)).to be(false)
      expect(Registration::UserRegistration.count).to eq(0)
    end
  end

  context "with a completed campaign" do
    let!(:campaign) { create(:registration_campaign, :completed, campaignable: lecture) }

    it "deletes the lecture together with it" do
      delete(lecture_path(lecture))

      expect(Lecture.exists?(lecture.id)).to be(false)
      expect(Registration::Campaign.exists?(campaign.id)).to be(false)
    end
  end

  context "with a campaign that another event series requires" do
    let!(:campaign) { create(:registration_campaign, :with_items, campaignable: lecture) }
    let!(:notification) { create(:notification, notifiable: lecture) }

    before do
      create(:registration_policy, :prerequisite_campaign,
             registration_campaign: create(:registration_campaign),
             config: { "prerequisite_campaign_id" => campaign.id })
    end

    it "keeps the lecture and says which case it is" do
      expect { delete(lecture_path(lecture)) }.not_to change(Lecture, :count)

      expect(response).to redirect_to(edit_lecture_path(lecture, tab: "groups"))
      expect(flash[:alert])
        .to eq(I18n.t("controllers.lectures.destruction_failed_prerequisite"))
    end

    it "keeps the lecture's notifications" do
      delete(lecture_path(lecture))

      expect(Notification.exists?(notification.id)).to be(true)
    end

    # discard_blocker reports the first reason it finds, and registrations come
    # first - but the cascade walks past those, so the message must not.
    it "says so even when the campaign also has registrations" do
      campaign.update!(status: :open)
      create(:registration_user_registration,
             registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      delete(lecture_path(lecture))

      expect(Lecture.exists?(lecture.id)).to be(true)
      expect(flash[:alert])
        .to eq(I18n.t("controllers.lectures.destruction_failed_prerequisite"))
    end
  end

  context "with campaigns that nobody has touched yet" do
    let!(:draft) { create(:registration_campaign, campaignable: lecture) }
    let!(:running) { create(:registration_campaign, :open, campaignable: lecture) }

    it "deletes the lecture together with them" do
      expect { delete(lecture_path(lecture)) }.to change(Lecture, :count).by(-1)

      expect(response).to redirect_to(administration_path)
      expect(Registration::Campaign.where(id: [draft.id, running.id])).to be_empty
    end
  end
end
