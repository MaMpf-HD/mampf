require "rails_helper"

RSpec.describe(Search::Filters::EditorFilter, type: :filter) do
  describe "#call" do
    let!(:editor1) { create(:confirmed_user) }
    let!(:editor2) { create(:confirmed_user) }
    let!(:editor3) { create(:confirmed_user) }
    let!(:course1) { create(:course) }
    let!(:course2) { create(:course) }
    let!(:course3) { create(:course) }
    let!(:course4) { create(:course) }
    let(:user) { create(:confirmed_user) }
    let(:scope) { Course.all }

    subject(:filtered_scope) { described_class.filter(scope: scope, params: params, user: user) }

    before do
      # Explicitly create the join records to ensure associations are set
      # before the filter is called.
      create(:editable_user_join, editable: course1, user: editor1)
      create(:editable_user_join, editable: course2, user: editor2)
      create(:editable_user_join, editable: course3, user: editor1)
      create(:editable_user_join, editable: course3, user: editor3)
      create(:editable_user_join, editable: course4, user: editor3)
    end

    context "when specific editor_ids are provided" do
      context "with a single editor" do
        let(:params) { { editor_ids: [editor1.id] } }
        it "filters the scope to records associated with that editor" do
          expect(filtered_scope).to match_array([course1, course3])
        end
      end

      context "with multiple editor ids" do
        let(:params) { { editor_ids: [editor1.id, editor2.id] } }
        it "filters by multiple editor ids" do
          expect(filtered_scope).to match_array([course1, course2, course3])
        end
      end

      context "with a non-matching editor id" do
        let(:other_editor) { create(:confirmed_user) }
        let(:params) { { editor_ids: [other_editor.id] } }
        it "returns an empty scope" do
          expect(filtered_scope).to be_empty
        end
      end
    end
  end
end
