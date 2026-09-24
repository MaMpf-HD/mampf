# Builds what the lecture home page shows besides the registrations: the
# links into the lecture's material and the counts on the staff block.
module LectureHomeHelper
  Path = Struct.new(:title, :subtitle, :url, :icon, keyword_init: true)

  # Lists the material a student starts from, each with a subtitle only when
  # the lecture has data for it.
  def lecture_home_paths(lecture, tutor:, staff:)
    paths = []
    if lecture.exercise?(current_user)
      paths << Path.new(title: t("categories.exercise.plural"),
                        subtitle: lecture_home_next_deadline(lecture),
                        url: lecture_exercises_path(lecture), icon: "bi bi-pencil")
    end
    if lecture.script?(current_user)
      paths << Path.new(title: t("categories.script.singular"),
                        subtitle: lecture_home_script_edited(lecture),
                        url: lecture_script_path(lecture), icon: "bi bi-file-earmark")
    end
    if tutor
      paths << Path.new(title: t("categories.tutorials"),
                        url: lecture_tutorials_path(lecture), icon: "bi bi-people")
    elsif !staff && lecture.assignments.exists?
      paths << Path.new(title: t("categories.submissions"),
                        url: lecture_submissions_path(lecture), icon: "bi bi-people")
    end
    paths
  end

  # Counts the people a campaign has in its current state: those holding a
  # place in a first come, first served campaign, those who handed in
  # preferences in a preference-based one.
  def lecture_home_campaign_count_text(campaign)
    users = campaign.user_registrations.reject(&:rejected?).map(&:user_id).uniq.size
    if campaign.first_come_first_served?
      t("lecture_home.teacher.registered", count: users)
    else
      t("lecture_home.teacher.with_preferences", count: users)
    end
  end

  def lecture_home_closed_status(campaign)
    if campaign.completed?
      t("lecture_home.closed.completed")
    else
      t("lecture_home.closed.not_finalized")
    end
  end

  private

    def lecture_home_next_deadline(lecture)
      assignment = lecture.current_assignments.min_by(&:deadline)
      return unless assignment

      t("lecture_home.paths.next_deadline", title: assignment.title,
                                            deadline: format_date(assignment.deadline))
    end

    def lecture_home_script_edited(lecture)
      edited = lecture.manuscript&.file_last_edited
      return unless edited

      t("lecture_home.paths.script_edited", date: l(edited.to_date, format: :long))
    end
end
