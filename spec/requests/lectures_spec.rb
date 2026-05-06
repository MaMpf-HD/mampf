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

  describe "PATCH /lectures/:id" do
    let(:teacher) { create(:confirmed_user) }
    let(:lecture) { create(:lecture, teacher: teacher) }

    before do
      sign_in teacher
    end

    context "with turbo_stream request and assessments subpage" do
      before do
        Flipper.enable(:assessment_grading)
      end

      after do
        Flipper.disable(:assessment_grading)
      end

      it "updates lecture submission settings" do
        patch lecture_path(lecture),
              params: {
                lecture: {
                  submission_max_team_size: 5,
                  submission_grace_period: 30
                },
                subpage: "assessments"
              },
              headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        lecture.reload
        expect(lecture.submission_max_team_size).to eq(5)
        expect(lecture.submission_grace_period).to eq(30)
      end

      it "renders turbo_stream replacing submission settings" do
        patch lecture_path(lecture),
              params: {
                lecture: { submission_max_team_size: 3 },
                subpage: "assessments"
              },
              headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include("turbo-stream")
        expect(response.body).to include("lecture-submission-settings")
        expect(response.body).to include("submission_settings")
      end

      it "includes flash notice in turbo_stream" do
        patch lecture_path(lecture),
              params: {
                lecture: { submission_max_team_size: 2 },
                subpage: "assessments"
              },
              headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include(I18n.t("admin.lecture.updated"))
      end

      it "sets view locale from lecture" do
        lecture.update(locale: "en")

        patch lecture_path(lecture),
              params: {
                lecture: { submission_max_team_size: 4 },
                subpage: "assessments"
              },
              headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

        expect(I18n.locale).to eq(:en)
      end
    end

    context "with html request" do
      it "redirects to edit page" do
        patch lecture_path(lecture),
              params: { lecture: { submission_max_team_size: 5 } }

        expect(response).to redirect_to(edit_lecture_path(lecture))
      end

      it "redirects to edit page with tab param when subpage present" do
        patch lecture_path(lecture),
              params: {
                lecture: { submission_max_team_size: 5 },
                subpage: "assessments"
              }

        expect(response).to redirect_to(edit_lecture_path(lecture, tab: "assessments"))
      end
    end
  end
end
