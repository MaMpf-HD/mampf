# https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :password_strength_validation_enabled
end
