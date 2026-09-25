# Lets students pick their study program. Mathematics gets a key because the
# question to two-subject students needs it, and subject names are translations.
class AddStudyPrograms < ActiveRecord::Migration[8.0]
  DEGREES = ["bsc100", "bsc50", "msc", "med", "med_extension", "phd"].freeze

  # Columns: subject, degree, old German name, new German name, English name.
  # Match by subject and German name because ids differ between environments.
  PROGRAMS = [
    ["Mathematik", "bsc100", "BSc 100%", "B.Sc. 100%", "B.Sc. 100%"],
    ["Mathematik", "bsc50", "BSc 50%", "B.Sc. 50%", "B.Sc. 50%"],
    ["Mathematik", "msc", "MSc", "M.Sc.", "M.Sc."],
    ["Mathematik", "msc", nil, "M.Sc. Mathematics of Machine Learning and Data Science",
     "M.Sc. Mathematics of Machine Learning and Data Science"],
    ["Mathematik", "med", "MEd", "M.Ed.", "M.Ed."],
    ["Mathematik", "med_extension", nil, "M.Ed. Erweiterungsfach", "M.Ed. extension subject"],
    ["Mathematik", "phd", nil, "Promotion", "Doctorate"],
    ["Informatik", "bsc100", "BSc 100%", "B.Sc. 100%", "B.Sc. 100%"],
    ["Informatik", "bsc50", nil, "B.Sc. 50%", "B.Sc. 50%"],
    ["Informatik", "msc", "MSc", "M.Sc. Data and Computer Science",
     "M.Sc. Data and Computer Science"],
    ["Informatik", "med", nil, "M.Ed.", "M.Ed."],
    ["Informatik", "med_extension", nil, "M.Ed. Erweiterungsfach", "M.Ed. extension subject"],
    ["Informatik", "phd", nil, "Promotion", "Doctorate"],
    ["Physik", "bsc100", "BSc 100%", "B.Sc. 100%", "B.Sc. 100%"],
    ["Physik", "bsc50", nil, "B.Sc. 50%", "B.Sc. 50%"],
    ["Physik", "msc", "MSc", "M.Sc.", "M.Sc."],
    ["Physik", "med", nil, "M.Ed.", "M.Ed."],
    ["Scientific Computing", "msc", "MSc", "M.Sc.", "M.Sc."]
  ].freeze

  class Subject < ActiveRecord::Base
    self.table_name = "subjects"
  end

  class SubjectTranslation < ActiveRecord::Base
    self.table_name = "subject_translations"
  end

  class Program < ActiveRecord::Base
    self.table_name = "programs"
  end

  class ProgramTranslation < ActiveRecord::Base
    self.table_name = "program_translations"
  end

  class Division < ActiveRecord::Base
    self.table_name = "divisions"
  end

  def up
    add_column :programs, :degree, :string
    add_check_constraint :programs, "degree IN (#{DEGREES.map { |d| "'#{d}'" }.join(", ")})",
                         name: "programs_degree_check"
    add_column :subjects, :key, :string
    add_index :subjects, :key, unique: true
    add_reference :users, :program, foreign_key: { on_delete: :nullify }
    Program.reset_column_information
    Subject.reset_column_information

    math = subject_id("Mathematik")
    Subject.find(math).update!(key: "math") if math
    PROGRAMS.each { |row| classify(*row) }
  end

  def down
    PROGRAMS.reverse_each { |row| unclassify(*row) }
    remove_reference :users, :program, foreign_key: true
    remove_index :subjects, :key
    remove_column :subjects, :key
    remove_check_constraint :programs, name: "programs_degree_check"
    remove_column :programs, :degree
  end

  private

    def classify(subject_name, degree, before, name_de, name_en)
      subject = subject_id(subject_name)
      return say("No subject #{subject_name}: #{name_de} left out") unless subject

      program = (before && program_named(subject, before)) || program_named(subject, name_de)
      program ||= Program.create!(subject_id: subject)
      program.update!(degree: degree)
      rename(program, "de", name_de)
      rename(program, "en", name_en)
    end

    def unclassify(subject_name, _degree, before, name_de, _name_en)
      subject = subject_id(subject_name)
      program = subject && program_named(subject, name_de)
      return unless program

      if before
        rename(program, "de", before)
        rename(program, "en", before)
      elsif Division.exists?(program_id: program.id)
        say("#{subject_name} #{name_de} has divisions now and stays")
      else
        ProgramTranslation.where(program_id: program.id).delete_all
        program.delete
      end
    end

    def subject_id(name)
      SubjectTranslation.find_by(locale: "de", name: name)&.subject_id
    end

    def program_named(subject, name)
      ids = ProgramTranslation.where(locale: "de", name: name).select(:program_id)
      Program.find_by(subject_id: subject, id: ids)
    end

    def rename(program, locale, text)
      ProgramTranslation.find_or_initialize_by(program_id: program.id, locale: locale)
                        .update!(name: text)
    end
end
