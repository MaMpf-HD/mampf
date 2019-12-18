class InteractionSaver
  include Sidekiq::Worker

  def perform(session_id, full_path, referrer)
    Interaction.create(session_id: Digest::SHA2.hexdigest(session_id).first(10),
                       full_path: full_path,
                       referrer_url: referrer&.remove(ENV['URL_HOST'])
                                       &.remove('https://'))
  end
end