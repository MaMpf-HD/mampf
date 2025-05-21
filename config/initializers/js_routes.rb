# Provide a global `Routes` object with all the Rails routes available
# in JavaScript.
JsRoutes.setup do |config|
  config.module_type = nil
  config.namespace = "Routes" # global namespace
  config.file = "../../app/assets/javascripts/mampf_routes.js"
end
