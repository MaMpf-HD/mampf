# TODO: This is the config for the deprecated Sprockets configuration.
# Once we update our asset pipeline, update the js-routes config here accordingly.
# https://github.com/railsware/js-routes/tree/main?tab=readme-ov-file#sprockets-deprecated
JsRoutes.setup do |config|
  config.module_type = nil
  config.namespace = "Routes"
end
