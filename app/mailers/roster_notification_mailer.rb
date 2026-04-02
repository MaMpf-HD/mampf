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
        recipient: user,
        sender: DefaultSetting::PROJECT_EMAIL
      ).public_send(template).deliver_now
    end

    def removed(user, rosterable)
      template = rosterable.is_a?(Lecture) ? :removed_from_lecture_email : :removed_from_group_email

      with(
        rosterable: rosterable,
        recipient: user,
        sender: DefaultSetting::PROJECT_EMAIL
      ).public_send(template).deliver_now
    end

    def moved(user, old_rosterable, new_rosterable)
      with(
        old_rosterable: old_rosterable,
        new_rosterable: new_rosterable,
        recipient: user,
        sender: DefaultSetting::PROJECT_EMAIL
      ).moved_between_groups_email.deliver_now
    end
  end

  def added_to_group_email
    prepare_data(params)
    email("added_to_group")
  end

  def removed_from_group_email
    prepare_data(params)
    email("removed_from_group")
  end

  def moved_between_groups_email
    prepare_data(params)
    email("moved_between_groups")
  end

  def removed_from_lecture_email
    prepare_data(params)
    email("removed_from_lecture")
  end

  private

    def prepare_data(params)
      @rosterable      = params[:rosterable]
      @old_rosterable  = params[:old_rosterable]
      @new_rosterable  = params[:new_rosterable]
      @recipient       = params[:recipient]
      @sender          = params[:sender]
      @username        = @recipient.name
      @rosterable_link = url_for_rosterable(@rosterable || @new_rosterable)
      @lecture         = lecture_for_rosterable(@rosterable || @new_rosterable)
    end

    def email(mail_template)
      prepare_data(params)
      mail(
        from: @sender,
        to: @recipient.email,
        subject: t(
          "roster.mailer.roster_#{mail_template}_email_subject",
          rosterable_title: @rosterable&.title || @new_rosterable&.title,
          lecture_title: @lecture&.title || ""
        )
      )
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
      when Tutorial
        # TODO: replace with tutorial details page when it exists
        lecture_campaign_registrations_url(rosterable.lecture)
      when Talk
        talk_url(rosterable)
      when Cohort
        # TODO: replace with cohort details page when it exists
        lecture_campaign_registrations_url(rosterable.lecture)
      else
        raise(ArgumentError,
              "Unknown rosterable type: #{rosterable.class.name}")
      end
    end
end
