require "rails_helper"

RSpec.describe(Registration::Policy::Handler, type: :model) do
  let(:policy) { build(:registration_policy) }
  let(:handler) { described_class.new(policy) }

  describe "#evaluate" do
    it "raises NotImplementedError" do
      expect { handler.evaluate(double) }.to raise_error(NotImplementedError)
    end
  end

  describe "#summary" do
    it "returns default summary" do
      expect(handler.summary).to eq("-")
    end
  end
end
