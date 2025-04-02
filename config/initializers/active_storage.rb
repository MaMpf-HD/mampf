# TODO: (Dominic): Describe why we need this (!)
Rails.application.config.to_prepare do
  ActiveStorage::BaseController.class_eval do
    # Override send_file specifically for ActiveStorage controllers
    def send_file(path, options = {})
      # Clone options to avoid modifying the original
      local_options = options.dup

      # Store the current X-Accel-Redirect setting
      original_header = Rails.application.config.action_dispatch.x_sendfile_header

      # Temporarily disable X-Accel-Redirect for ActiveStorage
      Rails.application.config.action_dispatch.x_sendfile_header = nil

      # Call the original send_file method from ActionController::DataStreaming
      result = super(path, local_options)

      # Restore the original setting
      Rails.application.config.action_dispatch.x_sendfile_header = original_header

      result
    end
  end
end
