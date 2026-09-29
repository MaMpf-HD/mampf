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

    describe "the teacher's homepage and picture" do
      it "are saved for a teacher" do
        create(:lecture, teacher: user)

        save_profile(homepage: "https://example.org/~ada")

        expect(user.reload.homepage).to eq("https://example.org/~ada")
      end

      it "are left alone for someone who teaches nothing" do
        save_profile(homepage: "https://example.org/~ada")

        expect(user.reload.homepage).to be_blank
      end

      it "report an address that is no web address" do
        create(:lecture, teacher: user)

        save_profile(homepage: "not an address")

        message = build(:user, homepage: "not an address").tap(&:valid?).errors[:homepage]
        expect(user.reload.homepage).to be_blank
        expect(response.body).to include("$('#homepage-error').append('#{message.join(" ")}')")
      end

      it "drop the picture when asked to" do
        create(:lecture, teacher: user)
        user.update!(image: Rails.public_path.join("unknown-person.gif").open)

        save_profile(remove_image: "1")

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

          save_profile(image: refused)

          expect(response.body).to include(
            I18n.t("submission.upload_failure_scan_required", locale: :en).strip
          )
          expect(response.body).to include("$('#image-error').append(")
          expect(user.reload.image.id).to eq(old_image)
        end

        it "wins over a ticked remove" do
          save_profile(image: upload_picture, remove_image: "1")

          expect(user.reload.image.original_filename).to eq("image.png")
        end
      end
    end

    it "leaves the bookmarks untouched" do
      lecture = create(:lecture, :released_for_all)
      create(:lecture_bookmark, user: user, lecture: lecture)

      save_profile

      expect(response).to have_http_status(:ok)
      expect(user.reload.lectures).to contain_exactly(lecture)
    end

    it "bookmarks nothing sent along with the form" do
      lecture = create(:lecture, :released_for_all)

      save_profile(lecture: { lecture.id.to_s => { subscribed: "1" } })

      expect(response).to have_http_status(:ok)
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
