RSpec.shared_examples("a registerable model") do
  describe "interface" do
    let(:campaign) { FactoryBot.create(:registration_campaign) }
    subject { build(described_class.name.underscore.to_sym) }

    it "responds to capacity" do
      expect(subject).to respond_to(:capacity)
    end

    it "responds to skip_campaigns" do
      expect(subject).to respond_to(:skip_campaigns)
    end

    it "responds to allocated_user_ids" do
      expect(subject).to respond_to(:allocated_user_ids)
    end

    it "responds to materialize_allocation!" do
      expect(subject).to respond_to(:materialize_allocation!)
    end

    it "has nil capacity by default" do
      expect(subject.capacity).to be_nil
    end

    it "has skip_campaigns set to false by default" do
      expect(subject.skip_campaigns).to be(false)
    end
  end

  describe "capacity validation via items" do
    let(:registerable) { create(described_class.name.underscore.to_sym) }
    let(:campaign) { create(:registration_campaign, :draft, :first_come_first_served) }
    let!(:item) do
      create(:registration_item, registration_campaign: campaign, registerable: registerable)
    end

    context "when capacity reduction is invalid" do
      before do
        campaign.update!(status: :open)
        # Ensure the item belongs to the campaign
        item.update!(registration_campaign: campaign)
        create_list(:registration_user_registration, 3, :confirmed, registration_item: item,
                                                                    registration_campaign: campaign)
        registerable.update!(capacity: 5)
      end

      it "adds error to capacity" do
        registerable.capacity = 2
        # Trigger update callbacks
        registerable.save
        expect(registerable.errors[:capacity])
          .to include(I18n.t(
                        "activerecord.errors.models.registration/item.attributes" \
                        ".base.capacity_too_low",
                        count: 3
                      ))
      end
    end

    context "when capacity change is valid" do
      it "allows update" do
        registerable.capacity = 100
        expect(registerable).to be_valid
      end
    end
  end
end
