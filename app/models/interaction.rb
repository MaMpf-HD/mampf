class Interaction < ApplicationRecord
  connects_to database: { writing: :interactions, reading: :interactions }
  scope :created_between, lambda {|start_date, end_date| where("created_at >= ? AND created_at <= ?", start_date, end_date )}
  require 'csv'

  def self.to_csv
    attributes = %w{id session_id created_at full_path referrer_url study_participant}

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |interaction|
        csv << attributes.map{ |attr| interaction.send(attr) }
      end
    end
  end
end