require "rails_helper"

RSpec.describe("StudentMessages", type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:tutor) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:tutorial) { create(:tutorial, :with_tutor_by_id, lecture: lecture, tutor_id: tutor.id) }
  let(:other_tutorial) { create(:tutorial, lecture: lecture) }
  let(:member) { create(:confirmed_user) }
  let(:outsider) { create(:confirmed_user) }
  let(:campaign) do
    create(:registration_campaign, :open, :first_come_first_served, campaignable: lecture)
  end
  let!(:registration) do
    create(:registration_user_registration, :confirmed,
           registration_campaign: campaign, user: create(:confirmed_user))
  end

  before do
    create(:lecture_membership, lecture: lecture, user: member)
    create(:tutorial_membership, tutorial: tutorial, user: member)
    create(:lecture_membership, lecture: lecture, user: outsider)
    create(:tutorial_membership, tutorial: other_tutorial, user: outsider)
  end

  describe "POST /lectures/:lecture_id/student_messages" do
    def send_message(fields = {}, audiences: ["lecture:all"], return_to: nil)
      post(lecture_student_messages_path(lecture),
           params: { return_to: return_to,
                     student_message: { subject: "First session",
                                        body: "We start on Monday.",
                                        audiences: audiences }.merge(fields) }.compact)
    end

    context "as the teacher" do
      before { sign_in teacher }

      it "creates the message for everybody and enqueues the delivery" do
        expect do
          send_message
        end.to change(StudentMessage, :count).by(1)
           .and(have_enqueued_mail(StudentMessageMailer, :student_message_email))

        expect(response).to redirect_to(edit_lecture_path(lecture, tab: "communication"))
        message = StudentMessage.last
        expect(message.sender).to eq(teacher)
        expect(message).to be_staff
        expect(message.recipient_emails).to contain_exactly(registration.user.email,
                                                            member.email, outsider.email)
        expect(message.audience_labels).to eq([I18n.t("student_message.audiences.everyone")])
      end

      # The groups picked are what the mail reaches, once each; the empty
      # value the "groups picked" radio sends is nothing.
      it "reaches the union of the groups picked" do
        send_message(audiences: ["", "tutorial:#{tutorial.id}", "tutorial:#{other_tutorial.id}"])

        message = StudentMessage.last
        expect(message.recipient_emails).to contain_exactly(member.email, outsider.email)
        expect(message.audience_labels).to eq([tutorial.title, other_tutorial.title])
      end

      it "refuses a group that is not the lecture's, and sends nothing" do
        foreign = create(:tutorial, lecture: create(:lecture))

        expect do
          send_message(audiences: ["tutorial:#{tutorial.id}", "tutorial:#{foreign.id}"])
        end.not_to change(StudentMessage, :count)

        expect(flash[:alert]).to eq(I18n.t("student_message.no_audience"))
      end

      it "refuses to send to nobody" do
        expect do
          send_message(audiences: [])
        end.not_to change(StudentMessage, :count)

        expect(flash[:alert]).to eq(I18n.t("student_message.no_audience"))
      end

      it "goes back where the form was" do
        send_message(return_to: "/lectures/#{lecture.id}/tutorials?tutorial=#{tutorial.id}")

        expect(response).to redirect_to("/lectures/#{lecture.id}/tutorials?tutorial=#{tutorial.id}")
      end

      # A bad way back must not fail the request once the message is on its
      # way; it is not followed.
      it "lands on the communication tab for anything but a path of this app" do
        ["javascript:alert(1)", "https://evil.example/x", "//evil.example",
         "/\\evil.example", "http://[", "x" * 10_000, "/\t//evil.example", "/bad path",
         "/bad%zz", "/#{"x" * 3000}"].each do |bad|
          send_message(return_to: bad)

          expect(response).to redirect_to(edit_lecture_path(lecture, tab: "communication"))
        end
      end

      it "stores a pdf attachment, scanned" do
        file = Rack::Test::UploadedFile.new(
          StringIO.new("%PDF-1.4 demo"), "application/pdf",
          original_filename: "program.pdf"
        )

        send_message({ attachment: file })

        attachment = StudentMessage.last.attachment
        expect(attachment.metadata["filename"]).to eq("program.pdf")
        expect(attachment.metadata.dig(MalwareScanGate::METADATA_KEY, "status"))
          .to eq(MalwareScanGate::CLEAN_STATUS)
      end

      # It goes out to every address picked, under MaMpf's name.
      it "sends nothing with an infected attachment" do
        scanner = instance_double(ClamavScanner)
        allow(MalwareScanGate).to receive(:scanner).and_return(scanner)
        allow(MalwareScanMetrics).to receive(:record_scan)
        allow(scanner).to receive(:scan).and_return(UploadScanResult.infected("Eicar-Signature"))
        file = Rack::Test::UploadedFile.new(StringIO.new("%PDF-1.4 demo"), "application/pdf",
                                            original_filename: "program.pdf")

        expect do
          send_message({ attachment: file })
        end.not_to change(StudentMessage, :count)

        expect(flash[:alert]).to eq(I18n.t("submission.upload_failure_malware"))
      end

      it "rejects non-pdf attachments (content-sniffed, not by extension)" do
        file = Rack::Test::UploadedFile.new(
          StringIO.new("just some text"), "application/pdf",
          original_filename: "program.pdf"
        )

        expect do
          send_message({ attachment: file })
        end.not_to change(StudentMessage, :count)

        expect(flash[:alert]).to include(I18n.t("student_message.attachment_must_be_pdf"))
      end

      it "answers a crafted scalar attachment with 400, not a crash" do
        send_message({ attachment: "text" })

        expect(response).to have_http_status(:bad_request)
        expect(StudentMessage.count).to eq(0)
      end

      it "keeps the labels in every language" do
        lecture.update!(locale: "de")
        teacher.update!(locale: "en")
        send_message

        expect(StudentMessage.last.audiences.sole["labels"])
          .to eq("de" => I18n.t("student_message.audiences.everyone", locale: :de),
                 "en" => I18n.t("student_message.audiences.everyone", locale: :en))
      end

      it "rejects a message without a body" do
        expect do
          send_message({ body: "" })
        end.not_to change(StudentMessage, :count)

        expect(flash[:alert]).to be_present
      end

      it "forces the sender to the current user, ignoring a spoofed sender_id" do
        send_message({ sender_id: create(:confirmed_user).id })

        expect(StudentMessage.last.sender).to eq(teacher)
      end

      it "ignores recipient_emails supplied in params (snapshots the audience server-side)" do
        send_message({ recipient_emails: ["attacker@evil.test"] },
                     audiences: ["tutorial:#{tutorial.id}"])

        expect(StudentMessage.last.recipient_emails).to eq([member.email])
      end
    end

    # A tutor writes to their own group, as themselves, and to nobody else.
    context "as a tutor" do
      before { sign_in tutor }

      it "sends to their own group as a tutor" do
        expect do
          send_message(audiences: ["tutorial:#{tutorial.id}"])
        end.to change(StudentMessage, :count).by(1)

        message = StudentMessage.last
        expect(message).to be_tutor
        expect(message.recipient_emails).to eq([member.email])
      end

      it "cannot write to another group or to everybody" do
        expect do
          send_message(audiences: ["tutorial:#{other_tutorial.id}"])
          send_message(audiences: ["lecture:all"])
        end.not_to change(StudentMessage, :count)

        expect(flash[:alert]).to eq(I18n.t("student_message.no_audience"))
      end
    end

    # The edit right is inherited from the course, and staff status with it.
    context "as an editor of the course" do
      it "sends as staff, and sees the picker" do
        course_editor = create(:confirmed_user)
        lecture.course.editors << course_editor
        sign_in course_editor

        get edit_lecture_path(lecture, tab: "communication")
        expect(response.body).to include("audience-everyone")

        send_message(audiences: ["tutorial:#{tutorial.id}"])
        expect(StudentMessage.last).to be_staff
      end
    end

    # Bulk mail per sender is bounded, whatever the account does.
    it "caps what one sender writes in an hour" do
      sign_in teacher
      Rails.cache.clear

      20.times { send_message }
      expect do
        send_message
      end.not_to change(StudentMessage, :count)

      expect(flash[:alert]).to eq(I18n.t("student_message.too_many"))
    end

    # A refused tutor is sent to a page of theirs, not to the lecture editor.
    it "sends a capped tutor back to their own page" do
      sign_in tutor
      Rails.cache.clear

      20.times { send_message(audiences: ["tutorial:#{tutorial.id}"]) }
      send_message(audiences: ["tutorial:#{tutorial.id}"])

      expect(response).to redirect_to(lecture_tutorials_path(lecture))
      expect(flash[:alert]).to eq(I18n.t("student_message.too_many"))
    end

    context "as a student" do
      before { sign_in member }

      it "is not allowed" do
        expect do
          send_message(audiences: ["tutorial:#{tutorial.id}"])
        end.not_to change(StudentMessage, :count)

        expect(response).to redirect_to(root_url)
      end
    end

    it "does not let a teacher send to another lecture (uses the URL lecture)" do
      victim = create(:lecture, :released_for_all, teacher: create(:confirmed_user))
      create(:lecture_membership, lecture: victim, user: create(:confirmed_user))
      sign_in teacher

      expect do
        post(lecture_student_messages_path(victim),
             params: { student_message: { subject: "s", body: "b", audiences: ["lecture:all"] } })
      end.not_to change(StudentMessage, :count)
      expect(response).to redirect_to(root_url)
    end
  end

  # What a sender writes is theirs, not the request log's.
  it "keeps the subject and the body out of the log" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    logged = filter.filter("student_message" => { "subject" => "Room change",
                                                  "body" => "We meet in room 3.",
                                                  "audiences" => ["lecture:all"] })

    expect(logged["student_message"]).to eq("subject" => "[FILTERED]", "body" => "[FILTERED]",
                                            "audiences" => ["lecture:all"])
  end

  describe "GET /lectures/:lecture_id/student_messages/recipients" do
    def ask(audiences)
      get(recipients_lecture_student_messages_path(lecture),
          params: { audiences: audiences }, as: :turbo_stream)
    end

    it "answers the picker with the count and the addresses behind a selection" do
      sign_in teacher
      ask(["tutorial:#{tutorial.id}"])

      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include("target=\"student-message-recipients\"")
      expect(response.body).to include(I18n.t("student_message.send", count: 1))
      expect(response.body).to include(member.email)
      expect(response.body).not_to include(outsider.email)
    end

    it "says nobody for an empty selection" do
      sign_in teacher
      ask([])

      expect(response.body).to include(I18n.t("student_message.nobody_picked"))
      expect(response.body).not_to include("copy-student-emails")
    end

    it "refuses a tutor asking about another group" do
      sign_in tutor
      ask(["tutorial:#{other_tutorial.id}"])

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "the pages" do
    it "shows the staff the picker with every group and their sent messages" do
      sign_in teacher
      StudentMessage.create!(lecture: lecture, sender: teacher, sender_role: :staff,
                             subject: "Old one", body: "b", audiences: [{ key: "lecture:all",
                                                                          label: "Everyone" }],
                             recipient_emails: ["x@example.com"], recipients_count: 1)
      StudentMessage.create!(lecture: lecture, sender: tutor, sender_role: :tutor,
                             subject: "Tutor's own", body: "b",
                             audiences: [{ key: "tutorial:#{tutorial.id}", label: "T" }],
                             recipient_emails: ["y@example.com"], recipients_count: 1)

      get edit_lecture_path(lecture, tab: "communication")

      expect(response.body).to include("student-mail-card")
      expect(response.body).to include("audience-everyone")
      expect(response.body).to include("audience-tutorial-#{tutorial.id}")
      expect(response.body).to include("audience-campaign-#{campaign.id}-all")
      expect(response.body).to include("Old one")
      expect(response.body).not_to include("Tutor&#39;s own")
    end

    it "gives the tutor a mail button for their group on their page" do
      sign_in tutor
      create(:assignment, lecture: lecture)

      get lecture_tutorials_path(lecture, tutorial: tutorial.id)

      expect(response.body).to include(I18n.t("student_message.tutorial.button"))
      expect(response.body).to include("value=\"tutorial:#{tutorial.id}\"")
    end

    # A first word to the group comes before the first sheet.
    it "gives the tutor the mail button before the lecture has a sheet" do
      sign_in tutor

      get lecture_tutorials_path(lecture, tutorial: tutorial.id)

      expect(response.body).to include(I18n.t("assignment.nothing_yet_in_lecture").strip)
      expect(response.body).to include(I18n.t("student_message.tutorial.button"))
    end
  end
end
