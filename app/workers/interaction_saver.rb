class InteractionSaver
  include Sidekiq::Worker

  def perform(session_id, full_path, referrer, action_name, controller_name,
              signed_in)
    if signed_in
      Interaction.create(session_id: Digest::SHA2.hexdigest(session_id).first(10),
                         full_path: full_path,
                         referrer_url: referrer&.remove(ENV['URL_HOST'])
                                         &.remove('https://'))
    end
    return unless controller_name == 'media'
    return unless action_name.in?(['play', 'display', 'register_download'])
    if action_name.in?(['play', 'display'])
      path_hash = Rails.application.routes.recognize_path(full_path)
      Consumption.create(medium_id: path_hash[:id],
                         mode: action_name == 'play' ? 'thyme' : 'pdf_view',
                         sort: action_name == 'play' ? 'video' : 'manuscript')
      return
    end
    path_hash = Rails.application.routes.recognize_path(full_path,
                                                        method: :post)
    Consumption.create(medium_id: path_hash[:id],
                       mode: 'download',
                       sort: full_path.split('?sort=').last)
  end
end