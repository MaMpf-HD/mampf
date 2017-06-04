class DisabledContent < ApplicationRecord
  belongs_to :lecture
  belongs_to :tag
end
