class Subject < ApplicationRecord
  has_many :programs
  extend Mobility
  translates :name

  def deletable?
    programs.none?
  end
end
