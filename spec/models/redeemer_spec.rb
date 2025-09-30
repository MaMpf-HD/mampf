require "rails_helper"

RSpec.describe(Redeemer, type: :model) do
  describe "#redeem" do
    let(:lecture) { FactoryBot.create(:lecture) }
    let(:voucher) { FactoryBot.create(:voucher, lecture: lecture, role: role) }
    let(:user) { FactoryBot.create(:confirmed_user) }
    let(:params) { {} }
    let(:role) { :tutor }

    before :each do
      allow(Current).to receive(:user).and_return(user)
      # Stub the specific helper method to prevent it from accessing the filesystem.
      # Since image tags are not relevant for our tests, we replace
      # them by empty strings
      allow_any_instance_of(EmailHelper).to receive(:email_image_tag).and_return("")
    end

    shared_examples "common voucher processing" do
      it "creates a redemption" do
        expect { voucher.redeem(params) }.to change { Redemption.count }.by(1)
      end

      it "subscribes the user to the lecture" do
        voucher.redeem(params)
        expect(user.lectures).to include(lecture)
      end

      it "creates notifications about the voucher's redemption" do
        count_before = Notification.count
        voucher.redeem(params)
        lecture.reload
        expect(Notification.count).to eq(count_before + lecture.editors_and_teacher.count)
      end
    end

    context "when the voucher is for a tutor" do
      let(:tutorial1) { FactoryBot.create(:tutorial, lecture: lecture) }
      let(:tutorial2) { FactoryBot.create(:tutorial, lecture: lecture) }
      let(:params) { { tutorial_ids: [tutorial1.id, tutorial2.id] } }

      include_examples "common voucher processing"

      it "adds the tutorials to the user's given tutorials" do
        voucher.redeem(params)
        expect(user.given_tutorials).to include(tutorial1, tutorial2)
      end

      it "does not add a tutorial if its id is not in the params" do
        tutorial3 = FactoryBot.create(:tutorial, lecture: lecture)
        voucher.redeem(params)
        expect(user.given_tutorials).not_to include(tutorial3)
      end

      it "creates a redemption with the claimed tutorials" do
        voucher.redeem(params)
        redemption = Redemption.last
        expect(redemption.claimed_tutorials).to include(tutorial1, tutorial2)
      end
    end

    context "when the voucher is for an editor" do
      let(:role) { :editor }

      include_examples "common voucher processing"

      it "adds the user to the lecture's editors" do
        voucher.redeem(params)
        expect(lecture.editors).to include(user)
      end

      it "sends an email to the new editor" do
        expect do
          voucher.redeem(params)
        end.to enqueue_mail_including_params(LectureNotificationMailer, :new_editor_email,
                                             recipient: user, lecture: lecture, locale: user.locale)

        perform_enqueued_jobs do
          voucher.redeem(params)
        end

        mail = ActionMailer::Base.deliveries.last
        I18n.locale = user.locale
        assert_from_notification_mailer(mail)
        expect(mail.to).to include(user.email)
        expect(mail.subject).to include(
          I18n.t("mailer.new_editor_subject", title: lecture.title_for_viewers)
        )
        expect(mail.html_part.body).to include(
          I18n.t("mailer.new_editor",
                 title: lecture.title_with_teacher, username: user.tutorial_name)
        )
      end
    end

    context "when the voucher is for a teacher" do
      let(:role) { :teacher }

      include_examples "common voucher processing"

      it "sets the user as the lecture's teacher" do
        voucher.redeem(params)
        expect(lecture.teacher).to eq(user)
      end

      it "demotes the previous teacher to an editor" do
        previous_teacher = lecture.teacher
        voucher.redeem(params)
        expect(lecture.editors).to include(previous_teacher)
      end

      it "invalidates the voucher" do
        voucher.redeem(params)
        expect(voucher.invalidated_at).not_to be_nil
      end

      it "enqueues an email to previous and new teacher" do
        previous_teacher = lecture.teacher
        expect do
          voucher.redeem(params)
        end.to enqueue_mail_including_params(LectureNotificationMailer, :new_teacher_email,
                                             recipient: user, lecture: lecture, locale: user.locale)
          .and(enqueue_mail_including_params(LectureNotificationMailer, :previous_teacher_email,
                                             recipient: previous_teacher, lecture: lecture,
                                             locale: previous_teacher.locale))
      end

      it "sends an email to previous and new teacher" do
        previous_teacher = lecture.teacher

        perform_enqueued_jobs do
          voucher.redeem(params)
        end

        # Mail to previous teacher
        mail = ActionMailer::Base.deliveries.last
        I18n.locale = previous_teacher.locale
        assert_from_notification_mailer(mail)
        expect(mail[:from].display_names).to include(I18n.t("mailer.notification"))
        expect(mail.to).to include(previous_teacher.email)
        expect(mail.subject).to include(
          I18n.t("mailer.previous_teacher_subject", title: lecture.title_for_viewers,
                                                    new_teacher: user.tutorial_name)
        )
        expect(mail).to have_html_body.and(include_in_html_body(
                                             I18n.t("mailer.previous_teacher",
                                                    title: lecture.title_with_teacher,
                                                    new_teacher: lecture.teacher.info,
                                                    username: previous_teacher.tutorial_name)
                                           ))

        # Mail to new teacher
        mail = ActionMailer::Base.deliveries[-2]
        I18n.locale = user.locale
        assert_from_notification_mailer(mail)
        expect(mail.to).to include(user.email)
        expect(mail.subject).to include(
          I18n.t("mailer.new_teacher_subject", title: lecture.title_for_viewers)
        )
        expect(mail).to have_html_body.and(include_in_html_body(
                                             I18n.t("mailer.new_teacher",
                                                    title: lecture.title_with_teacher,
                                                    username: user.tutorial_name)
                                           ))
      end
    end

    context "when the voucher is for a speaker" do
      let(:lecture) { FactoryBot.create(:lecture, :is_seminar) }
      let(:role) { :speaker }
      let(:talk1) { FactoryBot.create(:talk, lecture: lecture) }
      let(:talk2) { FactoryBot.create(:talk, lecture: lecture) }
      let(:params) { { talk_ids: [talk1.id, talk2.id] } }
      let(:cospeaker_talk1) { FactoryBot.create(:confirmed_user) }
      let(:cospeaker_talk2) { FactoryBot.create(:confirmed_user) }
      let(:cospeaker_talk2_other) { FactoryBot.create(:confirmed_user) }

      before do
        talk1.speakers << cospeaker_talk1
        talk2.speakers << cospeaker_talk2
        talk2.speakers << cospeaker_talk2_other
      end

      include_examples "common voucher processing"

      it "adds the talks to the user's given talks" do
        voucher.redeem(params)
        expect(user.talks).to include(talk1, talk2)
      end

      it "does not add a talk if its id is not in the params" do
        talk3 = FactoryBot.create(:talk, lecture: lecture)
        voucher.redeem(params)
        expect(user.talks).not_to include(talk3)
      end

      it "creates a redemption with the claimed talks" do
        voucher.redeem(params)
        redemption = Redemption.last
        expect(redemption.claimed_talks).to include(talk1, talk2)
      end

      it "enqueues emails to every co-speaker" do
        expect do
          voucher.redeem(params)
        end.to enqueue_mail_including_params(LectureNotificationMailer, :new_speaker_email,
                                             recipient: cospeaker_talk1, speaker: user,
                                             locale: cospeaker_talk1.locale, talk: talk1)
          .and(enqueue_mail_including_params(LectureNotificationMailer, :new_speaker_email,
                                             recipient: cospeaker_talk2, speaker: user,
                                             locale: cospeaker_talk2.locale, talk: talk2))
          .and(enqueue_mail_including_params(LectureNotificationMailer, :new_speaker_email,
                                             recipient: cospeaker_talk2_other, speaker: user,
                                             locale: cospeaker_talk2_other.locale, talk: talk2))
      end

      it "does not enqueue an email to the user that redeemed the voucher" do
        expect do
          voucher.redeem(params)
        end.not_to have_enqueued_mail(LectureNotificationMailer, :new_speaker_email)
          .with(hash_including(params: hash_including(recipient: user)))
      end

      it "sends emails to every co-speaker" do
        perform_enqueued_jobs do
          voucher.redeem(params)
        end

        [cospeaker_talk1, cospeaker_talk2, cospeaker_talk2_other].each do |cospeaker|
          talk = cospeaker == cospeaker_talk1 ? talk1 : talk2
          I18n.locale = cospeaker.locale
          mail = ActionMailer::Base.deliveries.detect do |m|
            m.to.include?(cospeaker.email) &&
              m.subject.include?(I18n.t("mailer.new_speaker_subject",
                                        seminar: talk.lecture.title, title: talk.to_label))
          end
          expect(mail).not_to be_nil
          assert_from_notification_mailer(mail)
          expect(mail).to have_html_body.and(include_in_html_body(
                                               I18n.t("mailer.new_speaker",
                                                      seminar: talk.lecture.title,
                                                      title: talk.to_label,
                                                      username: cospeaker.tutorial_name,
                                                      speaker: user.info)
                                             ))
        end
      end
    end
  end
end
