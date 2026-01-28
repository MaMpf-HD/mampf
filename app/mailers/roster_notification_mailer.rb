class RosterNotificationMailer < ApplicationMailer
  # Triggered whenever a user is added to / removed from / moved between group(s)
  # of a rosterable object

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

  private

    def prepare_data
      @rosterable      = params[:rosterable]
      @old_rosterable  = params[:old_rosterable]
      @new_rosterable  = params[:new_rosterable]
      @recipient       = params[:recipient]
      @sender          = params[:sender]
      @rosterable_link = url_for_rosterable(@rosterable || @new_rosterable)
      @username        = @recipient.name
    end

    def email(mail_template)
      prepare_data(params)
      mail(
        from: @sender,
        to: @recipient.email,
        subject: t(
          "mailer.roster_#{mail_template}_subject",
          rosterable_title: @rosterable.title,
          campaignable_title: @rosterable.try(:campaignable)&.title
        )
      )
    end

    def url_for_rosterable(rosterable)
      case rosterable
      when Lecture
        lecture_tutorial_overview_url(rosterable)
      when Tutorial
        # TODO: replace with tutorial details page when it exists
        lecture_tutorial_overview_url(rosterable.lecture)
      when Talk
        talk_url(rosterable)
      else
        raise(ArgumentError,
              "Unknown rosterable type: #{rosterable.class.name}")
      end
    end
end
