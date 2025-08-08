require "rails_helper"

RSpec.describe(Search::Filters::CourseFilter, type: :filter) do
  describe "#call" do
    let(:user) { create(:user) }
    let!(:course1) { create(:course) }
    let!(:course2) { create(:course) }
    let!(:course3) { create(:course) }
    let!(:tag1) { create(:tag) }
    let!(:tag2) { create(:tag) }
    let!(:tag3) { create(:tag) }
    let!(:tag4) { create(:tag) }

    before do
      # Explicitly create the join records to ensure associations are set
      # before the filter is called.
      create(:course_tag_join, course: course1, tag: tag1)
      create(:course_tag_join, course: course2, tag: tag2)
      create(:course_tag_join, course: course2, tag: tag3)
      create(:course_tag_join, course: course3, tag: tag4)
    end

    # Tags have a direct many-to-many relationship with courses
    # so we can test the filter with them
    let(:scope) { Tag.all }

    subject(:filtered_scope) { described_class.new(scope: scope, params: params, user: user).call }

    context "when specific course_ids are provided" do
      context "with a single course ID" do
        let(:params) { { course_ids: [course2.id] } }

        it "filters the scope to include only records associated with that course" do
          expect(filtered_scope).to match_array([tag2, tag3])
        end
      end

      context "with multiple course IDs" do
        let(:params) { { course_ids: [course1.id, course2.id] } }

        it "filters the scope to include records associated with any of those courses" do
          expect(filtered_scope).to match_array([tag1, tag2, tag3])
        end
      end

      context "with non-existent course IDs" do
        let(:params) { { course_ids: [999_999] } }

        it "returns an empty result set" do
          expect(filtered_scope).to be_empty
        end
      end
    end
  end
end
