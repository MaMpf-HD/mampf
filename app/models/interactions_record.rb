class InteractionsRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :interactions, reading: :interactions }
end