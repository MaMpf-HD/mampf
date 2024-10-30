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
        end.to enqueue_mail_with_params(LectureNotificationMailer, :new_editor_email,
                                        recipient: user, lecture: lecture, locale: user.locale)

        perform_enqueued_jobs do
          voucher.redeem(params)
        end

        mail = ActionMailer::Base.deliveries.last
        I18n.locale = user.locale
        expect(mail.from).to include(DefaultSetting::PROJECT_NOTIFICATION_EMAIL)
        expect(mail[:from].display_names).to include(I18n.t("mailer.notification"))
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
        end.to enqueue_mail_with_params(LectureNotificationMailer, :new_teacher_email,
                                        recipient: user, lecture: lecture, locale: user.locale)
          .and(enqueue_mail_with_params(LectureNotificationMailer, :previous_teacher_email,
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
        expect(mail.from).to eq([DefaultSetting::PROJECT_NOTIFICATION_EMAIL])
        expect(mail[:from].display_names).to include(I18n.t("mailer.notification"))
        expect(mail.to).to include(previous_teacher.email)
        expect(mail.subject).to include(
          I18n.t("mailer.previous_teacher_subject", title: lecture.title_for_viewers,
                                                    new_teacher: user.tutorial_name)
        )
        expect(mail.html_part.body.decoded.gsub(/[\r\n]/, "")).to include(
          I18n.t("mailer.previous_teacher",
                 title: lecture.title_with_teacher,
                 new_teacher: lecture.teacher.info, username: previous_teacher.tutorial_name)
              .gsub(/[\r\n]/, "")
        )

        # Mail to new teacher
        mail = ActionMailer::Base.deliveries[-2]
        I18n.locale = user.locale
        expect(mail.from).to eq([DefaultSetting::PROJECT_NOTIFICATION_EMAIL])
        expect(mail[:from].display_names).to include(I18n.t("mailer.notification"))
        expect(mail.to).to include(user.email)
        expect(mail.subject).to include(
          I18n.t("mailer.new_teacher_subject", title: lecture.title_for_viewers)
        )
        expect(mail.html_part.body).to include(
          I18n.t("mailer.new_teacher",
                 title: lecture.title_with_teacher, username: user.tutorial_name)
        )
      end
    end

    context "when the voucher is for a speaker" do
      let(:lecture) { FactoryBot.create(:lecture, :is_seminar) }
      let(:role) { :speaker }
      let(:talk1) { FactoryBot.create(:talk, lecture: lecture) }
      let(:talk2) { FactoryBot.create(:talk, lecture: lecture) }
      let(:params) { { talk_ids: [talk1.id, talk2.id] } }

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
    end
  end
end
