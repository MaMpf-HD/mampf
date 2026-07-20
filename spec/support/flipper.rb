RSpec.configure do |config|
  config.before(:suite) do
    [
      :assessment_grading,
      :registration_campaigns,
      :roster_maintenance,
      :student_performance
    ].each { |feature| Flipper.add(feature) }
  end
end
