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
    @previous_term = Term.previous_by_date(@date)
    return unless @previous_term

    check_for_first_mail
    check_for_reminder_mail
    check_for_deletion
  end

  def check_for_first_mail
    @deletion_date = Time.zone.today + 14.days
    fetch_props
    @reminder = false

    send_info_mail_to_submitters
    send_info_mail_to_editors
  end

  def check_for_reminder_mail
    @deletion_date = Time.zone.today + 7.days
    fetch_props
    @reminder = true

    send_info_mail_to_submitters
    send_info_mail_to_editors
  end

  def check_for_deletion
    @deletion_date = Time.zone.today
    fetch_props

    @submissions = Submission.where(assignment: @assignments)
    @submissions.each(&:destroy)

    send_destruction_mail_to_submitters
    send_destruction_mail_to_editors
  end

  private

  def fetch_props
    @assignments = Assignments.where(deletion_date: @deletion_date)
    @submitters = @assignments.submitters
    @lectures = Lecture.find_by(id: @assignments.pluck(:lecture_id))
  end

  def send_destruction_mail_to_submitters
    return unless @submitters.present?

    I18n.available_locales.each do |l|
      local_submitter_ids = @submitters.where(locale: l).pluck(:id)
      next if local_submitter_ids.empty?

      local_submitter_ids.in_groups_of(200, false) do |group|
        NotificationMailer.with(recipients: group,
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
    return if @submitters.blank?

    I18n.available_locales.each do |l|
      local_submitter_ids = @submitters.where(locale: l).pluck(:id)
      next if local_submitter_ids.empty?

      local_submitter_ids.in_groups_of(200, false) do |group|
        NotificationMailer.with(recipients: group,
                                term: @previous_term,
                                deletion_date: @deletion_date,
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
                              deletion_date: @deletion_date,
                              reminder: @reminder,
                              locale: l.locale)
                        .submission_deletion_lecture_email.deliver_now
    end
  end
end
