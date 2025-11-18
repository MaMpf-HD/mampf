RSpec.shared_examples("a registerable model") do
  let(:campaign) { FactoryBot.create(:registration_campaign) }

  it "responds to capacity" do
    expect(subject).to respond_to(:capacity)
  end

  it "responds to allocated_user_ids" do
    expect(subject).to respond_to(:allocated_user_ids)
  end

  it "responds to materialize_allocation!" do
    expect(subject).to respond_to(:materialize_allocation!)
  end

  it "raises NotImplementedError for capacity" do
    expect do
      subject.capacity
    end.to raise_error(NotImplementedError,
                       "Registerable must implement #capacity")
  end

  it "raises NotImplementedError for allocated_user_ids" do
    expect do
      subject.allocated_user_ids
    end.to raise_error(NotImplementedError,
                       "Registerable must implement #allocated_user_ids")
  end

  it "raises NotImplementedError for materialize_allocation!" do
    expect do
      subject.materialize_allocation!(user_ids: [1, 2], campaign: campaign)
    end.to raise_error(NotImplementedError,
                       "Registerable must implement #materialize_allocation!")
  end
end
