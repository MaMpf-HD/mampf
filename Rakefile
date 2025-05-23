# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

Rails.application.load_tasks

# Before assets:precompile (in production), we need to run js:routes
# to generate the Javascript routes file. See the js-routes gem.
task "assets:precompile" => "js:routes"
