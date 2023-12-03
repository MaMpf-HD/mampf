# prevents upload issue https://github.com/rails/rails/issues/45238
# bad request when uploading multiple files

Rails.application.config.active_storage.multiple_file_field_include_hidden = false