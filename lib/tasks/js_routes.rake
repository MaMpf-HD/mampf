namespace :js do
  desc "Recompile js-routes for frontend JavaScript"
  task recompile_routes: :environment do
    puts "Recompiling MaMpf routes for JS (via js-routes)"
    Rake::Task["js:routes"].invoke
  end
end
