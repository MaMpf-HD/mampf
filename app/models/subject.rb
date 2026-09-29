class Subject < ApplicationRecord
  MATH = "math".freeze

  has_many :programs
  extend Mobility
  extend I18nLocaleAccessors

  translates :name

  def math?
    key == MATH
  end

  def deletable?
    programs.none?
  end
end
