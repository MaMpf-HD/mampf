# Renders marking-table filters with optional actions supplied as content.
class MarkingFilterComponent < ViewComponent::Base
  # Names each group with its tutors: a lecturer with many groups knows the
  # people, not which group is whose.
  def self.tutorial_options(tutorials)
    tutorials = tutorials.to_a
    return [] if tutorials.empty?

    ActiveRecord::Associations::Preloader.new(records: tutorials, associations: :tutors).call
    tutorials.map { |tutorial| [tutorial.id.to_s, tutorial.title_with_tutors] } +
      [["none", I18n.t("assessment.grading_tutorial.no_tutorial_badge")]]
  end

  def initialize(id:, status_options: nil, tutorial_options: nil)
    super()
    @id = id
    @status_options = status_options
    @tutorial_options = tutorial_options
  end

  def status_filter?
    @status_options.present?
  end

  def tutorial_filter?
    @tutorial_options.present?
  end
end
