# The seed is split into files under db/seeds/, required in order so that a
# later file can rely on what an earlier one created (content.rb's lectures
# before scenarios.rb's registrations on them, say).
require Rails.root.join("db/seeds/content")
require Rails.root.join("db/seeds/scenarios")
