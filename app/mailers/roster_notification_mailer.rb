# Triggered whenever a user is added to / removed from / moved between group(s)
# of a rosterable object
class RosterNotificationMailer < ApplicationMailer
  SUPPORTED_ROSTERABLES = [Lecture, Tutorial, Cohort, Talk, Exam].freeze

  class << self
    def added(user, rosterable)
      return log_unsupported(rosterable) unless supported?(rosterable)

      # A bare lecture roster entry grants no access, so there is nothing to announce.
      return if rosterable.is_a?(Lecture)

      with(
        rosterable: rosterable,
        recipient: user
      ).public_send(added_template(rosterable)).deliver_later
    end

    def removed(user, rosterable)
      return log_unsupported(rosterable) unless supported?(rosterable)

      template =
        case rosterable
        when Lecture then :removed_from_lecture_email
        when Exam    then :removed_from_exam_email
        else              :removed_from_group_email
        end
      with(
        rosterable: rosterable,
        recipient: user
      ).public_send(template).deliver_later
    end

    def moved(user, old_rosterable, new_rosterable)
      return log_unsupported(old_rosterable) unless supported?(old_rosterable)
      return log_unsupported(new_rosterable) unless supported?(new_rosterable)
      return log_unsupported(old_rosterable) if old_rosterable.is_a?(Exam)
      return log_unsupported(new_rosterable) if new_rosterable.is_a?(Exam)

      with(
        old_rosterable: old_rosterable,
        new_rosterable: new_rosterable,
        recipient: user
      ).moved_between_groups_email.deliver_later

      notify_tutors(user, old_rosterable, new_rosterable)
    end

    def change_exam_schedule(rosterable)
      return log_unsupported(rosterable) unless rosterable.is_a?(Exam)

      users = rosterable.roster_entries.includes(:user).map(&:user)
      deliver_grouped(:change_exam_schedule_email, rosterable, users)
    end

    def finalized(rosterable, users)
      return log_unsupported(rosterable) unless supported?(rosterable)
      return if rosterable.is_a?(Lecture)

      deliver_grouped(added_template(rosterable), rosterable, users)
    end

    def rejected(user, campaign, reasons:)
      if campaign.exam_campaign?
        with(rosterable: campaign.exam,
             reasons: reasons,
             recipient: user).rejected_from_exam_email.deliver_later
      else
        with(lecture: campaign.campaignable,
             reasons: reasons,
             recipient: user).rejected_from_group_email.deliver_later
      end
    end

    def log_unsupported(rosterable)
      Rails.logger.error(
        "RosterNotificationMailer: Unsupported rosterable type: #{rosterable.class.name}"
      )
      nil
    end

    private

      def supported?(rosterable)
        SUPPORTED_ROSTERABLES.any? { |klass| rosterable.is_a?(klass) }
      end

      def added_template(rosterable)
        rosterable.is_a?(Exam) ? :added_to_exam_email : :added_to_group_email
      end

      # Only a tutorial has someone responsible for it. The two sides hear different
      # news: work handed in before the move stays with the tutorial it was handed in to.
      def notify_tutors(user, old_rosterable, new_rosterable)
        return unless old_rosterable.is_a?(Tutorial) && new_rosterable.is_a?(Tutorial)

        [[old_rosterable, :participant_left_group_email],
         [new_rosterable, :participant_joined_group_email]].each do |tutorial, template|
          tutorial.tutors.each do |tutor|
            with(participant: user,
                 rosterable: tutorial,
                 old_rosterable: old_rosterable,
                 new_rosterable: new_rosterable,
                 recipient: tutor).public_send(template).deliver_later
          end
        end
      end

      # One mail per language, members in bcc.
      def deliver_grouped(template, rosterable, users)
        users.group_by(&:locale).each_value do |users_in_locale|
          t = users_in_locale
          with(rosterable: rosterable,
               recipients: users_in_locale).public_send(template).deliver_later
        end
      end
  end

  def added_to_group_email
    email { t("roster.mailer.roster_added_to_group_email_subject", **subject_vars) }
  end

  def added_to_exam_email
    email do
      add_exam_details
      t("roster.mailer.roster_added_to_exam_email_subject", **subject_vars)
    end
  end

  def removed_from_group_email
    email { t("roster.mailer.roster_removed_from_group_email_subject", **subject_vars) }
  end

  def removed_from_exam_email
    email { t("roster.mailer.roster_removed_from_exam_email_subject", **subject_vars) }
  end

  def moved_between_groups_email
    email { t("roster.mailer.roster_moved_between_groups_email_subject", **subject_vars) }
  end

  def removed_from_lecture_email
    email { t("roster.mailer.roster_removed_from_lecture_email_subject", **subject_vars) }
  end

  def rejected_from_group_email
    rejection_email("roster.mailer.roster_rejected_from_group_email_subject")
  end

  def rejected_from_exam_email
    rejection_email("roster.mailer.roster_rejected_from_exam_email_subject")
  end

  def participant_left_group_email
    email { t("roster.mailer.roster_participant_left_group_email_subject", **subject_vars) }
  end

  def participant_joined_group_email
    email { t("roster.mailer.roster_participant_joined_group_email_subject", **subject_vars) }
  end

  def change_exam_schedule_email
    email do
      add_exam_details
      t("roster.mailer.roster_change_exam_schedule_email_subject", **subject_vars)
    end
  end

  private

    def prepare_data(params)
      @rosterable      = params[:rosterable]
      @old_rosterable  = params[:old_rosterable]
      @new_rosterable  = params[:new_rosterable]
      @recipient       = params[:recipient]
      @recipients      = params[:recipients]
      @participant     = params[:participant]
      @username        = @recipient&.tutorial_name
      rosterable = @rosterable || @new_rosterable
      @rosterable_link = url_for_rosterable(rosterable) if rosterable
      @lecture         = params[:lecture] ||
                         lecture_for_rosterable(@rosterable || @new_rosterable)
      @info            = {}
    end

    # Single recipient: addressed directly.
    # Multiple recipients: members in bcc.
    def email
      prepare_data(params)
      addressees = @recipient ? [@recipient] : @recipients
      locale = addressees.first.locale
      addressing = @recipient ? { to: @recipient.email } : { bcc: @recipients.map(&:email) }
      I18n.with_locale(locale || I18n.default_locale) do
        mail(
          from: NotificationMailer.sender(locale),
          **addressing,
          subject: yield
        )
      end
    end

    def rejection_email(subject_key)
      email do
        @info[:reason_link] = lecture_home_url(@lecture) if @lecture
        @info[:reasons] = rejection_reasons(params[:reasons])
        t(subject_key, **subject_vars)
      end
    end

    def subject_vars
      {
        rosterable_title: @rosterable&.title || @new_rosterable&.title,
        lecture_title: @lecture&.title || "",
        participant_name: @participant&.tutorial_name
      }
    end

    def rejection_reasons(reasons)
      reasons&.join(", ")
    end

    def lecture_for_rosterable(rosterable)
      if rosterable.is_a?(Lecture)
        rosterable
      else
        rosterable&.lecture
      end
    end

    def url_for_rosterable(rosterable)
      case rosterable
      when Lecture
        lecture_url(rosterable)
      when Tutorial, Cohort
        nil
      when Talk
        talk_url(rosterable)
      when Exam
        lecture_home_url(rosterable.lecture)
      else
        raise(ArgumentError,
              "Unknown rosterable type: #{rosterable.class.name}")
      end
    end

    def add_exam_details
      scope = "roster.mailer.exam_schedule"

      exam_date     = (I18n.l(@rosterable.date, format: :long) if @rosterable.date)
      exam_location = @rosterable.location.presence

      @info[:exam_date]     = exam_date
      @info[:exam_location] = exam_location

      parts = []

      # Sentence with known information
      if exam_date || exam_location
        sentence = [I18n.t("#{scope}.first_part")]
        sentence << I18n.t("#{scope}.date_part", exam_date: exam_date) if exam_date
        sentence << I18n.t("#{scope}.location_part", exam_location: exam_location) if exam_location

        last_part = I18n.t("#{scope}.last_part")
        sentence << last_part if last_part.present?

        parts << "#{sentence.join(" ")}."
      end

      # Sentence for missing information
      missing = []
      missing << I18n.t("#{scope}.date_ops") unless exam_date
      missing << I18n.t("#{scope}.location_ops") unless exam_location

      if missing.any?
        parts << I18n.t("#{scope}.non_available_info",
                        count: missing.size,
                        non_avai_ops: missing.to_sentence)
      end

      @info[:exam_schedule] = parts.join(" ").strip
    end
end
