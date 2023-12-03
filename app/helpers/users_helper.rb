# Users Helper
module UsersHelper
  def users_for_select(users)
    users.map { |u| [u.info, u.id] }
  end

  def select_proper_teaching_related_lectures(user)
    user.proper_teaching_related_lectures
        .sort_by { |l| [l.begin_date.to_time.to_i * (-1), l.title] }
        .map { |l| [l.title, l.id] }
  end
end
