require "rails_helper"

RSpec.describe(Filters::EditorFilter, type: :filter) do
  describe "#call" do
    let!(:editor1) { FactoryBot.create(:confirmed_user) }
    let!(:editor2) { FactoryBot.create(:confirmed_user) }
    let!(:editor3) { FactoryBot.create(:confirmed_user) }
    let!(:course1) { FactoryBot.create(:course) }
    let!(:course2) { FactoryBot.create(:course) }
    let!(:course3) { FactoryBot.create(:course) }
    let!(:course4) { FactoryBot.create(:course) }
    let(:user) { FactoryBot.create(:confirmed_user) }
    let(:scope) { Course.all }

    subject(:filtered_scope) { described_class.new(scope, params, user: user).call }

    before do
      # Explicitly create the join records to ensure associations are set
      # before the filter is called.
      FactoryBot.create(:editable_user_join, editable: course1, user: editor1)
      FactoryBot.create(:editable_user_join, editable: course2, user: editor2)
      FactoryBot.create(:editable_user_join, editable: course3, user: editor1)
      FactoryBot.create(:editable_user_join, editable: course3, user: editor3)
      FactoryBot.create(:editable_user_join, editable: course4, user: editor3)
    end

    context "when 'all_editors' parameter is set to '1'" do
      let(:params) { { all_editors: "1", editor_ids: [editor1.id] } }

      it "returns the original scope without filtering" do
        expect(filtered_scope).to match_array([course1, course2, course3, course4])
      end
    end

    context "when 'editor_ids' parameter is blank" do
      context "with a nil value" do
        let(:params) { { editor_ids: nil } }
        it "returns the original scope" do
          expect(filtered_scope).to match_array([course1, course2, course3, course4])
        end
      end

      context "with an empty array" do
        let(:params) { { editor_ids: [] } }
        it "returns the original scope" do
          expect(filtered_scope).to match_array([course1, course2, course3, course4])
        end
      end

      context "with an array with a blank string" do
        let(:params) { { editor_ids: [""] } }
        it "returns the original scope" do
          expect(filtered_scope).to match_array([course1, course2, course3, course4])
        end
      end
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
        let(:other_editor) { FactoryBot.create(:confirmed_user) }
        let(:params) { { editor_ids: [other_editor.id] } }
        it "returns an empty scope" do
          expect(filtered_scope).to be_empty
        end
      end
    end
  end
end
