# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

Rack::Mime::MIME_TYPES[".vtt"] = "text/vtt"
Rack::Mime::MIME_TYPES[".zip"] = "application/zip"
Rack::Mime::MIME_TYPES[".wasm"] = "application/wasm"
