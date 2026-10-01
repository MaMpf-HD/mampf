# Shows how many people study which program, one column per set of people:
# a group's members in the roster panel, a lecture's enrolled and all its
# people in the Participants tab.
class ProgramDistributionComponent < ViewComponent::Base
  # columns: column heading => ProgramDistribution
  def initialize(columns:, help: nil)
    super()
    @columns = columns
    @help = help
  end

  attr_reader :columns, :help

  def render?
    @columns.values.any? { |distribution| distribution.total.positive? }
  end

  # Orders programs by their largest count in any column and keeps :other and
  # :unanswered last, as each column does on its own.
  def keys
    with_program, without = all_rows.partition(&:program)
    programs = with_program.group_by(&:key).sort_by do |_, rows|
      [-rows.map(&:people).max, rows.first.program.name_with_subject]
    end
    present = without.map(&:key)
    programs.map(&:first) + [:other, :unanswered].select { |key| key.in?(present) }
  end

  def label(key)
    case key
    when :other, :unanswered then t("roster.programs.#{key}")
    else program(key).name_with_subject
    end
  end

  def people(distribution, key)
    distribution.rows.find { |row| row.key == key }&.people || 0
  end

  private

    def all_rows
      @all_rows ||= @columns.values.flat_map(&:rows)
    end

    def program(key)
      all_rows.find { |row| row.key == key }.program
    end
end
