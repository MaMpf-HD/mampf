class MediaPublisher
  include Sidekiq::Worker

  def perform
    media_ids = Medium.where.not(publisher: nil).pluck(:publisher)
                      .select { |p| p.release_date < DateTime.current }
                      .map(&:medium_id)
    Medium.where(id: media_ids).each(&:publish!)
  end
end
