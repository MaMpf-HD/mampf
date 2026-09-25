require "rails_helper"

RSpec.describe("Lectures::Home", type: :request) do
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: editor) }

  describe "GET /lectures/:id/home" do
    it "renders the teacher's intro text" do
      lecture.update!(home_intro: "<div>Welcome to the seminar</div>")
      sign_in student

      get lecture_home_path(lecture)

      expect(response.body).to include("Welcome to the seminar")
    end

    it "shows the staff empty-state when no intro is authored yet" do
      sign_in editor

      get lecture_home_path(lecture)

      expect(response.body).to include('data-testid="lecture-home-intro-empty"')
    end

    it "still shows the staff empty-state when the intro is only blank markup" do
      lecture.update!(home_intro: "<div><br></div>")
      sign_in editor

      get lecture_home_path(lecture)

      expect(response.body).to include('data-testid="lecture-home-intro-empty"')
      expect(response.body).not_to include('data-testid="lecture-home-intro"')
    end

    it "still shows students the fallback when the intro is only blank markup" do
      lecture.update!(home_intro: "<div><br></div>")
      sign_in student

      get lecture_home_path(lecture)

      expect(response.body).to include('data-testid="lecture-home-fallback-card"')
    end

    it "does not show the staff empty-state to a plain student" do
      sign_in student

      get lecture_home_path(lecture)

      expect(response.body)
        .not_to include('data-testid="lecture-home-intro-empty"')
    end
  end

  describe "the \"start here\" fallback card" do
    it "shows when the page is empty for a student" do
      sign_in student

      get lecture_home_path(lecture)

      expect(response.body)
        .to include('data-testid="lecture-home-fallback-card"')
      expect(response.body).to include(lecture_outline_path(lecture))
    end

    it "is hidden once the teacher has authored an intro" do
      lecture.update!(home_intro: "<div>Welcome to the seminar</div>")
      sign_in student

      get lecture_home_path(lecture)

      expect(response.body)
        .not_to include('data-testid="lecture-home-fallback-card"')
    end

    it "is hidden for staff, who get the empty-state instead" do
      sign_in editor

      get lecture_home_path(lecture)

      expect(response.body)
        .not_to include('data-testid="lecture-home-fallback-card"')
      expect(response.body)
        .to include('data-testid="lecture-home-intro-empty"')
    end
  end

  describe "the staff note about the student registration view" do
    let!(:campaign) do
      create(:registration_campaign, :open, :with_items,
             campaignable: lecture, items_count: 2,
             description: "Seminarvergabe")
    end

    it "shows staff a note about the student registration view" do
      sign_in editor

      get lecture_home_path(lecture)

      expect(response.body)
        .to include('data-testid="lecture-home-staff-registration-note"')
      expect(response.body).to include("Seminarvergabe")
      expect(response.body).to include(edit_lecture_path(lecture, tab: "groups"))
    end

    it "is not shown to students, who get the real registration block" do
      sign_in student

      get lecture_home_path(lecture)

      expect(response.body)
        .not_to include('data-testid="lecture-home-staff-registration-note"')
    end

    it "stays once a group takes self-registration" do
      create(:tutorial, lecture: lecture, skip_campaigns: true,
                        self_materialization_mode: :add_and_remove)
      sign_in editor

      get lecture_home_path(lecture)

      expect(response.body)
        .to include('data-testid="lecture-home-staff-registration-note"')
      expect(response.body).not_to include('data-testid="self-enrollment"')
    end

    it "counts the people registered in a first come, first served campaign" do
      item = campaign.registration_items.first
      create(:registration_user_registration, :confirmed, registration_campaign: campaign,
                                                          registration_item: item)
      create(:registration_user_registration, :rejected, registration_campaign: campaign,
                                                         registration_item: item)
      sign_in editor

      get lecture_home_path(lecture)

      expect(response.body)
        .to include(I18n.t("lecture_home.teacher.registered", count: 1))
    end

    it "is not shown to staff when the lecture has no campaigns" do
      without_campaign = create(:lecture, :released_for_all, teacher: editor)
      sign_in editor

      get lecture_home_path(without_campaign)

      expect(response.body)
        .not_to include('data-testid="lecture-home-staff-registration-note"')
    end
  end

  describe "the tutor block" do
    it "lists the tutorials the user teaches" do
      tutor = create(:confirmed_user)
      create(:tutorial, lecture: lecture, title: "Thursday Tutorial", tutors: [tutor])
      create(:tutorial, lecture: lecture, title: "Friday Tutorial")
      sign_in tutor

      get lecture_home_path(lecture)

      expect(response.body).to include('data-testid="lecture-home-tutor"')
      expect(response.body).to include("Thursday Tutorial")
      expect(response.body).not_to include("Friday Tutorial")
    end
  end

  describe "the closed campaigns" do
    it "lists a campaign past its deadline for a student who missed it" do
      create(:registration_campaign, :closed, campaignable: lecture,
                                              description: "Late tutorial registration")
      sign_in student

      get lecture_home_path(lecture)

      expect(response.body).to include('data-testid="lecture-home-history"')
      expect(response.body).to include("Late tutorial registration")
      expect(response.body).not_to include('data-testid="lecture-home-registrations"')
    end
  end

  describe "an open campaign on the page" do
    let!(:campaign) do
      create(:registration_campaign, :open, :first_come_first_served,
             campaignable: lecture, description: "Tutorial registration")
    end

    before { lecture.update!(home_intro: "<div>Welcome</div>") }

    it "leads with the campaign the student still has to register in" do
      sign_in student

      get lecture_home_path(lecture)

      focus = Nokogiri::HTML(response.body).at_css('[data-testid="lecture-home-focus"]')
      expect(focus.text).to include("Tutorial registration")
    end

    it "loads the options only when the row is opened" do
      sign_in student

      get lecture_home_path(lecture)
      expect(response.body)
        .not_to include(campaign.registration_items.first.registerable.title)

      get lecture_home_campaign_path(lecture, campaign_id: campaign.id), as: :turbo_stream

      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body)
        .to include(campaign.registration_items.first.registerable.title)
    end

    it "answers not found for a campaign that is closed" do
      campaign.update!(status: :closed)
      sign_in student

      get lecture_home_campaign_path(lecture, campaign_id: campaign.id), as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end

    it "answers not found for the lecture's teacher" do
      sign_in editor

      get lecture_home_campaign_path(lecture, campaign_id: campaign.id), as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "a registration whose requirement fails" do
    it "says so in the campaign row next to the registration" do
      campaign = create(:registration_campaign, :open, :first_come_first_served,
                        :with_finalization_policy, campaignable: lecture,
                                                   description: "Tutorial registration")
      other = create(:confirmed_user, email: "someone@elsewhere.org")
      create(:registration_user_registration, :confirmed,
             registration_campaign: campaign,
             registration_item: campaign.registration_items.first, user: other)
      sign_in other

      get lecture_home_path(lecture)

      row = Nokogiri::HTML(response.body).at_css("summary.registration-fold-summary")
      expect(row.text).to include(I18n.t("registration.user_registration.summary.registered"))
      expect(row.text)
        .to include(I18n.t("registration.user_registration.summary.requirement_missing"))
      expect(row.text).to include("example.com")
    end
  end

  describe "a campaign closed before its deadline" do
    it "says so instead of naming the deadline as its end" do
      create(:registration_campaign, :closed, campaignable: lecture,
                                              registration_deadline: 1.week.from_now,
                                              description: "Early tutorial registration")
      sign_in student

      get lecture_home_path(lecture)

      expect(response.body).to include(
        I18n.t("lecture_home.history.closed_early", deadline: "DEADLINE").split("DEADLINE").first
      )
    end
  end

  describe "GET /lectures/:id/home_attachment" do
    it "streams the pdf to anyone who may see the home page" do
      attach_home_pdf(lecture).save!
      sign_in student

      get lecture_home_attachment_path(lecture)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
    end

    it "redirects when the lecture has no attachment" do
      sign_in editor

      get lecture_home_attachment_path(lecture)

      expect(response).to redirect_to(lecture_home_path(lecture))
      expect(flash[:alert])
        .to eq(I18n.t("registration.lecture.home.attachment_missing"))
      expect(flash[:alert])
        .not_to eq(I18n.t("registration.lecture.not_found"))
    end

    it "denies access for a non-staff user on an unpublished lecture" do
      attach_home_pdf(lecture).update!(released: nil)
      sign_in student

      get lecture_home_attachment_path(lecture)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "the offer on the page and the answer of the endpoint" do
    it "say the same thing for staff and students alike" do
      tutorial = create(:tutorial, lecture: lecture, skip_campaigns: true,
                                   self_materialization_mode: :add_and_remove)
      tutor = create(:confirmed_user)
      tutorial.update!(tutors: [tutor])

      { "teacher" => editor, "tutor" => tutor, "student" => student }.each do |role, user|
        sign_in user
        get lecture_home_path(lecture)
        offered = response.body.include?('data-testid="self-enrollment"')
        accepted = LectureAbility.new(user).can?(:self_materialize, lecture)
        sign_out user

        expect(offered).to eq(accepted),
                           "the page #{offered ? "offers" : "hides"} the tiles for the " \
                           "#{role}, the endpoint #{accepted ? "accepts" : "refuses"} them"
      end
    end
  end
end
