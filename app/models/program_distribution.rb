# Counts people by study program, for a lecture's teachers and the dean's
# office. Somebody without a program has either picked none of the listed ones
# or not answered yet; the two stay apart, since only the first says the person
# studies something else.
class ProgramDistribution
  Row = Struct.new(:key, :program, :people, keyword_init: true)
  SubjectRow = Struct.new(:subject, :people, :rows, keyword_init: true)

  # users: a relation, so the counting happens in the database. The keywords
  # carry counts read beforehand; see from_pairs.
  def initialize(users = nil, counts: nil, other: nil, programs: nil)
    @users = users
    @counts = counts
    @other = other
    @programs = programs
  end

  # Builds a distribution from [program_id, answered] pairs read beforehand,
  # for a page that counts many sets of people at once. programs: the
  # programs by id, with their subjects loaded.
  def self.from_pairs(pairs, programs:)
    new(counts: pairs.map(&:first).tally,
        other: pairs.count { |program_id, answered| program_id.nil? && answered },
        programs: programs)
  end

  def total
    counts.values.sum
  end

  # Programs by size, then those without one: :other before :unanswered.
  def rows
    @rows ||= program_rows + rows_without_program
  end

  # Groups the programs by subject, largest first, for whoever plans by
  # faculty rather than by program.
  def subjects
    subject_rows = program_rows.group_by { |row| row.program.subject }.map do |subject, rows|
      SubjectRow.new(subject: subject, people: rows.sum(&:people), rows: rows)
    end
    subject_rows.sort_by { |row| [-row.people, row.subject.name.to_s] }
  end

  def rows_without_program
    without = counts.fetch(nil, 0)
    return [] if without.zero?

    [Row.new(key: :other, people: other), Row.new(key: :unanswered, people: without - other)]
      .select { |row| row.people.positive? }
  end

  private

    def counts
      @counts ||= @users.group(:program_id).count
    end

    def other
      @other ||= @users.where(program_id: nil).where.not(personal_data_confirmed_at: nil).count
    end

    def program_rows
      @program_rows ||= begin
        rows = programs.map do |program|
          Row.new(key: program.id, program: program, people: counts[program.id])
        end
        rows.sort_by { |row| [-row.people, row.program.name_with_subject] }
      end
    end

    def programs
      ids = counts.keys.compact
      return @programs.values_at(*ids).compact if @programs

      Program.includes(:translations, subject: :translations).where(id: ids)
    end
end
