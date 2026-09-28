require "rails_helper"

RSpec.describe("Profile", type: :request) do
  let(:user) { create(:confirmed_user) }

  before do
    sign_in user
  end

  describe "POST /profile/update" do
    def save_profile(**fields)
      post("/profile/update",
           params: { user: { name: user.name, subscription_type: 1, locale: "en",
                             email_for_news: "0", **fields } },
           xhr: true)
    end

    it "keeps the bookmarks, which the dashboard's search looks after" do
      lecture = create(:lecture, :released_for_all)
      create(:lecture_bookmark, user: user, lecture: lecture)

      save_profile

      expect(response).to have_http_status(:ok)
      expect(user.reload.lectures).to contain_exactly(lecture)
    end

    it "bookmarks nothing sent along with the form" do
      lecture = create(:lecture, :released_for_all)

      save_profile(lecture: { lecture.id.to_s => { subscribed: "1" } })

      expect(user.reload.lectures).to be_empty
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
