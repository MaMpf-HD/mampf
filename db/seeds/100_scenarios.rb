# The demo scenarios, run on top of the content core (010_content.rb) to give
# a developer everything to click around: rosters, campaigns, coursework,
# assessment, performance, eligibility, exams, grading, vignettes, the
# next-term banner, a legacy pre-roster lecture, and the forum/announcement
# material EnrichSupport adds. Each of these already knows how to find (or
# build) the lecture it plays on and how to reset its own state, so this is
# just the order that has always produced a consistent whole -- what used to
# be `rails db:seed` after restoring the shipped dump.
require "factory_bot_rails"

Scenarios::SetupSupport.setup_from_scratch!(homework: false)
Scenarios::CampaignSetupSupport.setup!
Scenarios::NextTermBannerSupport.setup!
Scenarios::VignettesSupport.setup!
Scenarios::LegacyLectureSupport.setup!

# Registration still open in the term after the one the seed plays in,
# nothing left dangling in the one it does, deadlines that do not go stale,
# and two accounts kept on an outdated password policy.
Scenarios::ScenarioTouchupsSupport.add_running_campaigns!
Scenarios::ScenarioTouchupsSupport.settle_current_term_campaigns!
Scenarios::ScenarioTouchupsSupport.extend_open_deadlines!
Scenarios::ScenarioTouchupsSupport.stage_password_policy!

# The accounts a developer signs in with, seated with the coursework already
# under way -- last, so the homework below has somewhere to land.
Seeds::CourseworkSupport.setup!
Scenarios::SetupSupport.setup_homework_submissions!

Seeds::EnrichSupport.enrich!

puts "db/seeds/100_scenarios.rb: scenarios ready."
