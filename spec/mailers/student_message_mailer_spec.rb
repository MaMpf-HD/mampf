require "rails_helper"

RSpec.describe(StudentMessageMailer) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:campaign) do
    create(:registration_campaign, :open, :first_come_first_served,
           campaignable: lecture)
  end
  let(:student) { create(:confirmed_user) }
  let!(:registration) do
    create(:registration_user_registration, :confirmed,
           registration_campaign: campaign, user: student)
  end
  let(:message) do
    Registration::StudentMessage.create!(lecture: lecture, sender: teacher,
                                         subject: "First session",
                                         body: "We start on Monday.")
  end

  describe "#student_message_email" do
    subject(:mail) do
      described_class.with(message: message).student_message_email
    end

    it "sends to the registered students via bcc" do
      expect(mail.bcc).to include(student.email)
    end

    it "sets the sender as reply-to" do
      expect(mail.reply_to).to eq([teacher.email])
    end

    it "sends the sender a copy" do
      expect(mail.to).to eq([teacher.email])
    end

    it "puts the lecture editors in cc (the sender is not cc'd twice)" do
      editors = create_list(:confirmed_user, 2)
      lecture.update!(editors: editors)

      expect(mail.cc).to match_array(editors.map(&:email))
    end

    it "keeps the teacher in cc when an editor sends" do
      editor = create(:confirmed_user)
      lecture.update!(editors: [editor])
      message.update!(sender: editor)

      expect(mail.to).to eq([editor.email])
      expect(mail.cc).to eq([teacher.email])
    end

    it "prefixes the subject with the lecture title" do
      # the mail is rendered in the lecture's locale, so the localized
      # sort prefix of the title must be computed in that locale as well
      expected_title = I18n.with_locale(lecture.locale_with_inheritance) do
        lecture.title_for_viewers
      end

      expect(mail.subject).to eq("[#{expected_title}] First session")
    end

    it "contains the message body" do
      expect(mail.text_part.body.to_s).to include("We start on Monday.")
    end

    it "attaches the uploaded file" do
      message.attachment = StringIO.new("%PDF-1.4 demo")
      message.attachment_attacher.file.metadata["filename"] = "program.pdf"
      message.save!

      expect(mail.attachments.map(&:filename)).to include("program.pdf")
    end

    it "delivers to the audience snapshotted at creation time" do
      message # create (and snapshot) now
      latecomer = create(:confirmed_user)
      create(:registration_user_registration, :confirmed,
             registration_campaign: campaign, user: latecomer)

      expect(mail.bcc).to include(student.email)
      expect(mail.bcc).not_to include(latecomer.email)
    end

    it "sends nothing when the recipient snapshot is empty" do
      # cannot happen through the regular flow (the model validates the
      # presence of recipients), so this only guards against anomalous data
      empty_message = Registration::StudentMessage.new(
        lecture: lecture, sender: teacher, subject: "s", body: "b",
        recipient_emails: []
      )

      mail = described_class.with(message: empty_message)
                            .student_message_email

      expect(mail.message).to be_a(ActionMailer::Base::NullMail)
    end
  end
end
