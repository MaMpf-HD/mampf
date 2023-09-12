class HasSeenNewsPopup < ApplicationRecord
  belongs_to :user_id
  belongs_to :news_popup_id
end
