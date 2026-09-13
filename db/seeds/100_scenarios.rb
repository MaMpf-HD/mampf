# The demo scenarios, run on top of the content core (010_content.rb) to give
# a developer everything to click around: rosters, campaigns, coursework,
# assessment, performance, eligibility, exams, grading, vignettes, the
# next-term banner, a legacy pre-roster lecture, and the forum/announcement
# material EnrichSupport adds. Each of these already knows how to find (or
# build) the lecture it plays on and how to reset its own state, so this is
# just the order that has always produced a consistent whole -- what used to
# be `rails db:seed` after restoring the shipped dump.
require "factory_bot_rails"
require Rails.root.join("lib/seeds/build_support")

Demo::SetupSupport.setup_from_scratch!(homework: false)
Demo::CampaignSetupSupport.setup!
Demo::NextTermBannerSupport.setup!
Demo::VignettesSupport.setup!
Demo::LegacyLectureSupport.setup!

# Registration still open in the term after the one the seed plays in, and
# nothing left dangling in the one it does.
Seeds::BuildSupport.add_running_campaigns!
Seeds::BuildSupport.settle_current_term_campaigns!
Seeds::BuildSupport.extend_open_deadlines!

# The accounts a developer signs in with, seated with the coursework already
# under way -- last, so the homework below has somewhere to land.
Seeds::CourseworkSupport.setup!
Demo::SetupSupport.setup_homework_submissions!

Seeds::EnrichSupport.enrich!

puts "db/seeds/100_scenarios.rb: scenarios ready."
