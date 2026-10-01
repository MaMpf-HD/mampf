# Counts people by study program, for a lecture's teachers and the dean's
# office. Somebody without a program has either picked none of the listed ones
# or not answered yet; the two stay apart, since only the first says the person
# studies something else.
class ProgramDistribution
  Row = Struct.new(:key, :program, :people, keyword_init: true)

  # users: a relation, so the counting happens in the database.
  def initialize(users)
    @users = users
  end

  def total
    counts.values.sum
  end

  # Programs by size, then those without one: :other before :unanswered.
  def rows
    @rows ||= program_rows + rows_without_program
  end

  private

    def counts
      @counts ||= @users.group(:program_id).count
    end

    def program_rows
      programs = Program.includes(:translations, subject: :translations)
                        .where(id: counts.keys.compact)
      rows = programs.map do |program|
        Row.new(key: program.id, program: program, people: counts[program.id])
      end
      rows.sort_by { |row| [-row.people, row.program.name_with_subject] }
    end

    def rows_without_program
      without = counts.fetch(nil, 0)
      return [] if without.zero?

      other = @users.where(program_id: nil).where.not(personal_data_confirmed_at: nil).count
      [Row.new(key: :other, people: other), Row.new(key: :unanswered, people: without - other)]
        .select { |row| row.people.positive? }
    end
end
