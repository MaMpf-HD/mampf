module Roster
  class RosterNotificationMailer < ApplicationMailer
    # These methods should be triggered whenever a user is added/removed
    # into/from a rosterable object

    def added_to_group_email
      @rosterable = params[:rosterable]
      @rosterable_link = url_for(@rosterable)
      @username = @recipient.tutorial_name

      mail(from: @sender,
           to: @recipient.email,
           subject: t("mailer.roster_added_to_group_email_subject",
                      rosterable_title: @rosterable.title))
    end

    def url_for(rosterable)
      case rosterable
      when Lecture
        lecture_tutorial_overview_url(rosterable)
      when Tutorial # rubocop:disable Lint/DuplicateBranch
        # TODO: replace this with details page for tutorial when it exists
        lecture_tutorial_overview_url(rosterable.lecture)
      when Talk
        talk_url(rosterable)
      else
        raise(ArgumentError, "Unknown rosterable type: #{rosterable.class.name}")
      end
    end
  end
end
