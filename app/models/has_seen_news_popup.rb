class HasSeenNewsPopup < ApplicationRecord
  belongs_to :user
  belongs_to :news_popup
end
