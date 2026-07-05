module Assessment
  # delegates to PointEntryService for actual point recording
  # triggers Participation.recompute_points_total! after point entry (via PointEntryService)
  # validates that the task belongs to the submission's assessment (via PointEntryService)
  # Only allows scoring if the assignment is inactive (after deadline)

  class SubmissionGraderService
    class SubmissionGraderError < StandardError; end

    def self.score_multi_teams_by_types!(records, scorer)
      validated_tutorials_ids = []
      validated_lecture_ids = []
      ActiveRecord::Base.transaction do
        records.each do |entry|
          SubmissionGraderService.score_tasks_by_types!(entry, scorer,
                                                        validated_tutorials_ids,
                                                        validated_lecture_ids)
        end
      end
    end

    # Routes a bulk entry to the correct scoring method based on target type.
    def self.score_tasks_by_types!(entry, scorer, validated_tutorials_ids, validated_lecture_ids)
      case entry["target"]
      when "submission"
        submission = Submission.find(entry["id"])
        tutorial_id = submission.tutorial_id
        if tutorial_id.present? && validated_tutorials_ids.exclude?(tutorial_id)
          tutorial = Tutorial.find(tutorial_id)
          raise_if_errors!([validate_current_user_can_grade_tutorial(tutorial, scorer)])
          validated_tutorials_ids << tutorial_id
        end
        score_tasks_by_submission!(submission, entry["task_points"], scorer)

      when "participation"
        participation = Assessment::Participation.find(entry["id"])
        tutorial_id = participation.tutorial_id

        if tutorial_id.present? && validated_tutorials_ids.exclude?(tutorial_id)
          tutorial = Tutorial.find(tutorial_id)
          raise_if_errors!([validate_current_user_can_grade(tutorial, scorer)])
          validated_tutorials_ids << tutorial_id
        elsif tutorial_id.nil?
          lecture_id = participation.assessment&.assessable&.lecture_id

          if lecture_id.present? && validated_lecture_ids.exclude?(lecture_id)
            lecture = Lecture.find(lecture_id)
            raise_if_errors!([validate_current_user_can_grade(lecture, scorer)])
            validated_lecture_ids << lecture_id if lecture_id.present?
          end
        end
        score_tasks_by_participation!(participation, entry["task_points"], scorer)
      else
        raise(SubmissionGraderError, "Unknown target type #{entry["target"].inspect}")
      end
    end

    # Enters points of all tasks for all team members of a submission
    # points_by_task_id, Hash of task_id => points, points potentially nil and string
    def self.score_tasks_by_submission!(submission, points_by_task_id, scorer)
      raise_if_errors!([validate_submission_present(submission)])

      assignment = submission.assignment
      assessment = assignment&.assessment

      raise_if_errors!([
                         validate_submission_has_assignment(submission, assignment),
                         validate_assignment_has_assessment(assignment, assessment)
                       ])
      raise_if_errors!([
                         validate_assessment_requires_points(assessment),
                         validate_assignment_inactive(assignment)
                       ])

      handle_score_tasks_by_submission(assessment, submission, points_by_task_id, scorer)
    end

    def self.score_tasks_by_participation!(participation, points_by_task_id, scorer)
      raise_if_errors!([validate_participation_present(participation)])

      assignment = participation.assessment&.assessable

      raise_if_errors!([
                         validate_participation_has_assignment(participation, assignment),
                         validate_assignment_inactive(assignment)
                       ])

      handle_score_tasks_by_participation(participation, points_by_task_id, scorer)
    end

    def self.init_participation(assessment, user, tutorial)
      if assessment.nil? || user.nil? || tutorial.nil?
        raise(SubmissionGraderError, "Assessment, user, and tutorial must be present")
      end

      participation = Participation.find_or_initialize_by(
        assessment_id: assessment.id,
        user_id: user.id
      )
      if participation.new_record?
        participation.update!(tutorial_id: tutorial.id) if tutorial.present?
        participation.save!
      end
      participation
    end

    # methods call to PointEntryService
    def self.handle_score_tasks_by_participation(participation,
                                                 points_by_task_id,
                                                 scorer)
      PointEntryService.enter_points(
        participation,
        points_by_task_id,
        scorer,
        nil
      )
    end

    def self.handle_score_tasks_by_submission(assessment, submission, points_by_task_id, scorer)
      users = submission.users
      users.each do |user|
        participation = init_participation(assessment, user, submission.tutorial)
        PointEntryService.enter_points(
          participation,
          points_by_task_id,
          scorer,
          submission
        )
      end
    end

    # validation methods: each returns nil (valid) or an error string (invalid) ---

    def self.validate_submission_has_assignment(submission, assignment)
      return if assignment.present?

      I18n.t("assessment.task_points.submission_has_no_assignment",
             submission_id: submission.id)
    end

    def self.validate_assignment_has_assessment(assignment, assessment)
      return if assessment.present?

      I18n.t("assessment.task_points.assignment_has_no_assessment",
             assignment_id: assignment.id)
    end

    def self.validate_participation_has_assignment(participation, assignment)
      return if assignment.present?

      I18n.t("assessment.task_points.participation_has_no_assignment",
             participation_id: participation.id)
    end

    def self.validate_assignment_inactive(assignment)
      return if assignment.nil? || !assignment.active?

      I18n.t("assessment.task_points.cannot_score_active_assignment")
    end

    def self.validate_assessment_requires_points(assessment)
      return if assessment.nil? || assessment.requires_points?

      I18n.t("assessment.task_points.not_required_points")
    end

    def self.validate_submission_present(submission)
      return if submission.present?

      I18n.t("assessment.task_points.submission_missing")
    end

    def self.validate_participation_present(participation)
      return if participation.present?

      I18n.t("assessment.task_points.participation_missing")
    end

    def self.validate_current_user_can_grade(something, user)
      return if something.nil? || user.can_grade_in_scope?(something)

      "User cannot grade"
    end

    #  error-raising helper ---

    def self.raise_if_errors!(errors)
      errors = errors.compact
      raise(SubmissionGraderError, errors.join("; ")) if errors.any?
    end

    private_class_method(:raise_if_errors!,
                         :validate_submission_has_assignment,
                         :validate_assignment_has_assessment,
                         :validate_participation_has_assignment,
                         :validate_assignment_inactive,
                         :validate_assessment_requires_points,
                         :validate_submission_present,
                         :validate_participation_present,
                         :validate_current_user_can_grade,
                         :handle_score_tasks_by_submission,
                         :handle_score_tasks_by_participation)
  end
end
