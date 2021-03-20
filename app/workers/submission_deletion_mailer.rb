class SubmissionDeletionMailer
  include Sidekiq::Worker

  def perform
    #date = Date.today
    date = Date.new(2020,10,8)
    result = sanity_check(date)
    return unless result[:advance]
    if result[:reminder]
      result[:previous_term].update(submission_deletion_reminder: Time.now)
    else
      result[:previous_term].update(submission_deletion_mail: Time.now)
    end
    send_mail_to_submitters(result[:previous_term], result[:reminder])
    send_mail_to_editors(result[:previous_term], result[:reminder])
  end

  private

    def send_mail_to_submitters(term, reminder)
      submitters = term.submitters
      return unless submitters.present?

      I18n.available_locales.each do |l|
        local_submitter_ids = submitters.where(locale: l).pluck(:id)
        next if local_submitter_ids.empty?
        NotificationMailer.with(recipients: local_submitter_ids,
                                term: term,
                                deletion_date:
                                  term.submission_deletion_date,
                                reminder: reminder,
                                locale: l)
                          .submission_deletion_email.deliver_now
      end
    end

    def send_mail_to_editors(term, reminder)
      lectures = term.lectures_with_submissions
      lectures.each do |l|
        editor_ids = l.editors.pluck(:id) + [l.teacher.id]
        NotificationMailer.with(recipients: editor_ids,
                                term: term,
                                lecture: l,
                                deletion_date:
                                  term.submission_deletion_date,
                                reminder: reminder,
                                locale: l.locale)
                          .submission_deletion_lecture_email.deliver_now
      end
    end

    def sanity_check(date)
      term = Term.by_date(date)
      previous_term = term&.previous
      return { advance: false } unless previous_term

      unless date.in?([term.begin_date, term.begin_date + 7.days])
        return { advance: false }
      end

      if date == term.begin_date
        { advance: previous_term.submission_deletion_mail.nil?,
          reminder: false,
          previous_term: previous_term }
      else
        { advance: previous_term.submission_deletion_mail.present? &&
                     previous_term.submission_deletion_reminder.nil?,
          reminder: true,
          previous_term: previous_term }
      end
    end
end