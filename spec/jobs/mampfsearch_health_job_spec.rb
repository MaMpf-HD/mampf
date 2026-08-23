require "rails_helper"

RSpec.describe MampfsearchHealthJob, type: :job do
  describe "#perform" do
    it "delegates to MampfsearchHealth.new.call" do
      health_service = instance_double(MampfsearchHealth)
      expect(MampfsearchHealth).to receive(:new).and_return(health_service)
      expect(health_service).to receive(:call)

      described_class.perform_now
    end
  end
end
