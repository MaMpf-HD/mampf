# Missing top-level docstring, please formulate one yourself 😁
class RosterOverviewComponent < ViewComponent::Base
  SUPPORTED_TYPES = {
    tutorials: { model: "Tutorial", association: :tutorial_memberships, includes: :tutors },
    talks: { model: "Talk", association: :speaker_talk_joins, includes: :speakers },
    cohorts: { model: "Cohort", association: :cohort_memberships, includes: [] }
  }.freeze

  # rubocop:disable Metrics/ParameterLists
  def initialize(lecture:, group_type: :all, roster_tab: :lanes, rosterable: nil,
                 participants: nil, pagy: nil, filter_mode: "all", counts: {})
    super()
    @lecture = lecture
    @group_type = group_type
    @roster_tab = roster_tab
    @rosterable = rosterable
    @participants = participants
    @pagy = pagy
    @filter_mode = filter_mode
    @counts = counts
  end
  # rubocop:enable Metrics/ParameterLists

  attr_reader :lecture, :roster_tab, :rosterable, :group_type, :participants, :pagy, :filter_mode,
              :counts

  def sections
    # Fetch all items across all requested types
    all_items = target_types.flat_map do |type|
      build_group_items(type)
    end.compact

    # Bucket 1: The official roster (propagate_to_lecture = true)
    on_roster = all_items.select do |item|
      !item.is_a?(Cohort) || item.propagate_to_lecture?
    end

    # Bucket 2: Sidecars / Waitlists (propagate_to_lecture = false)
    off_roster = all_items.select do |item|
      item.is_a?(Cohort) && !item.propagate_to_lecture?
    end

    result = []

    # 1. Main Roster Section
    if on_roster.any? || primary_type_enabled?
      result << {
        title: primary_section_title,
        items: sort_mixed_items(on_roster)
      }
    end

    # 2. Isolated Section
    if off_roster.any? || cohorts_enabled?
      result << {
        title: I18n.t("roster.cohorts.without_lecture_enrollment_title"),
        items: off_roster
      }
    end

    result
  end

  def all_groups_empty?
    @lecture.tutorials.empty? && @lecture.talks.empty? && @lecture.cohorts.empty?
  end

  private

    def build_group_items(type)
      items = @lecture.public_send(type)
      return [] if items.empty?

      items.sort_by do |item|
        if type == :talks
          item.position
        else
          has_completed_campaign = item.in_completed_campaign?
          [has_completed_campaign ? 0 : 1, item.title.to_s]
        end
      end
    end

    def sort_mixed_items(items)
      items.sort_by do |item|
        type_rank = item.is_a?(Cohort) ? 2 : 1
        [type_rank, item.title.to_s]
      end
    end

    def primary_type_enabled?
      target_types.intersect?([:tutorials, :talks])
    end

    def cohorts_enabled?
      target_types.include?(:cohorts)
    end

    def primary_section_title
      I18n.t("roster.cohorts.with_lecture_enrollment_title")
    end

    def target_types
      if @group_type == :all
        SUPPORTED_TYPES.keys
      elsif @group_type.is_a?(Array)
        @group_type.map(&:to_sym)
      else
        [@group_type.to_sym]
      end
    end
end
