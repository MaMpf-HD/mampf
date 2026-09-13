# The seed is split into numbered files under db/seeds/, loaded in order so
# that a later file can rely on what an earlier one created (010_content.rb's
# lectures before 100_scenarios.rb's registrations on them, say).
Rails.root.glob("db/seeds/[0-9]*.rb").sort.each { |file| require file }
