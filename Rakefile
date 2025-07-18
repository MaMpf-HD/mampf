require_relative "config/application"

Rails.application.load_tasks

# Before assets:precompile (in production), we need to run js:routes
# to generate the Javascript routes file. See the js-routes gem.
task "assets:precompile" => "js:routes"
