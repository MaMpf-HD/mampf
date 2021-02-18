puts 'ApplicationRecord is being loaded'
puts caller_locations.select { |line| line.to_s =~ /#{Rails.root.to_s}\/config\/initializers/ }

# ApplicationRecord
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
