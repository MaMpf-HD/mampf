# frozen_string_literal: true

# PORO class that handles the cleaning of submissions of the previous term
# in order to fulfill GDPR regulations
class SubmissionCleaner
  attr_reader :date, :advance, :previous_term, :reminder, :destroy,
              :submissions, :submitters, :lectures

  def initialize(date:)
    @date = date
  end

  def clean!
    set_attributes
    return unless @advance

    warn_about_destruction and return unless @destroy

    destroy_and_inform
  end

  def set_attributes
    determine_actions
    fetch_previous_term_props if @advance
    true
  end

  private

  def determine_actions
    @advance = false
    @previous_term = Term.previous_by_date(@date)
    return unless @previous_term
    return unless @date.in?(previous_term.submission_deletion_info_dates)
    if date == @previous_term.end_date + 1.day
      @advance = @previous_term.submission_deletion_mail.nil?
      @reminder = false
    elsif date == @previous_term.end_date + 8.days
      @advance = @previous_term.submission_deletion_mail.present? &&
                   @previous_term.submission_deletion_reminder.nil?
      @reminder = true
    elsif date == @previous_term.submission_deletion_date
      @advance = @previous_term.submission_deletion_mail.present? &&
                   @previous_term.submission_deletion_reminder.present? &&
                   @previous_term.submissions_deleted_at.nil?
      @destroy = true
    end
  end

  def fetch_previous_term_props
    @submissions = @previous_term.submissions
    @submitters = @previous_term.submitters
    @lectures = @previous_term.lectures_with_submissions
  end

  def destroy_and_inform
    @previous_term.update(submissions_deleted_at: Time.now)
    @submissions.each(&:destroy)
    send_destruction_mail_to_submitters
    send_destruction_mail_to_editors
  end

  def warn_about_destruction
    if @reminder
      @previous_term.update(submission_deletion_reminder: Time.now)
    else
      @previous_term.update(submission_deletion_mail: Time.now)
    end

    send_info_mail_to_submitters
    send_info_mail_to_editors
    true
  end

  def send_destruction_mail_to_submitters
    return unless @submitters.present?

    I18n.available_locales.each do |l|
      local_submitter_ids = @submitters.where(locale: l).pluck(:id)
      next if local_submitter_ids.empty?

      local_submitter_ids.in_groups_of(200) do |group|
        NotificationMailer.with(recipients: group.compact,
                                term: @previous_term,
                                locale: l)
                          .submission_destruction_email.deliver_now
      end
    end
  end

  def send_destruction_mail_to_editors
    @lectures.each do |l|
      editor_ids = l.editors.pluck(:id) + [l.teacher.id]
      NotificationMailer.with(recipients: editor_ids,
                              term: @previous_term,
                              lecture: l,
                              locale: l.locale)
                        .submission_destruction_lecture_email.deliver_now
    end
  end

  def send_info_mail_to_submitters
    return unless @submitters.present?

    I18n.available_locales.each do |l|
      local_submitter_ids = @submitters.where(locale: l).pluck(:id)
      next if local_submitter_ids.empty?
        local_submitter_ids.in_groups_of(200) do |group|
          NotificationMailer.with(recipients: group.compact,
                                  term: @previous_term,
                                  deletion_date:
                                    @previous_term.submission_deletion_date,
                                  reminder: @reminder,
                                  locale: l)
                            .submission_deletion_email.deliver_now
        end
      end
    end

    def send_info_mail_to_editors
      @lectures.each do |l|
        editor_ids = l.editors.pluck(:id) + [l.teacher.id]
        NotificationMailer.with(recipients: editor_ids,
                                term: @previous_term,
                                lecture: l,
                                deletion_date:
                                  @previous_term.submission_deletion_date,
                                reminder: @reminder,
                                locale: l.locale)
                          .submission_deletion_lecture_email.deliver_now
      end
    end
end
