# Renders a list of groups (tutorials, exams, etc.) for a lecture.
# Can be filtered by group_type (:tutorials, :exams, :all).
class RosterOverviewComponent < ViewComponent::Base
  def initialize(lecture:, group_type: :all)
    super()
    @lecture = lecture
    @group_type = group_type
  end

  attr_reader :lecture

  # Returns a list of groups to display based on the selected type.
  # Structure: { title: String, items: ActiveRecord::Relation, type: Symbol }
  def groups
    @groups ||= case @group_type
                when :tutorials
                  [tutorial_group]
                when :talks
                  [talk_group]
                when :exams
                  # [exam_group] # Future implementation
                  []
                else
                  # :all or default
                  [
                    tutorial_group,
                    talk_group
                    # Future: exam_group
                  ]
    end.compact
  end

  def total_participants
    groups.sum do |group|
      group[:items].sum { |item| item.roster_entries.count }
    end
  end

  def total_capacity
    sum = 0
    groups.each do |group|
      group[:items].each do |item|
        return nil if item.capacity.nil?

        sum += item.capacity
      end
    end
    sum
  end

  def unassigned_count
    klass_name = case @group_type
                 when :tutorials then "Tutorial"
                 when :talks then "Talk"
                 else return 0
    end

    campaigns = Registration::Campaign.where(campaignable: @lecture)
                                      .joins(:registration_items)
                                      .where(registration_items: { registerable_type: klass_name })
                                      .distinct

    campaigns.flat_map { |c| c.unassigned_users.pluck(:id) }.uniq.count
  end

  def group_type_title
    case @group_type
    when :tutorials
      I18n.t("roster.tabs.tutorial_maintenance")
    when :talks
      I18n.t("roster.tabs.talk_maintenance")
    else
      I18n.t("roster.dashboard.title")
    end
  end

  # Helper to generate the correct polymorphic path
  def group_path(item)
    case item
    when Tutorial
      helpers.tutorial_roster_path(item)
    when Talk
      helpers.talk_roster_path(item)
    else
      "#"
    end
  end

  def active_campaign_for(item)
    Registration::Campaign
      .joins(:registration_items)
      .where(registration_items: { registerable_id: item.id, registerable_type: item.class.name })
      .where.not(status: :completed)
      .first
  end

  private

    def tutorial_group
      items = @lecture.tutorials.includes(:tutors).order(:title)
      return nil if items.empty?

      {
        title: Tutorial.model_name.human(count: 2),
        items: items,
        type: :tutorials
      }
    end

    def talk_group
      items = @lecture.talks.includes(:speakers).order(:title)
      return nil if items.empty?

      {
        title: Talk.model_name.human(count: 2),
        items: items,
        type: :talks
      }
    end
end
