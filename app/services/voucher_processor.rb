class VoucherProcessor < ApplicationService
  include Notifier

  def initialize(voucher, user, params)
    super
    @voucher = voucher
    @lecture = voucher.lecture
    @user = user
    @params = params
  end

  def call
    redemption = process_voucher
    create_notifications!(redemption)
    @user.subscribe_lecture!(@lecture)
  end

  private

    def process_voucher
      case @voucher.role.to_sym
      when :tutor
        process_tutor_voucher
      when :editor
        process_editor_voucher
      when :teacher
        process_teacher_voucher
      when :speaker
        process_speaker_voucher
      end
    end

    def process_tutor_voucher
      selected_tutorials = @lecture.tutorials.where(id: @params[:tutorial_ids])
      @lecture.update_tutor_status!(@user, selected_tutorials)

      Redemption.create(user: @user, voucher: @voucher,
                        claimed_tutorials: selected_tutorials)
    end

    def process_editor_voucher
      @lecture.update_editor_status!(@user)
      notify_new_editor_by_mail(@user, @lecture)

      Redemption.create(user: @user, voucher: @voucher)
    end

    def process_teacher_voucher
      previous_teacher = @lecture.teacher
      @lecture.update_teacher_status!(@user)
      # no need to send out notifications if the teacher stays the same
      # because then there is no demotion to editor
      # (it is actually not possible to trigger this case via the GUI)
      notify_about_teacher_change_by_mail(@lecture, previous_teacher) if previous_teacher != @user
      @voucher.invalidate!

      Redemption.create(user: @user, voucher: @voucher)
    end

    def process_speaker_voucher
      selected_talks = @lecture.talks.where(id: @params[:talk_ids])
      @lecture.update_speaker_status!(@user, selected_talks)
      notify_cospeakers_by_mail(@user, selected_talks)

      Redemption.create(user: @user, voucher: @voucher,
                        claimed_talks: selected_talks)
    end

    def create_notifications!(redemption)
      @lecture.editors_and_teacher.each do |editor|
        Notification.create(notifiable: redemption, recipient: editor)
      end
    end
end
