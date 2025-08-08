require "rails_helper"

RSpec.describe(Search::Filters::TagFilter, type: :filter) do
  describe "#call" do
    let(:user) { create(:user) }
    let!(:tag1) { create(:tag) }
    let!(:tag2) { create(:tag) }
    let!(:tag3) { create(:tag) }

    # Setup media with different tag combinations
    let!(:medium1) { create(:valid_medium, tags: [tag1]) }
    let!(:medium2) { create(:valid_medium, tags: [tag2]) }
    let!(:medium3) { create(:valid_medium, tags: [tag1, tag2]) }
    let!(:medium4) { create(:valid_medium, tags: [tag3]) }
    let!(:medium_no_tags) { create(:valid_medium) }

    let(:scope) { Medium.all }
    let(:all_media) { [medium1, medium2, medium3, medium4, medium_no_tags] }

    subject(:filtered_scope) { described_class.apply(scope: scope, params: params, user: user) }

    context "when filtering with 'or' logic (default)" do
      let(:params) { { tag_ids: [tag1.id, tag2.id] } }
      it "returns all media associated with any of the given tags" do
        expect(filtered_scope).to match_array([medium1, medium2, medium3])
      end
    end

    context "when filtering with 'and' logic" do
      context "with tags that have a match" do
        let(:params) { { tag_ids: [tag1.id, tag2.id], tag_operator: "and" } }
        it "returns only media associated with all of the given tags" do
          expect(filtered_scope).to contain_exactly(medium3)
        end
      end

      context "with tags that have no match" do
        let(:params) { { tag_ids: [tag1.id, tag3.id], tag_operator: "and" } }
        it "returns an empty scope" do
          expect(filtered_scope).to be_empty
        end
      end
    end
  end
end
