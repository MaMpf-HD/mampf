require "rails_helper"

RSpec.describe(RosterSupersetCheckerJob, type: :worker) do
  subject { described_class.new }

  describe "#perform" do
    it "delegates to Rosters::RosterSupersetChecker" do
      checker = instance_double(Rosters::RosterSupersetChecker)
      allow(Rosters::RosterSupersetChecker).to receive(:new).and_return(checker)
      expect(checker).to receive(:check_all_lectures!)

      subject.perform
    end
  end
end
