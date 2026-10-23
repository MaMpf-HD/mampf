class MampfsearchDeleteJob < ApplicationJob
  queue_as :default

  def perform(media_rails_id)
    SearchClient.instance.delete_media(media_rails_id)
  rescue SearchClient::MampfSearchError => e
    Rails.logger.warn("Failed to delete medium #{media_rails_id} from MampfSearch: #{e.message}")
  end
end
