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
end
