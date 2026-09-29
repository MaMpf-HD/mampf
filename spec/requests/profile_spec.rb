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

    def save_teacher_profile(**fields)
      post("/profile/update",
           params: { user: { name: user.name, subscription_type: 1, locale: "en",
                             email_for_news: "0", **fields } },
           xhr: true)
    end

    describe "the teacher's homepage and picture" do
      it "are saved for a teacher" do
        create(:lecture, teacher: user)

        save_teacher_profile(homepage: "https://example.org/~ada")

        expect(user.reload.homepage).to eq("https://example.org/~ada")
      end

      it "are left alone for someone who teaches nothing" do
        save_teacher_profile(homepage: "https://example.org/~ada")

        expect(user.reload.homepage).to be_blank
      end

      it "report an address that is no web address" do
        create(:lecture, teacher: user)

        save_teacher_profile(homepage: "not an address")

        message = build(:user, homepage: "not an address").tap(&:valid?).errors[:homepage]
        expect(user.reload.homepage).to be_blank
        expect(response.body).to include("$('#homepage-error').append('#{message.join(" ")}')")
      end

      it "drop the picture when asked to" do
        create(:lecture, teacher: user)
        user.update!(image: Rails.public_path.join("unknown-person.gif").open)

        save_teacher_profile(remove_image: "1")

        expect(user.reload.image).to be_nil
      end

      describe "a new picture" do
        let(:refused) do
          image = Rails.root.join(SPEC_FILES, "image.png").open("rb")
          cached = ProfileimageUploader.upload(image, :cache)
          data = cached.data.deep_dup
          data["metadata"]["malware_scan"] = { "status" => "clean" }
          data.to_json
        end

        before do
          create(:lecture, teacher: user)
          user.update!(image: Rails.public_path.join("unknown-person.gif").open)
        end

        def upload_picture
          scanner = instance_double(ClamavScanner, scan: UploadScanResult.clean)
          allow(MalwareScanGate).to receive(:scanner).and_return(scanner)
          post("/profile_image/upload",
               params: { file: Rack::Test::UploadedFile.new(File.join(SPEC_FILES, "image.png"),
                                                            "image/png") },
               headers: upload_intent_headers(ProfileimageUploader, user: user, target: user))
          response.body
        end

        it "that is refused is named, and the old one stays" do
          old_image = user.image.id

          save_teacher_profile(image: refused)

          expect(response.body).to include(
            I18n.t("submission.upload_failure_scan_required", locale: :en).strip
          )
          expect(response.body).to include("$('#image-error').append(")
          expect(user.reload.image.id).to eq(old_image)
        end

        it "wins over a ticked remove" do
          save_teacher_profile(image: upload_picture, remove_image: "1")

          expect(user.reload.image.original_filename).to eq("image.png")
        end
      end
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
