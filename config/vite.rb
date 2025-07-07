# See https://henrikbjorn.medium.com/til-how-to-use-3rd-party-rubygem-assets-with-vite-ruby-rails-145b8b7d663c
# which references:
# https://github.com/ElMassimo/vite_ruby/discussions/159#discussioncomment-1992049

puts "Recompiling js-routes before starting Vite Dev Server" # rubocop:disable Rails/Output
require "rake"
require_relative "../config/application"
Rails.application.load_tasks
Rake::Task["js:routes"].invoke

ViteRuby.env["GEM_PATHS"] = Gem.loaded_specs.to_h do |name, gem|
  ["gems/#{name}", gem.full_gem_path]
end.to_json
