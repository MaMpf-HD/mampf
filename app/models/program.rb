class Program < ApplicationRecord
  belongs_to :subject
  has_many :divisions, dependent: :destroy
  extend Mobility
  extend I18nLocaleAccessors
  translates :name

  def name_with_subject
    "#{subject.name}: #{name}"
  end

  def courses
    divisions.map(&:courses).flatten
  end

  # array of all programs together with their ids for use in options_for_select
  def self.select_programs
    Program.includes(:subject).all.sort_by(&:name_with_subject)
           .map { |p| [p.name_with_subject, p.id] }
  end
end
