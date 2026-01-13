require "rails_helper"

RSpec.describe(Registration::Item, type: :model) do
  describe "factory" do
    it "creates a valid default item with tutorial" do
      item = FactoryBot.create(:registration_item)
      expect(item).to be_valid
      expect(item.registerable_type).to eq("Tutorial")
      expect(item.registerable.lecture).to eq(item.registration_campaign.campaignable)
    end

    it "creates a valid item for tutorial" do
      item = FactoryBot.create(:registration_item, :for_tutorial)
      expect(item).to be_valid
      expect(item.registerable_type).to eq("Tutorial")
      expect(item.registerable.lecture).to eq(item.registration_campaign.campaignable)
    end

    it "creates a valid item for talk" do
      item = FactoryBot.create(:registration_item, :for_talk)
      expect(item).to be_valid
      expect(item.registerable_type).to eq("Talk")
      expect(item.registerable.lecture).to eq(item.registration_campaign.campaignable)
    end

    it "creates a valid item for lecture" do
      item = FactoryBot.create(:registration_item, :for_lecture)
      expect(item).to be_valid
      expect(item.registerable_type).to eq("Lecture")
      expect(item.registerable).to eq(item.registration_campaign.campaignable)
    end
  end

  describe "validations" do
    subject { create(:registration_item) }

    describe "#registerable_type_consistency" do
      let(:campaign) { create(:registration_campaign) }

      context "when existing item is a tutorial" do
        let!(:tutorial_item) do
          create(:registration_item, :for_tutorial, registration_campaign: campaign)
        end

        it "allows adding another item of the same type" do
          new_item = build(:registration_item, :for_tutorial, registration_campaign: campaign)
          expect(new_item).to be_valid
        end

        it "does not allow adding an item of a different type" do
          new_item = build(:registration_item, :for_talk, registration_campaign: campaign)
          expect(new_item).not_to be_valid
          expect(new_item.errors[:base])
            .to include(I18n.t("activerecord.errors.models.registration/item.attributes.base" \
                               ".mixed_types"))
        end
      end

      context "when existing item is a lecture" do
        let!(:lecture_item) do
          create(:registration_item, :for_lecture, registration_campaign: campaign)
        end

        it "does not allow adding another lecture item" do
          new_item = build(:registration_item, :for_lecture, registration_campaign: campaign)
          expect(new_item).not_to be_valid
          expect(new_item.errors[:base])
            .to include(I18n.t("activerecord.errors.models.registration/item.attributes.base" \
                               ".lecture_unique"))
        end

        it "does not allow adding an item of a different type" do
          new_item = build(:registration_item, :for_tutorial, registration_campaign: campaign)
          expect(new_item).not_to be_valid
          expect(new_item.errors[:base])
            .to include(I18n.t("activerecord.errors.models.registration/item.attributes.base" \
                               ".lecture_unique"))
        end
      end
    end

    describe "#validate_capacity_frozen" do
      let(:campaign) { create(:registration_campaign, :draft, :first_come_first_served) }
      let(:item) { create(:registration_item, registration_campaign: campaign) }

      context "when campaign is completed" do
        before do
          item # ensure item exists
          campaign.update!(status: :completed)
        end

        it "prevents changing capacity" do
          item.capacity = 10
          expect(item).not_to be_valid
          expect(item.errors[:base])
            .to include(I18n.t("activerecord.errors.models.registration/item.attributes.base" \
                               ".frozen"))
        end
      end

      context "when campaign is processing (preference based)" do
        let(:campaign) { create(:registration_campaign, :draft, :preference_based) }

        before do
          item # ensure item exists
          campaign.update!(status: :processing)
        end

        it "prevents changing capacity" do
          item.capacity = 10
          expect(item).not_to be_valid
          expect(item.errors[:base])
            .to include(I18n.t("activerecord.errors.models.registration/item.attributes.base" \
                               ".frozen"))
        end
      end
    end

    describe "#validate_capacity_reduction" do
      let(:campaign) { create(:registration_campaign, :draft, :first_come_first_served) }
      let(:item) { create(:registration_item, registration_campaign: campaign) }

      context "when campaign is open (FCFS)" do
        before do
          item # ensure item exists
          campaign.update!(status: :open)
          create_list(:registration_user_registration, 3, :confirmed, registration_item: item)
          item.capacity = 5
          item.save
        end

        it "allows reducing capacity if still above confirmed count" do
          item.capacity = 4
          expect(item).to be_valid
        end

        it "allows setting capacity to unlimited (nil)" do
          item.capacity = nil
          expect(item).to be_valid
        end

        it "does not allow reducing capacity below confirmed count" do
          item.capacity = 2
          expect(item).not_to be_valid
          expect(item.errors[:base])
            .to include(I18n.t(
                          "activerecord.errors.models.registration/item.attributes.base" \
                          ".capacity_too_low", count: 3
                        ))
        end
      end

      context "when campaign is draft" do
        it "allows setting capacity freely" do
          item.capacity = 2
          expect(item).to be_valid
        end
      end

      context "when campaign is preference based" do
        let(:campaign) { create(:registration_campaign, :draft, :preference_based) }

        before do
          item
          campaign.update!(status: :open)
          # Create registrations to ensure validation is skipped even if they exist
          # Note: We provide preference_rank to satisfy model validations for
          # preference_based campaigns
          create_list(:registration_user_registration, 3, :pending,
                      registration_campaign: campaign,
                      registration_item: item,
                      preference_rank: 1)
        end

        it "allows reducing capacity below confirmed count (validation skipped)" do
          item.capacity = 2
          expect(item).to be_valid
        end
      end
    end

    describe "#validate_capacity_change_from_registerable!" do
      let(:campaign) { create(:registration_campaign, :draft, :first_come_first_served) }
      let(:item) { create(:registration_item, registration_campaign: campaign) }

      context "when capacity is editable" do
        it "returns nil" do
          expect(item.validate_capacity_change_from_registerable!(10)).to be_nil
        end
      end

      context "when capacity is frozen" do
        before do
          item # ensure item exists
          campaign.update!(status: :completed)
        end

        it "returns frozen error" do
          expect(item.validate_capacity_change_from_registerable!(10)).to eq([:base, :frozen])
        end
      end

      context "when capacity reduction is invalid" do
        before do
          item # ensure item exists
          campaign.update!(status: :open)
          create_list(:registration_user_registration, 3, :confirmed, registration_item: item)
          item.capacity = 5
          item.save
        end

        it "returns capacity_too_low error" do
          expect(item.validate_capacity_change_from_registerable!(2))
            .to eq([:base, :capacity_too_low, { count: 3 }])
        end
      end
    end

    describe "callbacks" do
      describe "#ensure_campaign_is_draft" do
        let(:item) { create(:registration_item, registration_campaign: campaign) }

        context "when campaign is draft" do
          let(:campaign) { create(:registration_campaign, :draft) }

          it "allows destruction" do
            item # ensure item exists
            expect { item.destroy }.to change(described_class, :count).by(-1)
          end
        end

        context "when campaign is open" do
          let(:campaign) { create(:registration_campaign, :draft) }

          before do
            item # ensure item exists
            campaign.update!(status: :open)
          end

          it "prevents destruction" do
            expect { item.destroy }.not_to change(described_class, :count)
            expect(item.errors[:base])
              .to include(I18n.t("activerecord.errors.models.registration/item.attributes.base" \
                                 ".frozen"))
          end
        end
      end
    end

    describe "#title" do
      let(:item) { create(:registration_item) }

      it "delegates to registerable registration_title if present" do
        allow(item.registerable).to receive(:registration_title).and_return("Registration Title")
        expect(item.title).to eq("Registration Title")
      end

      it "falls back to registerable title" do
        allow(item.registerable).to receive(:registration_title).and_return(nil)
        allow(item.registerable).to receive(:title).and_return("Original Title")
        expect(item.title).to eq("Original Title")
      end
    end

    describe "#capacity_editable?" do
      let(:campaign) { create(:registration_campaign, :draft, :first_come_first_served) }
      let(:item) { create(:registration_item, registration_campaign: campaign) }

      context "when campaign is draft" do
        it "returns true" do
          expect(item.capacity_editable?).to be(true)
        end
      end

      context "when campaign is open" do
        before do
          item # ensure item exists
          campaign.update!(status: :open)
        end

        it "returns true" do
          expect(item.capacity_editable?).to be(true)
        end
      end

      context "when campaign is completed" do
        before do
          item # ensure item exists
          campaign.update!(status: :completed)
        end

        it "returns false" do
          expect(item.capacity_editable?).to be(false)
        end
      end

      context "when campaign is processing" do
        context "and preference based" do
          let(:campaign) { create(:registration_campaign, :draft, :preference_based) }

          before do
            item # ensure item exists
            campaign.update!(status: :processing)
          end

          it "returns false" do
            expect(item.capacity_editable?).to be(false)
          end
        end

        context "and FCFS" do
          before do
            item # ensure item exists
            campaign.update!(status: :processing)
          end

          it "returns true" do
            expect(item.capacity_editable?).to be(true)
          end
        end
      end
    end

    describe "#first_choice_count" do
      let(:campaign) { create(:registration_campaign, :preference_based) }
      let(:item) { create(:registration_item, registration_campaign: campaign) }

      before do
        # Create 2 first choices
        create_list(:registration_user_registration, 2, registration_item: item, preference_rank: 1,
                                                        registration_campaign: campaign)
        # Create 1 second choice
        create(:registration_user_registration, registration_item: item, preference_rank: 2,
                                                registration_campaign: campaign)
      end

      it "counts only registrations with preference rank 1" do
        expect(item.first_choice_count).to eq(2)
      end
    end

    describe "#validate_uniqueness_constraints" do
      let(:lecture) { create(:lecture) }
      let(:tutorial) { create(:tutorial, lecture: lecture) }
      let(:campaign) { create(:registration_campaign, campaignable: lecture) }

      context "with registerables (strict global uniqueness)" do
        let(:other_lecture) { create(:lecture) }
        let(:other_campaign) { create(:registration_campaign, campaignable: other_lecture) }

        before do
          create(:registration_item, registration_campaign: other_campaign, registerable: tutorial)
        end

        it "is invalid if already in another campaign" do
          item = build(:registration_item, registration_campaign: campaign, registerable: tutorial)
          expect(item).not_to be_valid
          expect(item.errors[:base])
            .to include(I18n.t("activerecord.errors.models.registration/item.attributes.base" \
                               ".already_in_other_campaign"))
        end
      end
    end                               ".already_in_other_campaign"))
        end
      end
    end
  end
end
