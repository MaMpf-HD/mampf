# PORO class that handles the cleaning of submissions
# in order to fulfill GDPR regulations
class SubmissionCleaner
  attr_reader :date, :advance, :reminder, :destroy,
              :submissions, :submitters, :lectures

  def initialize(date:)
    @date = date
  end

  def clean!
    check_for_first_mail
    check_for_reminder_mail
    check_for_deletion
  end

  def check_for_first_mail
    @deletion_date = @date + 14.days
    fetch_props
    return if @assignments.empty?

    @reminder = false
    send_info_mail_to_submitters
    send_info_mail_to_editors
  end

  def check_for_reminder_mail
    @deletion_date = @date + 7.days
    fetch_props
    return if @assignments.empty?

    @reminder = true
    send_info_mail_to_submitters
    send_info_mail_to_editors
  end

  def check_for_deletion
    @deletion_date = @date
    fetch_props
    return if @assignments.empty?

    @submissions = Submission.where(assignment: @assignments)
    @submissions.each(&:destroy!)

    send_destruction_mail_to_submitters
    send_destruction_mail_to_editors
  end

  private

    def clear_props
      @assignments = nil
      @submitters = nil
      @lectures = nil
    end

    def fetch_props
      clear_props
      @assignments = Assignment.where(deletion_date: @deletion_date)
      return if @assignments.empty?

      @submitters = User.where(id: @assignments.flat_map(&:submitter_ids))
      @lectures = Lecture.where(id: @assignments.pluck(:lecture_id))
    end

    def send_destruction_mail_to_submitters
      return if @submitters.blank?

      I18n.available_locales.each do |l|
        local_submitter_ids = @submitters.where(locale: l).pluck(:id)
        next if local_submitter_ids.empty?

        local_submitter_ids.in_groups_of(200, false) do |group|
          NotificationMailer.with(recipients: group,
                                  deletion_date: @deletion_date,
                                  locale: l)
                            .submission_destruction_email.deliver_now
        end
      end
    end

    def send_destruction_mail_to_editors
      @lectures.each do |l|
        editor_ids = l.editors.pluck(:id) + [l.teacher.id]
        NotificationMailer.with(recipients: editor_ids,
                                lecture: l,
                                deletion_date: @deletion_date,
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
                                  deletion_date: @deletion_date,
                                  reminder: @reminder,
                                  lectures: @lectures,
                                  locale: l)
                            .submission_deletion_email.deliver_now
        end
      end
    end

    def send_info_mail_to_editors
      @lectures.each do |l|
        editor_ids = l.editors.pluck(:id) + [l.teacher.id]
        NotificationMailer.with(recipients: editor_ids,
                                lecture: l,
                                deletion_date: @deletion_date,
                                reminder: @reminder,
                                locale: l.locale)
                          .submission_deletion_lecture_email.deliver_now
      end
    end
end
