class Interaction < InteractionsRecord
  scope :created_between, lambda { |start_date, end_date|
                            where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                          }
  require "csv"

  def self.to_csv
    attributes = ["id", "session_id", "created_at", "full_path", "referrer_url",
                  "study_participant"]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |interaction|
        csv << attributes.map { |attr| interaction.send(attr) }
      end
    end
  end
end
