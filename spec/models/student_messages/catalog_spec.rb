require "rails_helper"

RSpec.describe(StudentMessages::Catalog) do
  let(:teacher) { create(:confirmed_user) }
  let(:tutor) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:tutorial) { create(:tutorial, :with_tutor_by_id, lecture: lecture, tutor_id: tutor.id) }
  let(:other_tutorial) { create(:tutorial, lecture: lecture) }
  let(:member) { create(:confirmed_user) }
  let(:outsider) { create(:confirmed_user) }

  before do
    create(:lecture_membership, lecture: lecture, user: member)
    create(:tutorial_membership, tutorial: tutorial, user: member)
    create(:lecture_membership, lecture: lecture, user: outsider)
    other_tutorial
  end

  describe "for staff" do
    subject(:catalog) { described_class.new(lecture, teacher) }

    it "offers everybody, the groups and their members" do
      expect(catalog.everyone.key).to eq("lecture:all")
      expect(catalog.everyone.user_ids).to contain_exactly(member.id, outsider.id)
      expect(catalog.sections.map(&:first)).to eq([:tutorials])
      keys = catalog.audiences.map(&:key)
      expect(keys).to include("lecture:all", "tutorial:#{tutorial.id}",
                              "tutorial:#{other_tutorial.id}")
      expect(catalog.pick(["tutorial:#{tutorial.id}"]).first.user_ids).to eq([member.id])
      expect(catalog.pick(["tutorial:#{other_tutorial.id}"]).first.count).to eq(0)
    end

    it "refuses a key that is not the lecture's" do
      foreign = create(:tutorial, lecture: create(:lecture))

      expect(catalog.pick(["tutorial:#{foreign.id}"])).to be_nil
      expect(catalog.pick(["tutorial:#{tutorial.id}", "nonsense"])).to be_nil
    end

    # While a campaign runs, its items are the groups; the rosters are only
    # filled at finalization, after which only the rejected are left to write to.
    describe "registrations" do
      let(:campaign) do
        create(:registration_campaign, :open, :first_come_first_served, campaignable: lecture)
      end
      let(:item) { create(:registration_item, registration_campaign: campaign) }
      let(:registrant) { create(:confirmed_user) }
      let(:rejected) { create(:confirmed_user) }

      before do
        create(:registration_user_registration, :confirmed, registration_campaign: campaign,
                                                            registration_item: item,
                                                            user: registrant)
        create(:registration_user_registration, :rejected, registration_campaign: campaign,
                                                           registration_item: item,
                                                           user: rejected)
      end

      it "lists the campaign, its items and the rejected while it runs" do
        by_key = catalog.audiences.index_by(&:key)

        expect(by_key["campaign:#{campaign.id}:all"].user_ids).to eq([registrant.id])
        expect(by_key["item:#{item.id}"].user_ids).to eq([registrant.id])
        expect(by_key["item:#{item.id}"].label).to end_with(item.title)
        expect(by_key["campaign:#{campaign.id}:rejected"].user_ids).to eq([rejected.id])
      end

      # An exam's campaign has one item, the exam: its registrants are the
      # campaign's, and the campaign goes by the exam's name.
      it "folds a one-item campaign into its item" do
        exam = create(:exam, lecture: lecture, title: "Midterm")
        exam_campaign = exam.registration_campaign
        exam_campaign.update!(description: "", status: :open)
        exam_item = Registration::Item.find_by!(registerable: exam)
        create(:registration_user_registration, :confirmed, registration_campaign: exam_campaign,
                                                            registration_item: exam_item,
                                                            user: create(:confirmed_user))
        keys = catalog.audiences.map(&:key)

        expect(keys).to include("campaign:#{exam_campaign.id}:all")
        expect(keys).not_to include("item:#{exam_item.id}")
        expect(catalog.audiences.find { |a| a.key == "campaign:#{exam_campaign.id}:all" }.label)
          .to start_with("Midterm")
      end

      it "keeps only the rejected once the campaign is finalized" do
        campaign.update!(status: :completed)
        keys = catalog.audiences.map(&:key)

        expect(keys).to include("campaign:#{campaign.id}:rejected")
        expect(keys).not_to include("campaign:#{campaign.id}:all", "item:#{item.id}")
      end
    end
  end

  describe "for a tutor" do
    subject(:catalog) { described_class.new(lecture, tutor) }

    it "offers their own group and nothing else" do
      expect(catalog).not_to be_staff
      expect(catalog.everyone).to be_nil
      expect(catalog.audiences.map(&:key)).to eq(["tutorial:#{tutorial.id}"])
      expect(catalog.pick(["tutorial:#{other_tutorial.id}"])).to be_nil
      expect(catalog.pick(["lecture:all"])).to be_nil
    end
  end

  it "offers a student nothing" do
    expect(described_class.new(lecture, member).audiences).to be_empty
  end
end
