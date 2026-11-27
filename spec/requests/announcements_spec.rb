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
      create(:announcement, lecture: nil, announcer: teacher, banner_active: true,
                            details: details)
    end

    it "escapes or strips script tags in main page announcements to prevent XSS" do
      get root_path
      expect(response).to be_successful
      expect(response.body).not_to include("<script>alert('main-xss')</script>")
    end
  end

  describe "POST /announcements" do
    it "never puts a lecture announcement on the banner" do
      post announcements_path,
           params: { announcement: { details: "Hi", lecture_id: lecture.id,
                                     banner_active: "1" } }
      expect(Announcement.last).to have_attributes(lecture: lecture, banner_active: false)
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

    it "does not create an announcement without a lecture, not even for an admin" do
      sign_in create(:confirmed_user, admin: true)
      expect do
        post(announcements_path, params: { announcement: { details: "Hi" } })
      end.not_to change(Announcement, :count)
    end

    it "does not create one for a lecture the user cannot edit" do
      sign_in create(:confirmed_user)
      expect do
        post(announcements_path,
             params: { announcement: { details: "Hi", lecture_id: lecture.id } })
      end.not_to change(Announcement, :count)
    end
  end
end
