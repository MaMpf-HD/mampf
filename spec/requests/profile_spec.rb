require "rails_helper"

RSpec.describe("Profile", type: :request) do
  let(:user) { create(:confirmed_user) }

  before do
    sign_in user
  end

  describe "PATCH /profile/subscribe_lecture" do
    def subscribe(lecture, passphrase: nil)
      patch(subscribe_lecture_path,
            params: { lecture: { id: lecture.id, passphrase: passphrase } },
            xhr: true)
    end

    context "with a passphrase-protected lecture" do
      let(:lecture) do
        create(:lecture, :released_for_all, passphrase: "secret")
      end

      it "subscribes the user with the correct passphrase" do
        subscribe(lecture, passphrase: "secret")

        expect(response).to have_http_status(:ok)
        expect(user.reload.lectures).to include(lecture)
      end

      it "does not subscribe the user without the passphrase" do
        subscribe(lecture)

        expect(user.reload.lectures).not_to include(lecture)
      end

      it "subscribes roster members without the passphrase" do
        create(:lecture_membership, user: user, lecture: lecture)

        subscribe(lecture)

        expect(response).to have_http_status(:ok)
        expect(user.reload.lectures).to include(lecture)
      end
    end

    context "with the plain HTML flow of the lecture home page" do
      let(:lecture) do
        create(:lecture, :released_for_all, passphrase: "secret")
      end

      def subscribe_html(lecture, passphrase: nil)
        patch(subscribe_lecture_path,
              params: { lecture: { id: lecture.id,
                                   passphrase: passphrase,
                                   parent: "redirect" } })
      end

      it "redirects to the lecture content after a successful subscription" do
        subscribe_html(lecture, passphrase: "secret")

        expect(response).to redirect_to(lecture_path(lecture))
        expect(user.reload.lectures).to include(lecture)
      end

      it "redirects back to the lecture home page with an alert on a " \
         "wrong passphrase" do
        subscribe_html(lecture, passphrase: "wrong")

        expect(response)
          .to redirect_to(lecture_home_path(lecture))
        expect(flash[:alert]).to eq(I18n.t("errors.profile.passphrase"))
        expect(user.reload.lectures).not_to include(lecture)
      end

      it "redirects with an alert also for Turbo form submissions" do
        # Turbo intercepts even local forms and negotiates the
        # turbo_stream format
        patch(subscribe_lecture_path,
              params: { lecture: { id: lecture.id, passphrase: "wrong",
                                   parent: "redirect" } },
              headers: { "ACCEPT" => "text/vnd.turbo-stream.html, " \
                                     "text/html, application/xhtml+xml" })

        expect(response)
          .to redirect_to(lecture_home_path(lecture))
        expect(flash[:alert]).to eq(I18n.t("errors.profile.passphrase"))
      end

      it "redirects with an alert when the lecture is not published" do
        unpublished = create(:lecture)

        subscribe_html(unpublished)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("admin.lecture.no_rights"))
      end
    end
  end
end
