# Renders marking-table filters with optional actions supplied as content.
class MarkingFilterComponent < ViewComponent::Base
  def initialize(id:, status_options: nil, tutorials: nil)
    super()
    @id = id
    @status_options = status_options
    @tutorials = tutorials.to_a
  end

  def status_filter?
    @status_options.present?
  end

  def tutorial_filter?
    tutorial_options.present?
  end

  # Names each tutorial with its tutors: a lecturer filtering the whole
  # lecture knows the tutors better than the titles.
  def tutorial_options
    return [] if @tutorials.empty?

    @tutorial_options ||= begin
      ActiveRecord::Associations::Preloader.new(records: @tutorials, associations: :tutors).call
      @tutorials.map { |tutorial| [tutorial.id.to_s, tutorial.title_with_tutors] } +
        [["none", I18n.t("assessment.grading_tutorial.no_tutorial_badge")]]
    end
  end
end
