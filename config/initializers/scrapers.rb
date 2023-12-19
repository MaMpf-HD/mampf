Dir[Rails.root.join("lib/scrapers/*.rb").to_s].each { |l| require l }
