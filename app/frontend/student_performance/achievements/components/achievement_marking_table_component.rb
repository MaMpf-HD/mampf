# An achievement's table: one row per person, with the value the tutor
# enters and whether it meets the achievement. A tutor sees their group, the lecturer
# every member, group by group; the rows are seeded as the table is drawn,
# the way a test's are.
class AchievementMarkingTableComponent < ViewComponent::Base
  STATUSES = [:met, :not_met, :unmarked, :exempt].freeze

  def initialize(achievement:, grading_scope:)
    super()
    @achievement = achievement
    @lecture = achievement.lecture
    @assessment = achievement.assessment
    @grading_scope = grading_scope
    @tutorial = grading_scope if grading_scope.is_a?(Tutorial)
  end

  attr_reader :achievement

  def rows
    @rows ||= members.filter_map { |user| participations[user.id] }
  end

  def row_for(participation)
    ParticipationRowComponent.new(participation: participation, assessment: @assessment,
                                  grading_scope: @grading_scope, table_option: :achievement,
                                  filter_tutorial_id: participation.tutorial_id)
  end

  def layout
    @layout ||= PointingTableLayout.for(assessable: achievement, grading_scope: @grading_scope)
  end

  def status_options
    STATUSES.map { |status| [status.to_s, I18n.t("assessment.achievements.marking.#{status}")] }
  end

  # The lecturer's table filters by group; a tutor's is one group already.
  def tutorial_options
    return [] if @tutorial || @lecture.tutorials.empty?

    @lecture.tutorials.order(:title).map { |tutorial| [tutorial.id.to_s, tutorial.title] } +
      [["none", I18n.t("assessment.grading_tutorial.no_tutorial_badge")]]
  end

  def summary
    PointingSummaryComponent.new(statuses: rows.map { |row| achievement.status_of(row) },
                                 hand_ins: false)
  end

  def filter_id
    "achievement-#{achievement.id}-#{@tutorial ? "tutorial-#{@tutorial.id}" : "lecture"}"
  end

  private

    # A group's members by the name the table shows; the lecture's members
    # group by group, those in no group last, as the sheet tables read.
    def members
      @members ||= if @tutorial
        @tutorial.members.to_a.sort_by { |user| user.tutorial_name.to_s.downcase }
      else
        @lecture.members.to_a.sort_by do |user|
          [groups[user.id] ? 0 : 1, groups[user.id]&.title.to_s, user.tutorial_name.to_s.downcase]
        end
      end
    end

    # One group per person and lecture, so a group's members are its own.
    def groups
      @groups ||= if @tutorial
        @tutorial.members.to_h { |user| [user.id, @tutorial] }
      else
        TutorialMembership.where(tutorial: @lecture.tutorials).includes(:tutorial)
                          .index_by(&:user_id).transform_values(&:tutorial)
      end
    end

    def participations
      @participations ||= Assessment::ParticipationIndex.rows_for(
        @assessment, members, members.to_h { |user| [user.id, groups[user.id]] }
      )
    end
end
