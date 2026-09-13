# The content core -- terms, courses, lectures, tags/notions/relations, items,
# media metadata, personas -- read from db/seeds/data/*.yml. See
# Seeds::LoadSupport and db/seeds/data/README.md.
report = Seeds::LoadSupport.load!

if report == :already_loaded
  puts "db/seeds/content.rb: content core already present, skipping."
else
  report.each { |row| puts "#{row[:group]}: #{row[:loaded]} loaded" }
  puts "Personas sign in with password \"#{Seeds::LoadSupport::PASSWORD}\", " \
       "e.g. teacher@mampf.edu or student1@mampf.edu."
end
