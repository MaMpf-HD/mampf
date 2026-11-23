require "rails_helper"

RSpec.describe(Rosters::RunningRegistrations, type: :model) do
  let(:lecture) { create(:lecture) }
  let(:fcfs) do
    create(:registration_campaign, :closed, campaignable: lecture, items_count: 2)
  end
  let(:preference) do
    create(:registration_campaign, :closed, :preference_based,
           campaignable: lecture, items_count: 2)
  end
  let(:anna) { create(:confirmed_user, first_name: "Anna", last_name: "Becker") }
  let(:jonas) { create(:confirmed_user, first_name: "Jonas", last_name: "Krause") }

  def register(user, campaign, item, status: :confirmed, rank: nil)
    create(:registration_user_registration, user: user, registration_campaign: campaign,
                                            registration_item: item, status: status,
                                            preference_rank: rank)
  end

  describe "#users" do
    it "lists the people of open, closed and processing campaigns by last name" do
      open = create(:registration_campaign, :open, campaignable: lecture)
      processing = create(:registration_campaign, :processing, campaignable: lecture)
      zoe = create(:confirmed_user, first_name: "Zoe", last_name: "Zander")
      register(zoe, fcfs, fcfs.registration_items.first)
      register(jonas, open, open.registration_items.first)
      register(anna, processing, processing.registration_items.first)

      expect(described_class.new(lecture).users).to eq([anna, jonas, zoe])
    end

    it "leaves out draft campaigns" do
      draft = create(:registration_campaign, :with_items, campaignable: lecture)
      register(anna, draft, draft.registration_items.first)

      expect(described_class.new(lecture).users).to be_empty
    end

    it "lists people who are already on the lecture roster" do
      create(:lecture_membership, lecture: lecture, user: anna)
      register(anna, fcfs, fcfs.registration_items.first)

      expect(described_class.new(lecture).users).to eq([anna])
    end

    it "leaves out rejected registrations" do
      register(anna, fcfs, fcfs.registration_items.first, status: :rejected)

      expect(described_class.new(lecture).users).to be_empty
    end

    it "leaves out completed campaigns, since they are on the rosters" do
      completed = create(:registration_campaign, :completed, campaignable: lecture)
      register(anna, completed, completed.registration_items.first)

      expect(described_class.new(lecture).users).to be_empty
    end

    it "leaves out exam campaigns and other lectures" do
      exam_campaign = create(:exam, lecture: lecture).registration_campaign
      exam_campaign.update!(status: :closed, registration_deadline: 1.day.ago)
      register(anna, exam_campaign, exam_campaign.registration_items.sole)
      other = create(:registration_campaign, :closed)
      register(jonas, other, other.registration_items.first)

      expect(described_class.new(lecture).users).to be_empty
    end

    it "finds people by name or matriculation number" do
      jonas.update!(matriculation_number: "3698123")
      register(anna, fcfs, fcfs.registration_items.first)
      register(jonas, fcfs, fcfs.registration_items.second)

      expect(described_class.new(lecture, search: "Becker").users).to eq([anna])
      expect(described_class.new(lecture, search: "3698").users).to eq([jonas])
    end
  end

  describe "#campaigns" do
    it "puts the campaign whose deadline comes first first" do
      later = create(:registration_campaign, :closed, campaignable: lecture,
                                                      registration_deadline: 1.hour.ago)
      earlier = create(:registration_campaign, :closed, campaignable: lecture,
                                                        registration_deadline: 2.days.ago)

      expect(described_class.new(lecture).campaigns).to eq([earlier, later])
    end
  end

  describe "#counts_by_campaign" do
    it "counts the people the search finds per campaign" do
      register(anna, fcfs, fcfs.registration_items.first)
      register(jonas, fcfs, fcfs.registration_items.second)
      register(anna, preference, preference.registration_items.first, status: :pending, rank: 1)
      register(anna, preference, preference.registration_items.second, status: :pending, rank: 2)

      expect(described_class.new(lecture).counts_by_campaign)
        .to eq(fcfs.id => 2, preference.id => 1)
      expect(described_class.new(lecture, search: "Krause").counts_by_campaign)
        .to eq(fcfs.id => 1)
    end
  end

  describe "#entry_by_user" do
    let(:first_item) { preference.registration_items.first }
    let(:second_item) { preference.registration_items.second }

    before do
      register(anna, preference, second_item, status: :pending, rank: 2)
      register(anna, preference, first_item, status: :pending, rank: 1)
    end

    def entry
      described_class.new(lecture, campaign: preference).entry_by_user([anna.id]).fetch(anna.id)
    end

    it "gives the chosen items in the order of the preferences" do
      expect(entry.chosen_items).to eq([first_item, second_item])
    end

    it "has no allocated item before the allocation is computed" do
      expect(entry.allocated?).to be(false)
      expect(entry.allocated_item).to be_nil
    end

    it "gives the allocated item once the allocation is computed" do
      preference.update!(status: :processing, last_allocation_calculated_at: Time.current)
      Registration::UserRegistration.find_by(user: anna, registration_item: second_item)
                                    .update!(status: :confirmed)

      expect(entry.allocated_item).to eq(second_item)
    end

    it "has no allocated item for someone the allocation left out" do
      preference.update!(status: :processing, last_allocation_calculated_at: Time.current)

      expect(entry.allocated?).to be(true)
      expect(entry.allocated_item).to be_nil
    end

    it "shows a forced assignment as the allocation, not as a choice" do
      forced_item = create(:registration_item, registration_campaign: preference)
      register(anna, preference, forced_item, status: :confirmed)
      preference.update!(status: :processing, last_allocation_calculated_at: Time.current)

      expect(entry.chosen_items).to eq([first_item, second_item])
      expect(entry.allocated_item).to eq(forced_item)
    end

    it "shows the item a real allocation run gives" do
      Registration::AllocationService.new(preference).allocate!

      expect(entry.allocated_item).to eq(first_item)
    end

    it "needs a campaign" do
      expect { described_class.new(lecture).entry_by_user([anna.id]) }
        .to raise_error(ArgumentError)
    end

    it "keeps to the given campaign" do
      register(anna, fcfs, fcfs.registration_items.first)

      expect(entry.campaign).to eq(preference)
      expect(entry.registrations.map(&:registration_campaign)).to all(eq(preference))
    end
  end
end
