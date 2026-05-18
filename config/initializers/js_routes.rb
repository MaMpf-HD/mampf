# Provide a global `Routes` object with all the Rails routes available
# in JavaScript.
JsRoutes.setup do |config|
  config.module_type = nil
  config.namespace = "Routes" # global namespace
  config.file = Rails.root.join("app/frontend/js/mampf_routes.js")
end
