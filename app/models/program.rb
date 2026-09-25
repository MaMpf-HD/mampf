class Program < ApplicationRecord
  # Students of these degrees study two subjects and are asked whether
  # mathematics is one of them.
  TWO_SUBJECT_DEGREES = ["bsc50", "med"].freeze

  belongs_to :subject
  has_many :divisions, dependent: :destroy

  # A program without a degree only classifies courses; students cannot pick it.
  enum :degree, { bsc100: "bsc100", bsc50: "bsc50", msc: "msc", med: "med",
                  med_extension: "med_extension", phd: "phd" },
       validate: { allow_nil: true }

  scope :offered_to_students, -> { where.not(degree: nil) }

  extend Mobility
  extend I18nLocaleAccessors

  translates :name

  def name_with_subject
    "#{subject.name}: #{name}"
  end

  def two_subjects?
    degree.in?(TWO_SUBJECT_DEGREES)
  end

  def courses
    divisions.map(&:courses).flatten
  end
end
