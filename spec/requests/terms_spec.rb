require "rails_helper"

RSpec.describe("Terms", type: :request) do
  let(:admin) { create(:confirmed_user, admin: true) }
  let(:student) { create(:confirmed_user) }

  context "as an admin" do
    before { sign_in admin }

    describe "GET /terms" do
      it "responds with HTML" do
        get terms_path
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/html")
      end
    end

    describe "GET /terms/new" do
      it "responds with turbo frame containing form" do
        get new_term_path, headers: { "turbo-frame" => "term-form" }
        expect(response).to have_http_status(:ok)
        assert_turbo_frame("term-form")
      end
    end

    describe "GET /terms/:id/edit" do
      let(:term) { create(:term) }

      it "responds with turbo frame containing form" do
        get edit_term_path(term), headers: { "turbo-frame" => "term-form" }
        expect(response).to have_http_status(:ok)
        assert_turbo_frame("term-form")
      end

      it "redirects to terms index when term not found" do
        get edit_term_path(id: 99_999)
        expect(response).to redirect_to(terms_path)
        expect(flash[:alert]).to eq(I18n.t("controllers.no_term"))
      end
    end

    describe "POST /terms" do
      let(:valid_params) { { term: { year: 2025, season: "SS" } } }

      it "creates a term and redirects on success" do
        expect do
          post(terms_path, params: valid_params)
        end.to change(Term, :count).by(1)

        expect(response).to redirect_to(terms_path)
      end

      it "creates a term and responds with turbo stream on turbo request" do
        expect do
          post(terms_path, params: valid_params, as: :turbo_stream)
        end.to change(Term, :count).by(1)

        assert_turbo_stream(action: "prepend", target: "terms")
        assert_turbo_stream(action: "update", target: Term.new)
      end

      it "responds with form on validation failure" do
        create(:term, year: 2025, season: "SS")

        expect do
          post(terms_path, params: valid_params)
        end.not_to change(Term, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.media_type).to eq("text/html")
      end
    end

    describe "PATCH /terms/:id" do
      let(:term) { create(:term, year: 2024, season: "WS") }

      it "updates a term and redirects on success" do
        patch term_path(term), params: { term: { year: 2025 } }

        expect(response).to redirect_to(terms_path)
        expect(term.reload.year).to eq(2025)
      end

      it "updates and responds with turbo stream on turbo request" do
        patch term_path(term), params: { term: { year: 2025 } }, as: :turbo_stream

        assert_turbo_stream(action: "replace", target: term)
        expect(term.reload.year).to eq(2025)
      end

      it "responds with form on validation failure" do
        create(:term, year: 2025, season: "WS")

        patch term_path(term), params: { term: { year: 2025 } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.media_type).to eq("text/html")
        expect(term.reload.year).to eq(2024)
      end
    end

    describe "DELETE /terms/:id" do
      it "destroys the term and redirects" do
        term = create(:term)

        expect do
          delete(term_path(term))
        end.to change(Term, :count).by(-1)

        expect(response).to redirect_to(terms_path)
      end

      it "destroys and responds with turbo stream on turbo request" do
        term = create(:term)

        expect do
          delete(term_path(term), as: :turbo_stream)
        end.to change(Term, :count).by(-1)

        assert_turbo_stream(action: "remove", target: term)
      end
    end

    describe "POST /terms/set_active_term" do
      it "switches the active term when a different term is selected" do
        old_active_term = create(:term, :active)
        new_active_term = create(:term, active: false)

        post set_active_term_path, params: { active_term: new_active_term.id }

        expect(response).to redirect_to(terms_path)
        expect(old_active_term.reload.active).to be(false)
        expect(new_active_term.reload.active).to be(true)
      end

      it "activates the selected term when no term is active" do
        inactive_term = create(:term, active: false)

        post set_active_term_path, params: { active_term: inactive_term.id }

        expect(response).to redirect_to(terms_path)
        expect(inactive_term.reload.active).to be(true)
      end

      it "does nothing when same term is selected again" do
        active_term = create(:term, :active)

        post set_active_term_path, params: { active_term: active_term.id }

        expect(response).to redirect_to(terms_path)
        expect(active_term.reload.active).to be(true)
      end

      it "does nothing when invalid term id is provided" do
        active_term = create(:term, :active)

        post set_active_term_path, params: { active_term: 99_999 }

        expect(response).to redirect_to(terms_path)
        expect(active_term.reload.active).to be(true)
      end
    end
  end

  context "as a student" do
    before { sign_in student }

    describe "GET /terms" do
      it "redirects to root" do
        get terms_path

        expect(response).to redirect_to(root_path)
      end
    end

    describe "GET /terms/new" do
      it "redirects to root" do
        get new_term_path

        expect(response).to redirect_to(root_path)
      end
    end

    describe "GET /terms/:id/edit" do
      let(:term) { create(:term) }

      it "redirects to root" do
        get edit_term_path(term)

        expect(response).to redirect_to(root_path)
      end
    end

    describe "POST /terms" do
      let(:valid_params) { { term: { year: 2025, season: "SS" } } }

      it "redirects to root and does not create a term" do
        expect do
          post(terms_path, params: valid_params)
        end.not_to change(Term, :count)

        expect(response).to redirect_to(root_path)
      end

      it "redirects to root on turbo request and does not create a term" do
        expect do
          post(terms_path, params: valid_params, as: :turbo_stream)
        end.not_to change(Term, :count)

        expect(response).to redirect_to(root_path)
      end
    end

    describe "PATCH /terms/:id" do
      let(:term) { create(:term, year: 2024, season: "WS") }

      it "redirects to root and does not update the term" do
        patch term_path(term), params: { term: { year: 2025 } }

        expect(response).to redirect_to(root_path)
        expect(term.reload.year).to eq(2024)
      end

      it "redirects to root on turbo request and does not update the term" do
        patch term_path(term), params: { term: { year: 2025 } }, as: :turbo_stream

        expect(response).to redirect_to(root_path)
        expect(term.reload.year).to eq(2024)
      end
    end

    describe "DELETE /terms/:id" do
      let!(:term) { create(:term) }

      it "redirects to root and does not destroy the term" do
        expect do
          delete(term_path(term))
        end.not_to change(Term, :count)

        expect(response).to redirect_to(root_path)
      end

      it "redirects to root on turbo request and does not destroy the term" do
        expect do
          delete(term_path(term), as: :turbo_stream)
        end.not_to change(Term, :count)

        expect(response).to redirect_to(root_path)
      end
    end

    describe "POST /terms/set_active_term" do
      it "redirects to root and does not change active term" do
        old_active_term = create(:term, :active)
        new_active_term = create(:term, active: false)

        post set_active_term_path, params: { active_term: new_active_term.id }

        expect(response).to redirect_to(root_path)
        expect(old_active_term.reload.active).to be(true)
        expect(new_active_term.reload.active).to be(false)
      end
    end
  end
end
