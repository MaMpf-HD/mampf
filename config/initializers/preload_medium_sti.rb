# see https://weblog.rubyonrails.org/2019/2/22/zeitwerk-integration-in-rails-6-beta-2/
# zeitwerk integration for sti

autoloader = Rails.autoloaders.main
sti_leaves = ["question", "quiz", "remark"]

sti_leaves.each do |leaf|
  autoloader.on_setup { leaf.to_s }
end
