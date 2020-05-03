class VttContainer < ApplicationRecord
  include VttUploader[:table_of_contents]
  include VttUploader[:references]
end
