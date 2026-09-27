require "rails_helper"

RSpec.describe("Profile", type: :request) do
  let(:user) { create(:confirmed_user) }

  before do
    sign_in user
  end

  describe "POST /profile/update" do
    def save_profile(lectures = {})
      post("/profile/update",
           params: { user: { name: user.name, subscription_type: 1, locale: "en",
                             email_for_news: "0",
                             lecture: lectures.transform_keys(&:to_s) } },
           xhr: true)
    end

    def choosing(lecture, passphrase: nil)
      { lecture.id => { subscribed: "1", passphrase: passphrase } }
    end

    it "does not bookmark an unpublished lecture sent along with the form" do
      draft = create(:lecture, passphrase: "secret")

      save_profile(choosing(draft))

      expect(user.reload.lectures).not_to include(draft)
    end

    it "bookmarks a pass-phrase lecture with its pass phrase only" do
      lecture = create(:lecture, :released_for_all, passphrase: "secret")

      save_profile(choosing(lecture, passphrase: "wrong"))
      expect(user.reload.lectures).not_to include(lecture)

      save_profile(choosing(lecture, passphrase: "secret"))
      expect(response).to have_http_status(:ok)
      expect(user.reload.lectures).to include(lecture)
    end

    it "saves nothing when one of the chosen lectures is refused" do
      open_lecture = create(:lecture, :released_for_all)
      locked = create(:lecture, :released_for_all, passphrase: "secret")

      save_profile(choosing(open_lecture).merge(choosing(locked, passphrase: "wrong")))

      expect(user.reload.lectures).to be_empty
    end

    it "stops guessing pass phrases after ten saves a minute" do
      lecture = create(:lecture, :released_for_all, passphrase: "secret")
      10.times { save_profile(choosing(lecture, passphrase: "wrong")) }

      save_profile(choosing(lecture, passphrase: "secret"))

      expect(user.reload.lectures).not_to include(lecture)
    end

    it "is not throttled by pass-phrase attempts on the lecture icons" do
      lecture = create(:lecture, :released_for_all, passphrase: "secret")
      10.times do
        patch(subscribe_lecture_path,
              params: { lecture: { id: lecture.id, passphrase: "wrong" } }, xhr: true)
      end

      save_profile

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /profile/request_data" do
    it "mails the user their data and nobody else" do
      expect { get(request_data_path, xhr: true) }
        .to have_enqueued_mail(MathiMailer, :data_provide_email).with(user)
        .and(have_enqueued_mail.exactly(:once))
    end
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

      it "bookmarks the lecture with the correct passphrase" do
        subscribe(lecture, passphrase: "secret")

        expect(response).to have_http_status(:ok)
        expect(user.reload.lectures).to include(lecture)
      end

      it "stops guessing the passphrase after ten attempts a minute" do
        10.times { subscribe(lecture, passphrase: "wrong") }

        subscribe(lecture, passphrase: "secret")

        expect(response).to have_http_status(:too_many_requests)
        expect(user.reload.lectures).not_to include(lecture)
      end

      it "does not bookmark the lecture without the passphrase" do
        subscribe(lecture)

        expect(user.reload.lectures).not_to include(lecture)
      end

      it "bookmarks the lecture for roster members without the passphrase" do
        create(:lecture_membership, user: user, lecture: lecture)

        subscribe(lecture)

        expect(response).to have_http_status(:ok)
        expect(user.reload.lectures).to include(lecture)
      end
    end

    context "with a card from the fold of the coming term" do
      let(:next_term) { create(:term, :winter, year: 2025) }
      let(:lecture) { create(:lecture, :released_for_all, term: next_term) }

      before { create(:term, :summer, :active, year: 2025) }

      it "keeps the term on the card it renders back" do
        patch(subscribe_lecture_path,
              params: { lecture: { id: lecture.id,
                                   parent: "next_term_registered" } },
              xhr: true)

        expect(response.body).to include(next_term.to_label_short)
      end
    end
  end
end
