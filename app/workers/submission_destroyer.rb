class SubmissionDestroyer
  include Sidekiq::Worker

  def perform
    date = Date.today
    # date = Date.new(2020,10,15)
    result = sanity_check(date)
    return unless result[:advance]
    result[:previous_term].update(submissions_deleted_at: Time.now)
    # result[:submissions].each(&:destroy)
    send_mail_to_submitters(result[:previous_term], result[:submitters])
    send_mail_to_editors(result[:previous_term], result[:lectures])
  end

  private

    def send_mail_to_submitters(term, submitters)
      return unless submitters.present?

      I18n.available_locales.each do |l|
        local_submitter_ids = submitters.where(locale: l).pluck(:id)
        next if local_submitter_ids.empty?
        NotificationMailer.with(recipients: local_submitter_ids,
                                term: term,
                                locale: l)
                          .submission_destruction_email.deliver_now
      end
    end

    def send_mail_to_editors(term, lectures)
      lectures.each do |l|
        editor_ids = l.editors.pluck(:id) + [l.teacher.id]
        NotificationMailer.with(recipients: editor_ids,
                                term: term,
                                lecture: l,
                                locale: l.locale)
                          .submission_destruction_lecture_email.deliver_now
      end
    end

    def sanity_check(date)
      previous_term = Term.by_date(date)&.previous
      return { advance: false } unless previous_term

      return { advance: false } unless date == previous_term.end_date + 15.days

      return { advance: false } unless previous_term.submission_deletion_mail.present?

      return { advance: false } unless previous_term.submission_deletion_reminder.present?

      return { advance: false } if previous_term.submissions_deleted_at.present?

      { advance: true,
        previous_term: previous_term,
        submissions: previous_term.submissions,
        submitters: previous_term.submitters,
        lectures: previous_term.lectures_with_submissions }
    end
end