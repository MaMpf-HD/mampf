require "rails_helper"

RSpec.describe("Registration::StudentMessages", type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:campaign) do
    create(:registration_campaign, :open, :first_come_first_served,
           campaignable: lecture)
  end
  let!(:registration) do
    create(:registration_user_registration, :confirmed,
           registration_campaign: campaign, user: create(:confirmed_user))
  end

  before do
    Flipper.enable(:registration_campaigns)
  end

  after do
    Flipper.disable(:registration_campaigns)
  end

  describe "POST /lectures/:lecture_id/student_messages" do
    def send_message(params = {})
      post(lecture_student_messages_path(lecture),
           params: { registration_student_message: {
             subject: "First session",
             body: "We start on Monday."
           }.merge(params) })
    end

    context "as the teacher" do
      before do
        sign_in teacher
      end

      it "creates the message and enqueues the delivery" do
        expect do
          send_message
        end.to change(Registration::StudentMessage, :count).by(1)
           .and(have_enqueued_mail(StudentMessageMailer, :student_message_email))

        expect(response).to redirect_to(edit_lecture_path(lecture,
                                                          tab: "communication"))
        message = Registration::StudentMessage.last
        expect(message.sender).to eq(teacher)
        expect(message.recipients_count).to eq(1)
      end

      it "stores an attachment" do
        file = Rack::Test::UploadedFile.new(
          StringIO.new("program"), "application/pdf",
          original_filename: "program.pdf"
        )

        send_message(attachment: file)

        expect(Registration::StudentMessage.last.attachment_filename)
          .to eq("program.pdf")
      end

      it "rejects a message without a body" do
        expect do
          send_message(body: "")
        end.not_to change(Registration::StudentMessage, :count)

        expect(flash[:alert]).to be_present
      end

      it "refuses to send when there are no recipients" do
        registration.update!(status: :rejected)

        expect do
          send_message
        end.not_to change(Registration::StudentMessage, :count)

        expect(flash[:alert])
          .to eq(I18n.t("registration.student_message.no_recipients"))
      end
    end

    context "as a student" do
      before do
        sign_in create(:confirmed_user)
      end

      it "is not allowed" do
        expect do
          send_message
        end.not_to change(Registration::StudentMessage, :count)

        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe "GET /lectures/:id/edit (communication tab)" do
    before do
      sign_in teacher
    end

    it "shows the student mail card with recipient count and copy button" do
      get edit_lecture_path(lecture, tab: "communication")

      expect(response.body).to include("student-mail-card")
      expect(response.body).to include("copy-student-emails")
      expect(response.body)
        .to include(registration.user.email) # inside data-clipboard-text
    end
  end
end
