require "rails_helper"

RSpec.describe("Announcements", type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, teacher: teacher) }
  let!(:announcement) do
    create(:announcement, lecture: lecture, announcer: teacher,
                          details: "<div id='test-xss-xyz123'><script>alert('xss')</script></div>")
  end

  before do
    sign_in teacher
  end

  describe "GET /lectures/:id/edit" do
    it "escapes or strips script tags in announcements to prevent XSS" do
      get edit_lecture_path(lecture)
      if response.body.include?("<script>alert('xss')</script>")
        lines = response.body.split("\n")
        idx = lines.index { |l| l.include?("xss-xyz123") }
        if idx
          puts "LEAKED AT LINE #{idx}:"
          puts lines[[0, idx - 5].max..(idx + 5)].join("\n")
        else
          puts "xss-xyz123 not found, but script is present!"
        end
      end
      expect(response).to be_successful
      expect(response.body).not_to include("<script>alert('xss')</script>")
    end
  end

  describe "GET /" do
    let!(:main_announcement) do
      details = "<div id='test-main-xss-xyz123'><script>alert('main-xss')</script></div>"
      create(:announcement, lecture: nil, announcer: teacher, on_main_page: true,
                            details: details)
    end

    it "escapes or strips script tags in main page announcements to prevent XSS" do
      get root_path
      expect(response).to be_successful
      expect(response.body).not_to include("<script>alert('main-xss')</script>")
    end
  end

  describe "POST /announcements" do
    it "ignores on_main_page from a non-admin editor" do
      post announcements_path,
           params: { announcement: { details: "Hi", lecture_id: lecture.id,
                                     on_main_page: "1" } }
      expect(Announcement.last.on_main_page).to be_falsey
    end

    it "notifies who bookmarked, sits on a roster or has a registration running" do
      bookmarker, member, applicant, reader = create_list(:confirmed_user, 4)
      bookmarker.bookmark_lecture!(lecture)
      Rosters::MaintenanceService.new.add_user!(member, create(:tutorial, lecture: lecture))
      campaign = create(:registration_campaign, :open, :with_items, campaignable: lecture)
      create(:registration_user_registration, :pending,
             user: applicant, registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      post announcements_path, params: { announcement: { details: "Hi", lecture_id: lecture.id } }

      recipients = Notification.where(notifiable: Announcement.last).map(&:recipient)
      expect(recipients).to contain_exactly(bookmarker, member, applicant)
      expect(recipients).not_to include(reader)
    end

    it "publishes a site-wide announcement from an admin as the banner" do
      sign_in create(:confirmed_user, admin: true)
      post announcements_path,
           params: { announcement: { details: "Maintenance tonight" } },
           as: :turbo_stream
      expect(Announcement.last.on_main_page).to be(true)
      expect(response.body).to include("site-announcement-banner")
      expect(response.body).to include("Maintenance tonight")
    end

    it "shows the inline form again for an empty site-wide announcement" do
      sign_in create(:confirmed_user, admin: true)
      expect do
        post(announcements_path, params: { announcement: { details: "" } })
      end.not_to change(Announcement, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("new_announcement")
    end
  end

  describe "toggling a site-wide announcement" do
    let(:admin) { create(:confirmed_user, admin: true) }
    let!(:site_announcement) do
      create(:announcement, lecture: nil, announcer: admin, details: "Maintenance",
                            on_main_page: false)
    end

    before { sign_in admin }

    it "puts it up as the banner and swaps row and banner via Turbo Stream" do
      patch announcement_path(site_announcement),
            params: { announcement: { on_main_page: "1" } }, as: :turbo_stream

      expect(site_announcement.reload.on_main_page).to be(true)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include(ActionView::RecordIdentifier.dom_id(site_announcement))
      expect(response.body).to include("site-announcement-banner")
      expect(response.body).to include("Maintenance")
    end

    it "takes it down again" do
      site_announcement.update(on_main_page: true)

      patch announcement_path(site_announcement),
            params: { announcement: { on_main_page: "0" } }, as: :turbo_stream

      expect(site_announcement.reload.on_main_page).to be(false)
    end
  end

  describe "site-wide announcements as a teacher or editor" do
    let(:editor) do
      create(:confirmed_user).tap { |u| create(:editable_user_join, user: u, editable: lecture) }
    end

    [:teacher, :editor].each do |role|
      context "as the lecture's #{role}" do
        before { sign_in public_send(role) }

        it "cannot create one without a lecture" do
          expect do
            post(announcements_path, params: { announcement: { details: "Hi" } })
          end.not_to change(Announcement, :count)
        end

        it "cannot create one via an unknown lecture id" do
          expect do
            post(announcements_path,
                 params: { announcement: { details: "Hi", lecture_id: -1 } })
          end.not_to change(Announcement, :count)
        end

        it "cannot open the form for one" do
          get new_announcement_path
          expect(response).to redirect_to(root_url)
        end

        it "cannot see the list" do
          get announcements_path
          expect(response).to redirect_to(root_url)
        end

        it "cannot put an announcement up as the banner" do
          patch announcement_path(announcement),
                params: { announcement: { on_main_page: "1" } }
          expect(announcement.reload.on_main_page).to be_falsey
        end

        it "creates a lecture announcement that is not on the banner" do
          post announcements_path,
               params: { announcement: { details: "Hi", lecture_id: lecture.id } }
          expect(Announcement.last).to have_attributes(lecture: lecture,
                                                       on_main_page: false)
        end
      end
    end
  end
end
