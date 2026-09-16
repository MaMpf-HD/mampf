# Triggered whenever a user is added to / removed from / moved between group(s)
# of a rosterable object
class RosterNotificationMailer < ApplicationMailer
  SUPPORTED_ROSTERABLES = [Lecture, Tutorial, Cohort, Talk, Exam].freeze

  class << self
    def added(user, rosterable)
      return log_unsupported(rosterable) unless supported?(rosterable)

      # A bare lecture roster entry grants no access, so there is nothing to announce.
      return if rosterable.is_a?(Lecture)

      template  = rosterable.is_a?(Exam) ? :added_to_exam_email : :added_to_group_email
      info      = rosterable.is_a?(Exam) ? exam_info(rosterable) : {}

      with(
        rosterable: rosterable,
        recipient: user,
        info: info
      ).public_send(template).deliver_later
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
      return log_unsupported(rosterable) if rosterable.is_a?(Exam)

      with(
        old_rosterable: old_rosterable,
        new_rosterable: new_rosterable,
        recipient: user
      ).moved_between_groups_email.deliver_later

      notify_tutors(user, old_rosterable, new_rosterable)
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

      def exam_info(rosterable)
        return {} unless rosterable.is_a?(Exam)

        { exam_date: I18n.l(rosterable.date, format: :long),
          exam_location: rosterable.location.presence || "N/A" }
      end
  end

  def added_to_group_email
    email { t("roster.mailer.roster_added_to_group_email_subject", **subject_vars) }
  end

  def added_to_exam_email
    email { t("roster.mailer.roster_added_to_exam_email_subject", **subject_vars) }
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

  def participant_left_group_email
    email { t("roster.mailer.roster_participant_left_group_email_subject", **subject_vars) }
  end

  def participant_joined_group_email
    email { t("roster.mailer.roster_participant_joined_group_email_subject", **subject_vars) }
  end

  private

    def prepare_data(params)
      @rosterable      = params[:rosterable]
      @old_rosterable  = params[:old_rosterable]
      @new_rosterable  = params[:new_rosterable]
      @recipient       = params[:recipient]
      @participant     = params[:participant]
      @username        = @recipient.tutorial_name
      @rosterable_link = url_for_rosterable(@rosterable || @new_rosterable)
      @lecture         = lecture_for_rosterable(@rosterable || @new_rosterable)
      @info            = params[:info] || {}
    end

    def email
      prepare_data(params)
      I18n.with_locale(@recipient.locale || I18n.default_locale) do
        mail(
          from: NotificationMailer.sender(@recipient.locale),
          to: @recipient.email,
          subject: yield
        )
      end
    end

    def subject_vars
      {
        rosterable_title: @rosterable&.title || @new_rosterable&.title,
        lecture_title: @lecture&.title || "",
        participant_name: @participant&.tutorial_name
      }
    end

    def lecture_for_rosterable(rosterable)
      if rosterable.is_a?(Lecture)
        rosterable
      else
        rosterable&.lecture
      end
    end

    def url_for_rosterable(rosterable)
      return nil if rosterable.nil?

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
end
