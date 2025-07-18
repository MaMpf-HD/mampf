# See https://henrikbjorn.medium.com/til-how-to-use-3rd-party-rubygem-assets-with-vite-ruby-rails-145b8b7d663c
# which references:
# https://github.com/ElMassimo/vite_ruby/discussions/159#discussioncomment-1992049

ViteRuby.env["GEM_PATHS"] = Gem.loaded_specs.to_h do |name, gem|
  ["gems/#{name}", gem.full_gem_path]
end.to_json
