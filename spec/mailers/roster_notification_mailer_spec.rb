require "rails_helper"

describe RosterNotificationMailer do
  let(:user) { create(:user, name: "Alice", locale: "de") }

  def deliver(email)
    expect { email.deliver_now }
      .to change { ActionMailer::Base.deliveries.count }.by(1)

    ActionMailer::Base.deliveries.last
  end

  def delivered_body(mail)
    if mail.multipart?
      (mail.html_part || mail.text_part).body.decoded
    else
      mail.body.decoded
    end
  end

  describe ".added" do
    context "with a supported rosterable" do
      it "enqueues an email for a Tutorial" do
        tutorial = create(:tutorial)

        expect do
          described_class.added(user, tutorial)
        end.to have_enqueued_mail(described_class, :added_to_group_email)
      end

      it "enqueues an email for a Cohort" do
        cohort = create(:cohort)

        expect do
          described_class.added(user, cohort)
        end.to have_enqueued_mail(described_class, :added_to_group_email)
      end

      it "enqueues an email for a Talk" do
        talk = create(:talk)

        expect do
          described_class.added(user, talk)
        end.to have_enqueued_mail(described_class, :added_to_group_email)
      end
    end

    context "with a Lecture" do
      it "enqueues no email" do
        lecture = create(:lecture)

        expect do
          described_class.added(user, lecture)
        end.not_to have_enqueued_mail
      end
    end

    context "with an unsupported rosterable" do
      it "does not enqueue an email and logs instead" do
        unsupported = create(:registration_campaign)
        expect(Rails.logger).to receive(:error)
          .with(/Unsupported rosterable type: Registration::Campaign/)

        expect do
          described_class.added(user, unsupported)
        end.not_to have_enqueued_mail
      end
    end
  end

  describe ".removed" do
    context "with a supported rosterable" do
      it "enqueues an email for a Lecture" do
        lecture = create(:lecture)

        expect do
          described_class.removed(user, lecture)
        end.to have_enqueued_mail(described_class, :removed_from_lecture_email)
      end

      it "enqueues an email for a Tutorial" do
        tutorial = create(:tutorial)

        expect do
          described_class.removed(user, tutorial)
        end.to have_enqueued_mail(described_class, :removed_from_group_email)
      end

      it "enqueues an email for a Cohort" do
        cohort = create(:cohort)

        expect do
          described_class.removed(user, cohort)
        end.to have_enqueued_mail(described_class, :removed_from_group_email)
      end

      it "enqueues an email for a Talk" do
        talk = create(:talk)

        expect do
          described_class.removed(user, talk)
        end.to have_enqueued_mail(described_class, :removed_from_group_email)
      end
    end

    context "with an unsupported rosterable" do
      it "does not enqueue an email and logs instead" do
        unsupported = create(:registration_campaign)
        expect(Rails.logger).to receive(:error)
          .with(/Unsupported rosterable type: Registration::Campaign/)

        expect do
          described_class.removed(user, unsupported)
        end.not_to have_enqueued_mail
      end
    end
  end

  describe ".moved" do
    context "with a supported rosterable" do
      it "enqueues an email for a Lecture" do
        old_lecture = create(:lecture)
        new_lecture = create(:lecture)

        expect do
          described_class.moved(user, old_lecture, new_lecture)
        end.to have_enqueued_mail(described_class, :moved_between_groups_email)
      end

      it "enqueues an email for a Tutorial" do
        old_tutorial = create(:tutorial)
        new_tutorial = create(:tutorial)

        expect do
          described_class.moved(user, old_tutorial, new_tutorial)
        end.to have_enqueued_mail(described_class, :moved_between_groups_email)
      end

      it "enqueues an email for a Cohort" do
        old_cohort = create(:cohort)
        new_cohort = create(:cohort)

        expect do
          described_class.moved(user, old_cohort, new_cohort)
        end.to have_enqueued_mail(described_class, :moved_between_groups_email)
      end

      it "enqueues an email for a Talk" do
        old_talk = create(:talk)
        new_talk = create(:talk)

        expect do
          described_class.moved(user, old_talk, new_talk)
        end.to have_enqueued_mail(described_class, :moved_between_groups_email)
      end
    end

    context "when the move is between tutorials" do
      let(:lecture) { create(:lecture) }
      let(:old_tutorial) { create(:tutorial, lecture: lecture, title: "Mo 10") }
      let(:new_tutorial) { create(:tutorial, lecture: lecture, title: "Di 14") }
      let!(:old_tutor) { create(:tutor_tutorial_join, tutorial: old_tutorial).tutor }
      let!(:new_tutor) { create(:tutor_tutorial_join, tutorial: new_tutorial).tutor }

      it "tells the tutor left behind that the work stays with them" do
        expect do
          described_class.moved(user, old_tutorial, new_tutorial)
        end.to have_enqueued_mail(described_class, :participant_left_group_email)
          .with(a_hash_including(params: a_hash_including(recipient: old_tutor)))
      end

      it "tells the receiving tutor that someone joins them" do
        expect do
          described_class.moved(user, old_tutorial, new_tutorial)
        end.to have_enqueued_mail(described_class, :participant_joined_group_email)
          .with(a_hash_including(params: a_hash_including(recipient: new_tutor)))
      end

      it "names the participant and where their earlier work stays" do
        email = described_class.with(
          participant: user,
          rosterable: old_tutorial,
          old_rosterable: old_tutorial,
          new_rosterable: new_tutorial,
          recipient: old_tutor
        ).participant_left_group_email

        delivered = deliver(email)

        expect(delivered.to).to eq([old_tutor.email])
        expect(delivered.subject).to include("Mo 10")
        expect(delivered_body(delivered)).to include("Alice")
        expect(delivered_body(delivered)).to include("Di 14")
      end
    end

    context "with an unsupported rosterable" do
      it "does not enqueue an email and logs instead" do
        old_unsupported = create(:registration_campaign)
        new_unsupported = create(:registration_campaign)
        expect(Rails.logger).to receive(:error)
          .with(/Unsupported rosterable type: Registration::Campaign/)

        expect do
          described_class.moved(user, old_unsupported, new_unsupported)
        end.not_to have_enqueued_mail
      end

      it "does not enqueue an email when only the target is unsupported" do
        old_tutorial = create(:tutorial)
        new_unsupported = create(:registration_campaign)
        expect(Rails.logger).to receive(:error)
          .with(/Unsupported rosterable type: Registration::Campaign/)

        expect do
          described_class.moved(user, old_tutorial, new_unsupported)
        end.not_to have_enqueued_mail
      end
    end
  end

  describe "#added_to_group_email" do
    context "with a tutorial" do
      let(:rosterable) { create(:tutorial, title: "Übung 3") }

      it "sends the correct email" do
        email = described_class.with(
          rosterable: rosterable,
          recipient: user
        ).added_to_group_email

        delivered = deliver(email)

        expect(delivered.to).to eq([user.email])
        expect(delivered[:from].value).to eq(NotificationMailer.sender(user.locale))
        expect(delivered.subject).to include("Übung 3")
        expect(delivered_body(delivered)).to include("hinzugefügt")
        expect(delivered_body(delivered)).to include("Alice")
      end

      it "links to the lecture home" do
        email = described_class.with(
          rosterable: rosterable,
          recipient: user
        ).added_to_group_email

        delivered = deliver(email)

        expect(delivered_body(delivered)).to match(%r{https?://\S*lectures\S*})
      end
    end

    context "with a talk" do
      let(:rosterable) { create(:talk, title: "Vortrag 1") }

      it "links to the talk" do
        email = described_class.with(
          rosterable: rosterable,
          recipient: user
        ).added_to_group_email

        delivered = deliver(email)

        expect(delivered.subject).to include("Vortrag 1")
        expect(delivered_body(delivered)).to match(%r{https?://\S*talks\S*})
      end
    end
  end

  describe "#removed_from_group_email" do
    let(:rosterable) { create(:tutorial, title: "Übung 3") }

    it "sends the correct email" do
      email = described_class.with(
        rosterable: rosterable,
        recipient: user
      ).removed_from_group_email

      delivered = deliver(email)

      expect(delivered.subject).to include("Übung 3")
      expect(delivered_body(delivered)).to include("entfernt")
    end
  end

  describe "#removed_from_lecture_email" do
    let(:rosterable) { create(:lecture) }

    it "sends the correct email" do
      email = described_class.with(
        rosterable: rosterable,
        recipient: user
      ).removed_from_lecture_email

      delivered = deliver(email)

      # Lecture#title carries a translated type prefix, so it has to be read in
      # the locale the mail was rendered in.
      expected_title = I18n.with_locale(user.locale) { rosterable.title }
      expect(delivered.subject).to include(expected_title)
      expect(delivered_body(delivered)).to include("entfernt")
    end
  end

  describe "#moved_between_groups_email" do
    let(:old_group) { create(:tutorial, title: "Übung 1") }
    let(:new_group) { create(:tutorial, title: "Übung 2") }

    it "sends the correct email" do
      email = described_class.with(
        old_rosterable: old_group,
        new_rosterable: new_group,
        recipient: user
      ).moved_between_groups_email

      delivered = deliver(email)

      expect(delivered.subject).to include("Übung 2")
      expect(delivered_body(delivered)).to include("Übung 1")
      expect(delivered_body(delivered)).to include("Übung 2")
      expect(delivered_body(delivered)).to include("Alice")
    end
  end

  describe ".finalized" do
    let(:other_user) { create(:user, locale: "de") }
    let(:english_user) { create(:user, locale: "en") }

    before do
      user
      other_user
      english_user
      ActionMailer::Base.deliveries.clear
    end

    context "with a supported rosterable" do
      it "enqueues one email for all users of a Tutorial with the same locale" do
        tutorial = create(:tutorial)

        expect do
          described_class.finalized(tutorial, [user, other_user])
        end.to have_enqueued_mail(described_class, :added_to_group_email).once.with(
          a_hash_including(
            params: a_hash_including(
              rosterable: tutorial,
              recipients: match_array([user, other_user])
            )
          )
        )
      end

      it "enqueues one email per locale" do
        tutorial = create(:tutorial)

        expect do
          described_class.finalized(tutorial, [user, other_user, english_user])
        end.to have_enqueued_mail(described_class, :added_to_group_email).twice
      end

      it "does not address the users individually" do
        tutorial = create(:tutorial)

        expect do
          described_class.finalized(tutorial, [user])
        end.not_to have_enqueued_mail(described_class, :added_to_group_email).with(
          a_hash_including(params: a_hash_including(recipient: user))
        )
      end

      it "enqueues an email for a Cohort" do
        cohort = create(:cohort)

        expect do
          described_class.finalized(cohort, [user])
        end.to have_enqueued_mail(described_class, :added_to_group_email)
      end

      it "enqueues an email for a Talk" do
        talk = create(:talk)

        expect do
          described_class.finalized(talk, [user])
        end.to have_enqueued_mail(described_class, :added_to_group_email)
      end
    end

    context "with an unsupported rosterable" do
      it "does not enqueue an email and logs instead" do
        unsupported = create(:registration_campaign)
        expect(Rails.logger).to receive(:error)
          .with(/Unsupported rosterable type: Registration::Campaign/)

        expect do
          described_class.finalized(unsupported, [user])
        end.not_to have_enqueued_mail
      end
    end

    context "with an empty user list" do
      it "enqueues no email" do
        tutorial = create(:tutorial)

        expect do
          described_class.finalized(tutorial, [])
        end.not_to have_enqueued_mail
      end
    end

    context "with an Exam" do
      it "enqueues an email for an Exam" do
        exam = create(:exam, :written)

        expect do
          described_class.finalized(exam, [user])
        end.to have_enqueued_mail(described_class, :added_to_exam_email)
      end

      it "delivers a mail with the exam subject and schedule details" do
        exam = create(:exam, :written, date: Time.zone.parse("2026-11-15 10:00"),
                                       location: "Room 101")

        email = described_class.with(rosterable: exam, recipient: user).added_to_exam_email
        delivered = deliver(email)

        expected_subject = I18n.with_locale(user.locale) do
          I18n.t("roster.mailer.roster_added_to_exam_email_subject",
                 rosterable_title: exam.title,
                 lecture_title: exam.lecture.title)
        end
        expect(delivered.subject).to eq(expected_subject)

        body = delivered_body(delivered)
        expect(body).to include(I18n.l(exam.date, format: :long, locale: user.locale))
        expect(body).to include("Room 101")
      end

      it "enqueues one email per locale" do
        exam = create(:exam, :written)

        expect do
          described_class.finalized(exam, [user, other_user])
        end.to have_enqueued_mail(described_class, :added_to_exam_email).once

        expect do
          described_class.finalized(exam, [user, english_user])
        end.to have_enqueued_mail(described_class, :added_to_exam_email).twice
      end
    end

    context "with a tutorial" do
      let(:tutorial) { create(:tutorial, title: "Übung 3") }

      it "sends one mail in bcc with a link to the lecture home" do
        expect do
          perform_enqueued_jobs do
            described_class.finalized(tutorial, [user, other_user])
          end
        end.to change { ActionMailer::Base.deliveries.count }.by(1)

        delivered = ActionMailer::Base.deliveries.last

        expect(delivered.bcc).to match_array([user.email, other_user.email])
        expect(delivered.to).to be_blank
        expect(delivered.subject).to include("Übung 3")
        expect(delivered_body(delivered)).to match(%r{https?://\S*lectures\S*})
      end

      it "sends one mail per locale, each only to its own group" do
        expect do
          perform_enqueued_jobs do
            described_class.finalized(tutorial, [user, other_user, english_user])
          end
        end.to change { ActionMailer::Base.deliveries.count }.by(2)

        bccs = ActionMailer::Base.deliveries.last(2).map(&:bcc)

        expect(bccs).to contain_exactly(
          match_array([user.email, other_user.email]),
          [english_user.email]
        )
      end
    end

    context "with a talk" do
      let(:seminar) { create(:seminar) }
      let(:talk) { create(:talk, title: "Talk 3", lecture: seminar) }

      it "sends one mail in bcc with a link to the talk" do
        expect do
          perform_enqueued_jobs do
            described_class.finalized(talk, [user, other_user])
          end
        end.to change { ActionMailer::Base.deliveries.count }.by(1)

        delivered = ActionMailer::Base.deliveries.last

        expect(delivered.bcc).to match_array([user.email, other_user.email])
        expect(delivered.to).to be_blank
        expect(delivered.subject).to include("Talk 3")
        expect(delivered_body(delivered)).to match(%r{https?://\S*talks\S*})
      end
    end
  end

  describe ".change_exam_schedule" do
    let(:exam) { create(:exam, :written) }
    let(:other_user) { create(:user, locale: "de") }
    let(:english_user) { create(:user, locale: "en") }

    it "enqueues one email for all participants with the same locale" do
      [user, other_user].each { |participant| exam.add_user_to_roster!(participant) }

      expect do
        described_class.change_exam_schedule(exam)
      end.to have_enqueued_mail(described_class, :change_exam_schedule_email).once.with(
        a_hash_including(
          params: a_hash_including(
            rosterable: exam,
            recipients: match_array([user, other_user])
          )
        )
      )
    end

    it "enqueues one email per locale" do
      [user, other_user, english_user].each { |participant| exam.add_user_to_roster!(participant) }

      expect do
        described_class.change_exam_schedule(exam)
      end.to have_enqueued_mail(described_class, :change_exam_schedule_email).twice
    end

    it "enqueues no email when nobody is on the roster" do
      expect do
        described_class.change_exam_schedule(exam)
      end.not_to have_enqueued_mail
    end

    it "does not enqueue an email for a non-exam and logs instead" do
      tutorial = create(:tutorial)
      expect(Rails.logger).to receive(:error)
        .with(/Unsupported rosterable type: Tutorial/)

      expect do
        described_class.change_exam_schedule(tutorial)
      end.not_to have_enqueued_mail
    end
  end

  describe "grouped mails" do
    let(:other_user) { create(:user, name: "Carol", locale: "de") }

    context "for exam" do
      let(:exam) do
        create(:exam, :written, date: Time.zone.parse("2026-11-15 10:00"), location: "Room 101")
      end
      it "puts all recipients in bcc and none in to" do
        email = described_class.with(
          rosterable: exam,
          recipients: [user, other_user]
        ).change_exam_schedule_email

        delivered = deliver(email)

        expect(delivered.bcc).to match_array([user.email, other_user.email])
        expect(delivered.to).to be_blank
        expect(delivered[:from].value).to eq(NotificationMailer.sender("de"))
      end

      it "carries the new schedule in the change mail with a link to the lecture home" do
        email = described_class.with(
          rosterable: exam,
          recipients: [user]
        ).change_exam_schedule_email

        delivered = deliver(email)

        expected_subject = I18n.with_locale(user.locale) do
          I18n.t("roster.mailer.roster_change_exam_schedule_email_subject",
                 rosterable_title: exam.title,
                 lecture_title: exam.lecture.title)
        end
        expect(delivered.subject).to eq(expected_subject)

        body = delivered_body(delivered)
        expect(body).to include(I18n.l(exam.date, format: :long, locale: user.locale))
        expect(body).to include("Room 101")
        expect(delivered_body(delivered)).to match(%r{https?://\S*lectures\S*})
      end
    end
  end

  describe ".rejected" do
    let(:reasons) { ["Email domain not allowed."] }
    let(:lecture) { create(:lecture) }

    context "for a group campaign" do
      it "enqueues a group rejection email with the lecture and the reasons" do
        expect do
          described_class.rejected(user, reasons: reasons,
                                         exam_campaign: false, lecture: lecture)
        end.to have_enqueued_mail(described_class, :rejected_from_group_email).with(
          a_hash_including(
            params: a_hash_including(lecture: lecture, recipient: user, reasons: reasons)
          )
        )
      end

      it "sends one email per student" do
        other_user = create(:user, locale: "de")

        expect do
          described_class.rejected(user, reasons: reasons,
                                         exam_campaign: false, lecture: lecture)
          described_class.rejected(other_user, reasons: reasons,
                                               exam_campaign: false, lecture: lecture)
        end.to have_enqueued_mail(described_class, :rejected_from_group_email).twice
      end
    end

    context "for an exam campaign" do
      let(:exam) { create(:exam, :written, lecture: lecture) }

      it "enqueues an exam rejection email with the exam and the reasons" do
        expect do
          described_class.rejected(user, reasons: reasons,
                                         exam_campaign: true, exam: exam, lecture: lecture)
        end.to have_enqueued_mail(described_class, :rejected_from_exam_email).with(
          a_hash_including(
            params: a_hash_including(rosterable: exam, recipient: user, reasons: reasons)
          )
        )
      end

      it "does not enqueue a group rejection email" do
        expect do
          described_class.rejected(user, reasons: reasons,
                                         exam_campaign: true, exam: exam, lecture: lecture)
        end.not_to have_enqueued_mail(described_class, :rejected_from_group_email)
      end
    end
  end

  describe "the plain text translations" do
    I18n.available_locales.each do |locale|
      it "carry no markup in #{locale}" do
        I18n.t("roster.mailer", locale: locale)
            .reject { |key, _| key.to_s.end_with?("_html") }
            .each do |key, value|
          expect(value).not_to match(%r{<[a-z/][^>]*>}i),
                               "roster.mailer.#{key} (#{locale}) contains markup: #{value.inspect}"
        end
      end
    end
  end

  describe "the text part of a delivered mail" do
    let(:rosterable) { create(:tutorial, title: "Übung 3") }

    def text_part_of(email)
      deliver(email).text_part.body.decoded
    end

    def expect_plain_text(body)
      expect(body).to include("Alice")
      expect(body).not_to match(%r{<[a-z/][^>]*>}i)
    end

    it "carries no markup when a user is added to a group" do
      expect_plain_text(text_part_of(described_class.with(
        rosterable: rosterable, recipient: user
      ).added_to_group_email))
    end

    it "carries no markup when a user is removed from a group" do
      expect_plain_text(text_part_of(described_class.with(
        rosterable: rosterable, recipient: user
      ).removed_from_group_email))
    end

    it "carries no markup when a user is removed from a lecture" do
      expect_plain_text(text_part_of(described_class.with(
        rosterable: create(:lecture), recipient: user
      ).removed_from_lecture_email))
    end

    it "carries no markup when a user is moved between groups" do
      expect_plain_text(text_part_of(described_class.with(
        old_rosterable: rosterable,
        new_rosterable: create(:tutorial, title: "Übung 7"),
        recipient: user
      ).moved_between_groups_email))
    end

    it "carries no markup in a mail to a whole group" do
      body = text_part_of(described_class.with(
        rosterable: rosterable, recipients: [user]
      ).added_to_group_email)

      expect(body).not_to include("Alice")
      expect(body).not_to match(%r{<[a-z/][^>]*>}i)
    end

    it "names both the tutor and the participant when someone leaves a tutorial" do
      tutor = create(:confirmed_user, name: "Bob", locale: "de")

      body = text_part_of(described_class.with(
        participant: user,
        rosterable: rosterable,
        old_rosterable: rosterable,
        new_rosterable: create(:tutorial, title: "Übung 7"),
        recipient: tutor
      ).participant_left_group_email)

      expect(body).to include("Bob")
      expect_plain_text(body)
    end

    it "spells the group link out as a plain URL" do
      talk = create(:talk)

      body = text_part_of(described_class.with(
        rosterable: talk, recipient: user
      ).added_to_group_email)

      expect(body).to match(%r{https?://\S*/talks/#{talk.id}})
    end
  end
end
