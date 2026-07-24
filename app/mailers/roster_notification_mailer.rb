class RosterNotificationMailer < ApplicationMailer
  # Triggered whenever a user is added to / removed from / moved between group(s)
  # of a rosterable object

  class << self
    def added(user, rosterable)
      template = if rosterable.is_a?(Lecture)
        :added_to_lecture_email
      else
        :added_to_group_email
      end
      with(
        rosterable: rosterable,
        recipient: user
      ).public_send(template).deliver_later
    end

    def removed(user, rosterable)
      template = rosterable.is_a?(Lecture) ? :removed_from_lecture_email : :removed_from_group_email

      with(
        rosterable: rosterable,
        recipient: user
      ).public_send(template).deliver_later
    end

    def moved(user, old_rosterable, new_rosterable)
      with(
        old_rosterable: old_rosterable,
        new_rosterable: new_rosterable,
        recipient: user
      ).moved_between_groups_email.deliver_later
    end
  end

  def added_to_group_email
    email("roster.mailer.roster_added_to_group_email_subject")
  end

  def removed_from_group_email
    email("roster.mailer.roster_removed_from_group_email_subject")
  end

  def moved_between_groups_email
    email("roster.mailer.roster_moved_between_groups_email_subject")
  end

  def added_to_lecture_email
    email("roster.mailer.roster_added_to_lecture_email_subject")
  end

  def removed_from_lecture_email
    email("roster.mailer.roster_removed_from_lecture_email_subject")
  end

  private

    def prepare_data(params)
      @rosterable      = params[:rosterable]
      @old_rosterable  = params[:old_rosterable]
      @new_rosterable  = params[:new_rosterable]
      @recipient       = params[:recipient]
      @username        = @recipient.tutorial_name
      @rosterable_link = url_for_rosterable(@rosterable || @new_rosterable)
      @lecture         = lecture_for_rosterable(@rosterable || @new_rosterable)
    end

    def email(mail_template)
      prepare_data(params)
      I18n.with_locale(@recipient.locale || I18n.default_locale) do
        mail(
          from: NotificationMailer.sender(@recipient.locale),
          to: @recipient.email,
          subject: t(
            mail_template,
            rosterable_title: @rosterable&.title || @new_rosterable&.title,
            lecture_title: @lecture&.title || ""
          )
        )
      end
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
      else
        raise(ArgumentError,
              "Unknown rosterable type: #{rosterable.class.name}")
      end
    end
end
