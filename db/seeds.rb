# This file should contain all the record creation needed to seed the database
# with its default values.
# The data can then be loaded with the rails db:seed command
# (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
badges_data = [
  # Social Badges
  { title: "Kommentare", description: "Verfasse 10 Kommentare", icon_key: "write_comments_icon" },
  { title: "Annotationen", description: "Verfasse 10 öffentliche Kommentare in einem Semester",
    icon_key: "public_annotations_icon" },
  { title: "Neue Threads", description: "Eröffne 10 neue Threads", icon_key: "threads_icon" }
]

puts "Seeding Badges..."

badges_data.each do |badge_attrs|
  Badge.find_or_create_by!(title: badge_attrs[:title]) do |badge|
    badge.description = badge_attrs[:description]
    badge.icon_key = badge_attrs[:icon_key]
  end
end

puts "#{Badge.count} badges seeded."
