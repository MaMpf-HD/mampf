require "rails_helper"

RSpec.describe("Site announcements", type: :request) do
  let(:admin) { create(:confirmed_user, admin: true) }
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, teacher: teacher) }
  let(:editor) do
    create(:confirmed_user).tap { |u| create(:editable_user_join, user: u, editable: lecture) }
  end
  let!(:site_announcement) do
    create(:announcement, lecture: nil, announcer: admin, details: "Maintenance",
                          banner_active: false)
  end

  context "as an admin" do
    before { sign_in admin }

    it "lists the site-wide announcements only" do
      create(:announcement, lecture: lecture, details: "Lecture news")

      get site_announcements_path

      expect(response).to be_successful
      expect(response.body).to include("Maintenance")
      expect(response.body).not_to include("Lecture news")
    end

    it "publishes one as the banner" do
      post site_announcements_path,
           params: { announcement: { details: "Maintenance tonight" } },
           as: :turbo_stream

      expect(Announcement.last).to have_attributes(lecture: nil, banner_active: true)
      expect(response.body).to include("site-announcement-banner")
      expect(response.body).to include("Maintenance tonight")
    end

    it "renders the form into the list's frame, without the page around it" do
      get new_site_announcement_path,
          headers: { "Turbo-Frame" => "new_site_announcement" }

      expect(response).to be_successful
      expect(response.body).to include('<turbo-frame id="new_site_announcement">')
      expect(response.body).not_to include("<head>")
    end

    it "sends a direct visit of the form back to the list" do
      get new_site_announcement_path
      expect(response).to redirect_to(site_announcements_path)
    end

    it "notifies nobody about it, neither in MaMpf nor by mail" do
      create_list(:confirmed_user, 2, email_for_announcement: true)
      create(:confirmed_user, email_for_announcement: true).bookmark_lecture!(lecture)

      notifications_before = Notification.count

      expect do
        post(site_announcements_path,
             params: { announcement: { details: "Maintenance tonight" } },
             as: :turbo_stream)
      end.not_to have_enqueued_mail

      expect(Announcement.last.details).to include("Maintenance tonight")
      expect(Notification.count).to eq(notifications_before)
    end

    it "shows the inline form again for an empty one" do
      expect do
        post(site_announcements_path, params: { announcement: { details: "" } },
                                      headers: { "Turbo-Frame" => "new_site_announcement" })
      end.not_to change(Announcement, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('<turbo-frame id="new_site_announcement">')
    end

    it "puts one up as the banner and swaps row and banner via Turbo Stream" do
      patch site_announcement_path(site_announcement),
            params: { announcement: { banner_active: "1" } }, as: :turbo_stream

      expect(site_announcement.reload.banner_active).to be(true)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include(ActionView::RecordIdentifier.dom_id(site_announcement))
      expect(response.body).to include("site-announcement-banner")
    end

    it "takes one down again" do
      site_announcement.update!(banner_active: true)

      patch site_announcement_path(site_announcement),
            params: { announcement: { banner_active: "0" } }, as: :turbo_stream

      expect(site_announcement.reload.banner_active).to be(false)
    end

    it "cannot put a lecture announcement on the banner" do
      lecture_announcement = create(:announcement, lecture: lecture)

      patch site_announcement_path(lecture_announcement),
            params: { announcement: { banner_active: "1" } }

      expect(lecture_announcement.reload.banner_active).to be(false)
    end
  end

  [:teacher, :editor].each do |role|
    context "as a lecture's #{role}" do
      before { sign_in public_send(role) }

      it "cannot see the list" do
        get site_announcements_path
        expect(response).to redirect_to(root_url)
      end

      it "cannot open the form" do
        get new_site_announcement_path
        expect(response).to redirect_to(root_url)
      end

      it "cannot create one" do
        expect do
          post(site_announcements_path, params: { announcement: { details: "Hi" } })
        end.not_to change(Announcement, :count)
      end

      it "cannot put one up as the banner" do
        patch site_announcement_path(site_announcement),
              params: { announcement: { banner_active: "1" } }
        expect(site_announcement.reload.banner_active).to be(false)
      end
    end
  end
end
