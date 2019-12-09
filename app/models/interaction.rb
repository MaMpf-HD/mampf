class Interaction < ApplicationRecord
  connects_to database: { writing: :interactions, reading: :interactions }

end