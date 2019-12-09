class Interaction < ApplicationRecord
  connects_to database: { writing: :interactions, reading: :interactions }
  require 'csv'

  def self.to_csv
    attributes = %w{id session_id created_at full_path referrer_url}

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |interaction|
        csv << attributes.map{ |attr| interaction.send(attr) }
      end
    end
  end
end