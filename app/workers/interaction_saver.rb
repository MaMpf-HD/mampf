class InteractionSaver
  include Sidekiq::Worker

  def perform(session_id, full_path, referrer, study_participant)
    referrer_url = if referrer.to_s.include?(ENV['URL_HOST'])
                     referrer.to_s.remove(ENV['URL_HOST'])
                                  .remove('https://').remove('http://')
                   end
    Interaction.create(session_id: Digest::SHA2.hexdigest(session_id).first(10),
                       full_path: full_path,
                       referrer_url: referrer_url,
                       study_participant: study_participant)
  end
end