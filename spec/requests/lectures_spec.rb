require "rails_helper"

RSpec.describe("Lectures", type: :request) do
  # Use an admin to bypass visibility filters for simplicity
  let(:user) { create(:confirmed_user, admin: true) }

  # Create 13 calculus courses to test pagination with custom per_page value
  let!(:calculus_courses) do
    (1..13).map { |i| create(:course, title: "Advanced Calculus #{i}") }
  end
  let!(:calculus_lectures) do
    calculus_courses.map { |course| create(:lecture, course: course) }
  end
  let!(:course_algebra) { create(:course, title: "Linear Algebra") }
  let!(:lecture_algebra) { create(:lecture, course: course_algebra) }

  let(:per_page_value) { 10 }

  before do
    sign_in user

    # Stub the ControllerSearcher to use our custom `default_per_page` value
    allow(Search::Searchers::ControllerSearcher).to receive(:search)
      .and_wrap_original do |original_method, **args|
        modified_options = args[:options].merge(default_per_page: per_page_value)
        original_method.call(**args, options: modified_options)
      end
  end

  describe "GET /lectures/search" do
    context "with a JS/XHR request" do
      it "returns a successful response" do
        get search_lectures_path, params: { search: { fulltext: "Calculus" } }, xhr: true
        expect(response).to have_http_status(:ok)
      end

      it "returns the correct lectures in the response body" do
        get search_lectures_path, params: { search: { fulltext: "Calculus" } }, xhr: true
        expect(response.body).to include(calculus_courses.first.title)
        expect(response.body).not_to include(lecture_algebra.course.title)
      end

      it "filters lectures to the current term" do
        current_term = create(:term, :summer, :active, year: 2025)
        next_term = create(:term, :winter, year: 2025)
        current_course = create(:course, title: "Topology Current")
        next_course = create(:course, title: "Topology Next")
        create(:lecture, course: current_course, term: current_term)
        create(:lecture, course: next_course, term: next_term)
        term_independent_course = create(:course, :term_independent,
                                         title: "Topology Independent")
        create(:lecture, :term_independent, course: term_independent_course)

        get search_lectures_path,
            params: { search: { fulltext: "Topology", term_scope: "current" } },
            xhr: true

        expect(response.body).to include(current_course.title)
        expect(response.body).to include(term_independent_course.title)
        expect(response.body).not_to include(next_course.title)
      end

      it "filters lectures to the next term" do
        current_term = create(:term, :summer, :active, year: 2025)
        next_term = create(:term, :winter, year: 2025)
        current_course = create(:course, title: "Analysis Current")
        next_course = create(:course, title: "Analysis Next")
        create(:lecture, course: current_course, term: current_term)
        create(:lecture, course: next_course, term: next_term)
        term_independent_course = create(:course, :term_independent,
                                         title: "Analysis Independent")
        create(:lecture, :term_independent, course: term_independent_course)

        get search_lectures_path,
            params: { search: { fulltext: "Analysis", term_scope: "next" } },
            xhr: true

        expect(response.body).to include(next_course.title)
        expect(response.body).to include(term_independent_course.title)
        expect(response.body).not_to include(current_course.title)
      end
    end

    context "with registration campaigns" do
      # We deliberately use lecture_algebra (a unique title, single search
      # hit) here: the calculus lectures have random terms, so which of them
      # end up on the first results page is not deterministic.
      def search_algebra
        get(search_lectures_path,
            params: { search: { fulltext: "Algebra" }, infinite_scroll: true },
            as: :turbo_stream)
      end

      context "when the feature flag is enabled" do
        before do
          Flipper.enable(:registration_campaigns)
        end

        after do
          Flipper.disable(:registration_campaigns)
        end

        it "shows a badge for lectures with an open registration campaign" do
          create(:registration_campaign, :open, :first_come_first_served,
                 campaignable: lecture_algebra)

          search_algebra

          expect(response.body).to include("lecture-search-registration-badge")
        end

        it "does not show a badge for draft campaigns" do
          create(:registration_campaign, :first_come_first_served,
                 campaignable: lecture_algebra)

          search_algebra

          expect(response.body)
            .not_to include("lecture-search-registration-badge")
        end

        it "shows a registered badge instead when the user has registered" do
          campaign = create(:registration_campaign, :open,
                            :first_come_first_served,
                            campaignable: lecture_algebra)
          create(:registration_user_registration,
                 registration_campaign: campaign, user: user)

          search_algebra

          expect(response.body).to include("lecture-search-registered-badge")
          expect(response.body)
            .not_to include("lecture-search-registration-badge")
        end

        it "still shows the open badge when the registration was rejected" do
          campaign = create(:registration_campaign, :open,
                            :first_come_first_served,
                            campaignable: lecture_algebra)
          create(:registration_user_registration, :rejected,
                 registration_campaign: campaign, user: user)

          search_algebra

          expect(response.body).to include("lecture-search-registration-badge")
          expect(response.body)
            .not_to include("lecture-search-registered-badge")
        end
      end

      it "does not show a badge when the feature flag is disabled" do
        create(:registration_campaign, :open, :first_come_first_served,
               campaignable: lecture_algebra)

        search_algebra

        expect(response.body)
          .not_to include("lecture-search-registration-badge")
      end
    end

    context "with self-enrollment groups" do
      def search_algebra
        get(search_lectures_path,
            params: { search: { fulltext: "Algebra" }, infinite_scroll: true },
            as: :turbo_stream)
      end

      before { Flipper.enable(:roster_maintenance) }

      after { Flipper.disable(:roster_maintenance) }

      it "shows the open badge for a lecture with a self-enrollment group" do
        create(:tutorial, lecture: lecture_algebra,
                          self_materialization_mode: :add_only)

        search_algebra

        expect(response.body).to include("lecture-search-registration-badge")
      end

      it "shows the registered badge when the user is already in a group" do
        tutorial = create(:tutorial, lecture: lecture_algebra,
                                     self_materialization_mode: :add_only)
        create(:tutorial_membership, tutorial: tutorial, user: user)

        search_algebra

        expect(response.body).to include("lecture-search-registered-badge")
        expect(response.body)
          .not_to include("lecture-search-registration-badge")
      end

      it "shows no badge for groups with self-enrollment disabled" do
        create(:tutorial, lecture: lecture_algebra,
                          self_materialization_mode: :disabled)

        search_algebra

        expect(response.body)
          .not_to include("lecture-search-registration-badge")
        expect(response.body)
          .not_to include("lecture-search-registered-badge")
      end
    end

    context "with subscribed lectures" do
      def search_algebra
        get(search_lectures_path,
            params: { search: { fulltext: "Algebra" }, infinite_scroll: true },
            as: :turbo_stream)
      end

      it "shows a subscribed indicator on the card" do
        create(:lecture_user_join, user: user, lecture: lecture_algebra)

        search_algebra

        expect(response.body).to include("lecture-search-subscribed-indicator")
      end

      it "does not show a subscribed indicator otherwise" do
        search_algebra

        expect(response.body)
          .not_to include("lecture-search-subscribed-indicator")
      end
    end

    context "with an HTML request" do
      it "redirects to the root path" do
        get search_lectures_path, params: { search: { fulltext: "Calculus" } }
        expect(response).to redirect_to(:root)
      end

      it "sets a flash alert" do
        get search_lectures_path, params: { search: { fulltext: "Calculus" } }
        expect(flash[:alert]).to eq(I18n.t("controllers.search_only_js"))
      end
    end

    context "with a Turbo Stream request" do
      def turbo_stream_search(page: nil)
        params = { search: { fulltext: "Calculus" }, infinite_scroll: true }
        params[:page] = page if page
        get(search_lectures_path, params: params,
                                  headers: { "ACCEPT" => "text/vnd.turbo-stream.html" })
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "renders the initial list replacement" do
        turbo_stream_search

        expect(response.body).to include("lecture-search-results-wrapper")
        expect(response.body).to include(calculus_courses.first.title)
        expect(response.body).not_to include(lecture_algebra.course.title)
        expect(response.body).not_to include(calculus_courses[10].title)
      end

      it "appends results on subsequent pages" do
        turbo_stream_search(page: 2)

        expect(response.body).to include("turbo-stream action=\"append\"")
        expect(response.body).to include("lecture-search-results")
        expect(response.body).to include(calculus_courses[10].title)
        # regex necessary here since "11" includes "1", which is in the first page
        expect(response.body).not_to match(/\b#{Regexp.escape(calculus_courses.first.title)}\b/)
        expect(response.body).not_to include(lecture_algebra.course.title)
      end
    end
  end

  describe "GET /lectures/:id/script" do
    let(:user) { create(:confirmed_user_en) }
    let(:lecture) { create(:lecture, :released_for_all, locale: "en") }

    before do
      Flipper.enable(:registration_campaigns)
      create(:lecture_user_join, user: user, lecture: lecture)
      create(:lecture_medium,
             teachable: lecture,
             sort: "Script",
             released: "all",
             released_at: Time.zone.now,
             description: "Lecture script")
    end

    it "renders the lecture home sidebar entry" do
      get lecture_script_path(lecture)

      expect(response).to have_http_status(:ok)
      home_label = I18n.with_locale(:en) do
        I18n.t("basics.home")
      end

      expect(response.body).to include(home_label)
      expect(response.body).to include(lecture_home_path(lecture))
    end

    it "renders a Home marker when there are lecture updates" do
      announcement = create(:announcement,
                            lecture: lecture,
                            announcer: lecture.teacher)
      create(:notification, recipient: user, notifiable: announcement)

      get lecture_script_path(lecture)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("sidebar-item__badge")
      expect(response.body).to include(
        I18n.t("registration.lecture.home.news_indicator")
      )
    end
  end

  describe "GET /lectures/:id as staff" do
    let(:lecture) { create(:lecture, :released_for_all, teacher: user) }

    before do
      create(:lecture_user_join, user: user, lecture: lecture)
    end

    it "renders an edit affordance on the content page" do
      get lecture_path(lecture)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(edit_lecture_path(lecture))
      expect(response.body).to include(I18n.t("buttons.edit"))
    end
  end

  describe "lecture routes" do
    let(:lecture) { create(:lecture) }

    it "uses the canonical lecture member path for content" do
      expect(lecture_path(lecture)).to eq("/lectures/#{lecture.id}")
    end
  end

  describe "GET /lectures/:id as a non-subscriber" do
    let(:user) { create(:confirmed_user) }
    let(:lecture) { create(:lecture, :released_for_all) }

    it "redirects to the lecture's home page" do
      get lecture_path(lecture)

      expect(response).to redirect_to(lecture_home_path(lecture))
    end

    it "does not redirect staff (they bypass the subscription gate)" do
      teacher_lecture = create(:lecture, :released_for_all, teacher: user)

      get lecture_path(teacher_lecture)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "XSS protections" do
    let(:xss_payload) { "<div id='test-xss-xyz123'><script>alert('lecture-xss')</script></div>" }
    let!(:xss_course) { create(:course, title: "XSS Course") }
    let!(:xss_lecture) do
      create(:lecture, course: xss_course, teacher: user, organizational: true,
                       organizational_concept: xss_payload)
    end
    let!(:xss_chapter) { create(:chapter, lecture: xss_lecture, details: xss_payload) }
    let!(:xss_section) { create(:section, chapter: xss_chapter, details: xss_payload) }

    before do
      create(:lecture_user_join, user: user, lecture: xss_lecture)
    end

    it "escapes or strips script tags from lecture organizational concept, chapters, and sections in edit view" do # rubocop:disable Layout/LineLength
      get edit_lecture_path(xss_lecture)
      expect(response).to be_successful
      expect(response.body).not_to include("<script>alert('lecture-xss')</script>")
    end

    it "escapes or strips script tags in show view" do
      get lecture_path(xss_lecture)
      expect(response).to be_successful
      expect(response.body).not_to include("<script>alert('lecture-xss')</script>")
    end
  end
end
