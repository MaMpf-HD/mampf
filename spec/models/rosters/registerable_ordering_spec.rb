require "rails_helper"

# Missing top-level docstring, please formulate one yourself 😁
RSpec.describe(Rosters::RegisterableOrdering) do
  let(:lecture) { create(:lecture) }

  describe ".sort" do
    it "places tutorials before cohorts" do
      cohort = create(:cohort, :enrollment, context: lecture, title: "Alpha")
      tutorial = create(:tutorial, lecture: lecture, title: "Zeta")

      result = described_class.sort([cohort, tutorial])

      expect(result).to eq([tutorial, cohort])
    end

    it "sorts tutorials alphabetically by title" do
      t2 = create(:tutorial, lecture: lecture, title: "Beta")
      t1 = create(:tutorial, lecture: lecture, title: "Alpha")
      t3 = create(:tutorial, lecture: lecture, title: "Gamma")

      result = described_class.sort([t2, t1, t3])

      expect(result).to eq([t1, t2, t3])
    end

    it "places propagating cohorts before non-propagating ones" do
      non_prop = create(:cohort, :planning, context: lecture, title: "Alpha")
      prop = create(:cohort, :enrollment, context: lecture, title: "Beta")

      result = described_class.sort([non_prop, prop])

      expect(result).to eq([prop, non_prop])
    end

    it "sorts cohorts of the same propagation type alphabetically" do
      c2 = create(:cohort, :enrollment, context: lecture, title: "Zeta")
      c1 = create(:cohort, :enrollment, context: lecture, title: "Alpha")

      result = described_class.sort([c2, c1])

      expect(result).to eq([c1, c2])
    end

    context "with a seminar" do
      let(:seminar) { create(:lecture, :is_seminar) }

      it "sorts talks by position, not title" do
        talk_b = create(:talk, lecture: seminar, title: "Beta", position: 1)
        talk_a = create(:talk, lecture: seminar, title: "Alpha", position: 2)

        result = described_class.sort([talk_a, talk_b])

        expect(result).to eq([talk_b, talk_a])
      end

      it "places talks before cohorts" do
        cohort = create(:cohort, :enrollment, context: seminar, title: "Alpha")
        talk = create(:talk, lecture: seminar, title: "Zeta", position: 1)

        result = described_class.sort([cohort, talk])

        expect(result).to eq([talk, cohort])
      end
    end

    it "handles a full mixed collection for a lecture" do
      prop_cohort = create(:cohort, :enrollment, context: lecture, title: "Prop")
      non_prop = create(:cohort, :planning, context: lecture, title: "Aux")
      t2 = create(:tutorial, lecture: lecture, title: "Beta")
      t1 = create(:tutorial, lecture: lecture, title: "Alpha")

      result = described_class.sort([non_prop, t2, prop_cohort, t1])

      expect(result).to eq([t1, t2, prop_cohort, non_prop])
    end
  end

  describe ".sort_items" do
    it "sorts items by their registerable ordering" do
      campaign = create(:registration_campaign, campaignable: lecture)
      t1 = create(:tutorial, lecture: lecture, title: "Alpha")
      t2 = create(:tutorial, lecture: lecture, title: "Beta")
      cohort = create(:cohort, :enrollment, context: lecture, title: "Gamma")

      item_cohort = create(:registration_item,
                           registration_campaign: campaign,
                           registerable: cohort)
      item_t2 = create(:registration_item,
                       registration_campaign: campaign,
                       registerable: t2)
      item_t1 = create(:registration_item,
                       registration_campaign: campaign,
                       registerable: t1)

      result = described_class.sort_items([item_cohort, item_t2, item_t1])

      expect(result).to eq([item_t1, item_t2, item_cohort])
    end
  end

  describe ".item_sort_key" do
    it "returns an array usable for comparison" do
      tutorial = create(:tutorial, lecture: lecture, title: "Hello")
      campaign = create(:registration_campaign, campaignable: lecture)
      item = create(:registration_item,
                    registration_campaign: campaign,
                    registerable: tutorial)

      key = described_class.item_sort_key(item)

      expect(key).to be_an(Array)
      expect(key.length).to eq(4)
    end
  end
end
