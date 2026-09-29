module RecordsOffice
  # Builds the records office's downloads for German Excel: semicolons between
  # the fields and a byte order mark, without which Excel reads the file as
  # Windows-1252 and garbles every umlaut.
  module Export
    BOM = "\uFEFF".freeze
    PERSON_COLUMNS = [:last_name, :first_name, :matriculation_number, :email].freeze

    # Lists the members of one group, for the course evaluation's mailing.
    def self.emails(group)
      members = group.is_a?(Exam) ? group.users : group.members
      generate(members.sort_by { |user| sort_key(user) }.map { |user| person(user) })
    end

    def self.generate(rows)
      BOM + SafeCsv.generate(col_sep: ";") do |csv|
        csv << PERSON_COLUMNS.map { |column| I18n.t("records_office.columns.#{column}") }
        rows.each { |row| csv << row }
      end
    end
    private_class_method :generate

    def self.sort_key(user)
      [user.last_name.to_s.downcase, user.first_name.to_s.downcase, user.email]
    end
    private_class_method :sort_key

    def self.person(user)
      [user.last_name, user.first_name, user.matriculation_number, user.email]
    end
    private_class_method :person
  end
end
