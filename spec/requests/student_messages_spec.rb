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

      # The groups picked are what the mail reaches, once each.
      it "reaches the union of the groups picked" do
        send_message(audiences: ["tutorial:#{tutorial.id}", "lecture:roster"])

        message = StudentMessage.last
        expect(message.recipient_emails).to contain_exactly(member.email, outsider.email)
        expect(message.audience_labels).to eq([tutorial.title,
                                               I18n.t("student_message.audiences.roster")])
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

      it "stores a pdf attachment" do
        file = Rack::Test::UploadedFile.new(
          StringIO.new("%PDF-1.4 demo"), "application/pdf",
          original_filename: "program.pdf"
        )

        send_message({ attachment: file })

        expect(StudentMessage.last.attachment_filename).to eq("program.pdf")
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
  end
end
