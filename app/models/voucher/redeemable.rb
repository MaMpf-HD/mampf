module Redeemable
  extend ActiveSupport::Concern
  include Notifier

  included do
    has_many :redemptions, dependent: :destroy
  end

  def redeem(params)
    case role.to_sym
    when :tutor
      process_tutor_voucher(params[:tutorial_ids])
    when :editor
      process_editor_voucher
    when :teacher
      process_teacher_voucher
    when :speaker
      process_speaker_voucher(params[:talk_ids])
    end
  end

  private

    def process_tutor_voucher(tutorial_ids)
      selected_tutorials = lecture.tutorials.where(id: tutorial_ids)
      lecture.update_tutor_status!(Current.user, selected_tutorials)

      Redemption.create(user: Current.user, voucher: self,
                        claimed_tutorials: selected_tutorials)
    end

    def process_editor_voucher
      lecture.update_editor_status!(Current.user)
      notify_new_editor_by_mail(Current.user, lecture)

      Redemption.create(user: Current.user, voucher: self)
    end

    def process_teacher_voucher
      previous_teacher = lecture.teacher
      lecture.update_teacher_status!(Current.user)
      # no need to send out notifications if the teacher stays the same
      # because then there is no demotion to editor
      # (it is actually not possible to trigger this case via the GUI)
      if previous_teacher != Current.user
        notify_about_teacher_change_by_mail(lecture,
                                            previous_teacher)
      end
      invalidate!

      Redemption.create(user: Current.user, voucher: self)
    end

    def process_speaker_voucher(talk_ids)
      selected_talks = lecture.talks.where(id: talk_ids)
      lecture.update_speaker_status!(Current.user, selected_talks)
      notify_cospeakers_by_mail(Current.user, selected_talks)

      Redemption.create(user: Current.user, voucher: self,
                        claimed_talks: selected_talks)
    end

    def create_notifications!(redemption)
      lecture.editors_and_teacher.each do |editor|
        Notification.create(notifiable: redemption, recipient: editor)
      end
    end
end
