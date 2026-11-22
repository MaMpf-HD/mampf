require "rails_helper"

RSpec.describe(UserCleanerJob, type: :worker) do
  subject { described_class.new }

  let(:cleaner) { instance_double(UserCleaner, handle_inactive_users!: nil) }

  before { allow(UserCleaner).to receive(:new).and_return(cleaner) }

  it "handles inactive users on the production instance" do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("INSTANCE_NAME", nil).and_return("mampf")

    subject.perform

    expect(cleaner).to have_received(:handle_inactive_users!)
  end

  it "leaves users alone on any other instance" do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("INSTANCE_NAME", nil).and_return("mampf-staging")

    subject.perform

    expect(cleaner).not_to have_received(:handle_inactive_users!)
  end
end
