class RosterNotificationMailer < ApplicationMailer
  # Triggered whenever a user is added to a rosterable object
  def added_to_group_email
    @rosterable      = params[:rosterable]
    @recipient       = params[:recipient]
    @sender          = params[:sender]
    @rosterable_link = url_for_rosterable(@rosterable)
    @username        = @recipient.name

    mail(
      from: @sender,
      to: @recipient.email,
      subject: t(
        "mailer.roster_added_to_group_email_subject",
        rosterable_title: @rosterable.title,
        campaignable_title: @rosterable.try(:campaignable)&.title
      )
    )
  end

  private

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
