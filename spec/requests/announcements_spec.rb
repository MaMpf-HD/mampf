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

    it "lets an admin set on_main_page" do
      sign_in create(:confirmed_user, admin: true)
      post announcements_path,
           params: { announcement: { details: "Hi", on_main_page: "1" } }
      expect(Announcement.last.on_main_page).to be(true)
    end
  end
end
