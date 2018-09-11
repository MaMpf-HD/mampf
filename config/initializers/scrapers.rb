Dir[File.join(Rails.root, "lib", "scrapers", "*.rb")].each {|l| require l }
