# Users Helper
module UsersHelper
  def users_for_select(users)
    users.map { |u| [u.info, u.id] }
  end

  def confirm_user_deletion_text(user)
    return I18n.t('confirmation.generic') unless user.submissions.any?
    submission_count = user.submissions.proper.size
    single_submission_count = user.submissions.proper
                                  .select { |s| s.users.size == 1}.size
    t('confirmation.delete_account_with_submissions',
      submissions: submission_count,
      single_submissions: single_submission_count)
  end
end
