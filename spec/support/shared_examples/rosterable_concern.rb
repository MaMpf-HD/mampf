RSpec.shared_examples("a rosterable model") do
  let(:user) { create(:user) }
  let(:campaign) { create(:registration_campaign) }
  let(:other_campaign) { create(:registration_campaign) }

  # We need a persisted subject for DB operations
  let(:rosterable) { create(described_class.name.underscore.to_sym) }

  # Helper to find the join record without knowing the column name explicitly in the test body
  def find_roster_entry(rosterable, user)
    rosterable.roster_entries.find_by(rosterable.roster_user_id_column => user.id)
  end

  def roster_association_name
    rosterable.roster_entries.proxy_association.reflection.name
  end

  describe "interface" do
    subject { rosterable }
    it { is_expected.to respond_to(:roster_entries) }
    it { is_expected.to respond_to(:roster_user_id_column) }
    it { is_expected.to respond_to(:roster_association_name) }
    it { is_expected.to respond_to(:add_user_to_roster!) }
    it { is_expected.to respond_to(:remove_user_from_roster!) }
    it { is_expected.to respond_to(:materialize_allocation!) }
    it { is_expected.to respond_to(:allocated_user_ids) }

    it "roster_association_name returns a symbol" do
      expect(rosterable.roster_association_name).to be_a(Symbol)
    end

    it "roster_association_name matches an actual association" do
      expect(rosterable.class.reflect_on_association(rosterable.roster_association_name))
        .to be_present
    end
  end

  describe "#allocated_user_ids" do
    before { rosterable.add_user_to_roster!(user) }

    it "returns the ids of users in the roster" do
      expect(rosterable.allocated_user_ids).to include(user.id)
    end

    context "when roster entries are loaded" do
      before { rosterable.roster_entries.load }

      it "uses the loaded association to fetch ids" do
        expect(rosterable.association(roster_association_name)).to be_loaded
        expect(rosterable.allocated_user_ids).to include(user.id)
      end
    end
  end

  describe "#roster_empty?" do
    context "when roster is empty" do
      it "returns true" do
        expect(rosterable).to be_roster_empty
      end
    end

    context "when roster has users" do
      before { rosterable.add_user_to_roster!(user) }

      it "returns false" do
        expect(rosterable).not_to be_roster_empty
      end

      it "returns false using loaded association" do
        rosterable.roster_entries.load
        expect(rosterable.association(roster_association_name)).to be_loaded
        expect(rosterable).not_to be_roster_empty
      end
    end
  end

  describe "#full?" do
    # Only applicable if the model has a capacity
    if described_class.new.respond_to?(:capacity)
      context "with capacity" do
        before do
          rosterable.capacity = 1
          rosterable.save! if rosterable.persisted?
        end

        it "returns false when below capacity" do
          expect(rosterable).not_to be_full
        end

        it "returns true when at capacity" do
          rosterable.add_user_to_roster!(user)
          expect(rosterable).to be_full
        end

        it "returns true when at capacity (loaded)" do
          rosterable.add_user_to_roster!(user)
          rosterable.roster_entries.load
          expect(rosterable).to be_full
        end
      end
    end
  end

  describe "#over_capacity?" do
    if described_class.new.respond_to?(:capacity)
      context "with capacity" do
        before do
          rosterable.capacity = 1
          rosterable.save! if rosterable.persisted?
        end

        it "returns false when at capacity" do
          rosterable.add_user_to_roster!(user)
          expect(rosterable).not_to be_over_capacity
        end

        it "returns true when exceeding capacity" do
          rosterable.add_user_to_roster!(user)
          rosterable.add_user_to_roster!(create(:user))
          expect(rosterable).to be_over_capacity
        end

        it "returns true when exceeding capacity (loaded)" do
          rosterable.add_user_to_roster!(user)
          rosterable.add_user_to_roster!(create(:user))
          rosterable.roster_entries.load
          expect(rosterable).to be_over_capacity
        end
      end
    end
  end

  describe "#add_user_to_roster!" do
    it "adds the user to the roster" do
      expect do
        rosterable.add_user_to_roster!(user)
      end.to change { rosterable.roster_entries.count }.by(1)

      expect(find_roster_entry(rosterable, user)).to be_present
    end

    it "associates the user with the campaign if provided" do
      rosterable.add_user_to_roster!(user, campaign)
      entry = find_roster_entry(rosterable, user)
      expect(entry.source_campaign).to eq(campaign)
    end
  end

  describe "#remove_user_from_roster!" do
    before { rosterable.add_user_to_roster!(user) }

    it "removes the user from the roster" do
      expect do
        rosterable.remove_user_from_roster!(user)
      end.to change { rosterable.roster_entries.count }.by(-1)

      expect(find_roster_entry(rosterable, user)).to be_nil
    end
  end

  describe "#materialize_allocation!" do
    let(:users_to_keep) { create_list(:user, 2) }
    let(:users_to_add) { create_list(:user, 2) }
    let(:users_to_remove) { create_list(:user, 2) }
    let(:manual_users) { create_list(:user, 2) }
    let(:other_campaign_users) { create_list(:user, 2) }

    before do
      # Users to keep (already in roster via campaign)
      users_to_keep.each { |u| rosterable.add_user_to_roster!(u, campaign) }

      # Users to remove (already in roster via campaign, but won't be in target list)
      users_to_remove.each { |u| rosterable.add_user_to_roster!(u, campaign) }

      # Manual users (no campaign)
      manual_users.each { |u| rosterable.add_user_to_roster!(u) }

      # Other campaign users
      other_campaign_users.each { |u| rosterable.add_user_to_roster!(u, other_campaign) }
    end

    it "syncs the roster correctly" do
      target_users = users_to_keep + users_to_add

      rosterable.materialize_allocation!(user_ids: target_users.map(&:id), campaign: campaign)

      # Check users to add are present
      users_to_add.each do |u|
        entry = find_roster_entry(rosterable, u)
        expect(entry).to be_present
        expect(entry.source_campaign).to eq(campaign)
      end

      # Check users to keep are still present
      users_to_keep.each do |u|
        entry = find_roster_entry(rosterable, u)
        expect(entry).to be_present
        expect(entry.source_campaign).to eq(campaign)
      end

      # Check users to remove are gone
      users_to_remove.each do |u|
        expect(find_roster_entry(rosterable, u)).to be_nil
      end

      # Check manual users are untouched
      manual_users.each do |u|
        entry = find_roster_entry(rosterable, u)
        expect(entry).to be_present
        expect(entry.source_campaign).to be_nil
      end

      # Check other campaign users are untouched
      other_campaign_users.each do |u|
        entry = find_roster_entry(rosterable, u)
        expect(entry).to be_present
        expect(entry.source_campaign).to eq(other_campaign)
      end
    end
  end
end
