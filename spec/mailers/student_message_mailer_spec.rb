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
  let(:catalog) { StudentMessages::Catalog.new(lecture, teacher) }
  let(:message) do
    message = StudentMessage.new(lecture: lecture, sender: teacher, subject: "First session",
                                 body: "We start on Monday.")
    message.address_to(catalog.pick(["lecture:all"]))
    message.save!
    message
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

    # A tutor's mail to their group is theirs alone.
    it "puts nobody in cc when a tutor sends" do
      lecture.update!(editors: [create(:confirmed_user)])
      message.update!(sender: create(:confirmed_user), sender_role: :tutor)

      expect(mail.cc).to be_empty
    end

    it "names the groups in the footer" do
      expect(mail.text_part.body.to_s)
        .to include(I18n.t("student_message.audiences.everyone"))
    end

    # Two senders with the same display name are told apart by a verified
    # address and a role the server assigns.
    it "names the sender's address and role in the footer" do
      expected_role = I18n.with_locale(lecture.locale_with_inheritance) do
        I18n.t("mailer.student_message_role.staff")
      end

      expect(mail.text_part.body.to_s).to include("(#{teacher.email}, #{expected_role})")
    end

    # From before groups could be picked: no labels on record.
    it "says 'everyone registered at the time' for a message without groups" do
      message.update_columns(audiences: []) # rubocop:disable Rails/SkipsModelValidations
      expected = I18n.with_locale(lecture.locale_with_inheritance) do
        I18n.t("student_message.everyone_registered_then")
      end

      expect(mail.text_part.body.to_s).to include(expected)
    end

    # A job enqueued before the rename carries the old name in its GlobalID.
    it "is found under the old name a queued job may carry" do
      old_gid = "gid://mampf/Registration::StudentMessage/#{message.id}"

      expect(GlobalID::Locator.locate(old_gid)).to eq(message)
    end

    it "prefixes the subject with the lecture title" do
      # the mail is rendered in the lecture's locale, so the localized
      # sort prefix of the title must be computed in that locale as well
      expected_title = I18n.with_locale(lecture.locale_with_inheritance) do
        lecture.title_for_viewers
      end

      expect(mail.subject).to eq("[#{expected_title}] First session")
    end

    it "names the group in the subject when a tutor sends" do
      tutorial = create(:tutorial, lecture: lecture, title: "Mo 10")
      create(:tutorial_membership, tutorial: tutorial, user: student)
      tutor_message = StudentMessage.new(lecture: lecture, sender: create(:confirmed_user),
                                         sender_role: :tutor, subject: "Next week", body: "b")
      tutor_message.address_to(catalog.pick(["tutorial:#{tutorial.id}"]))
      tutor_message.save!
      expected_title = I18n.with_locale(lecture.locale_with_inheritance) do
        lecture.title_for_viewers
      end

      subject = described_class.with(message: tutor_message).student_message_email.subject

      expect(subject).to eq("[#{expected_title}, Mo 10] Next week")
    end

    it "contains the message body" do
      expect(mail.text_part.body.to_s).to include("We start on Monday.")
    end

    # Every uploader asks the gate: cached data that did not come through
    # the scan is no attachment.
    it "refuses cached data that was not scanned" do
      unscanned = StudentMessageUploader.upload(StringIO.new("%PDF-1.4 demo"), :cache)
      other = StudentMessage.new(lecture: lecture, sender: teacher, subject: "s", body: "b")
      other.address_to(catalog.pick(["lecture:all"]))
      other.attachment = unscanned.to_json

      expect(other).not_to be_valid
      expect(other.errors[:attachment])
        .to include(I18n.t("submission.upload_failure_scan_required"))
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
      empty_message = StudentMessage.new(
        lecture: lecture, sender: teacher, subject: "s", body: "b",
        recipient_emails: []
      )

      mail = described_class.with(message: empty_message)
                            .student_message_email

      expect(mail.message).to be_a(ActionMailer::Base::NullMail)
    end
  end

  describe ".deliver_by_locale" do
    include ActiveJob::TestHelper

    let(:teacher) { create(:confirmed_user, locale: "de") }
    let(:student) { create(:confirmed_user, locale: "en") }
    let(:german_student) { create(:confirmed_user, locale: "de") }
    let(:message) do
      message = StudentMessage.new(lecture: lecture, sender: teacher, subject: "First session",
                                   body: "We start on Monday.")
      message.address_to(catalog.pick(["lecture:all"]),
                         labels: catalog.labels_by_locale(["lecture:all"]))
      message.save!
      message
    end

    before do
      create(:registration_user_registration, :confirmed,
             registration_campaign: campaign, user: german_student)
    end

    def deliveries
      ActionMailer::Base.deliveries.clear
      perform_enqueued_jobs { described_class.deliver_by_locale(message) }
      ActionMailer::Base.deliveries
    end

    it "writes to each student in their own language" do
      english, german = deliveries.partition { |mail| mail.bcc.to_a.include?(student.email) }

      expect(english.sole.from_addrs.join).to eq(DefaultSetting::PROJECT_NOTIFICATION_EMAIL)
      expect(english.sole.header["From"].to_s).to include("MaMpf notification")
      expect(english.sole.text_part.body.to_s).to include("Everybody in the lecture")
      expect(german.sole.bcc).to eq([german_student.email])
      expect(german.sole.text_part.body.to_s).to include("Alle Studierenden der Veranstaltung")
    end

    it "gives the sender and the staff their copy only once" do
      editor = create(:confirmed_user, locale: "en")
      lecture.editors << editor

      mails = deliveries

      expect(mails.flat_map(&:destinations).count(teacher.email)).to eq(1)
      expect(mails.flat_map(&:destinations).count(editor.email)).to eq(1)
      copy = mails.find { |mail| mail.to == [teacher.email] }
      expect(copy.cc).to eq([editor.email])
      expect(copy.bcc).to eq([german_student.email])
    end

    it "gives an editor who also registered one copy, in the cc" do
      editor = create(:confirmed_user, locale: "en")
      lecture.editors << editor
      create(:registration_user_registration, :confirmed,
             registration_campaign: campaign, user: editor)

      mails = deliveries

      addressed = mails.flat_map { |mail| mail.to.to_a + mail.cc.to_a + mail.bcc.to_a }
      expect(addressed.count(editor.email)).to eq(1)
      expect(mails.find { |mail| mail.to == [teacher.email] }.cc).to eq([editor.email])
    end

    it "sends the sender a copy when no student reads their language" do
      german_student.update!(locale: "en")

      mails = deliveries

      expect(mails.map(&:to)).to contain_exactly([teacher.email], nil)
      expect(mails.flat_map(&:destinations))
        .not_to include(DefaultSetting::PROJECT_NOTIFICATION_EMAIL)
      expect(mails.find { |mail| mail.to == [teacher.email] }.bcc.to_a).to be_empty
    end
  end
end
