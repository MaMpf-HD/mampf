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
  end
end
