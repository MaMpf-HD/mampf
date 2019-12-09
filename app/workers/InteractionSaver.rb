class InteractionSaver
  include Sidekiq::Worker

  def perform(session_id, full_path, controller_name, action_name, referrer)
    Interaction.create(session_id: Digest::SHA2.hexdigest(session_id),
                       full_path: full_path,
                       controller_name: controller_name,
                       action_name: action_name,
                       referrer_url: referrer)
  end
end