class Consumption < ApplicationRecord
  connects_to database: { writing: :interactions, reading: :interactions }
end
