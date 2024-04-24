class Subject < ApplicationRecord
  has_many :programs
  extend Mobility
  extend I18nLocaleAccessors
  translates :name

  def deletable?
    programs.none?
  end
end
