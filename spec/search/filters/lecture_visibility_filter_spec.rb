require "rails_helper"

RSpec.describe(Filters::LectureVisibilityFilter, type: :filter) do
  describe "#call" do
    let!(:admin) { create(:user, admin: true) }
    let!(:regular_user) { create(:user) }

    # 1. A lecture that is explicitly published and should be visible to everyone.
    let!(:published_lecture) { create(:lecture, released: "all") }

    # 2. An unpublished lecture where the user is the teacher.
    let!(:taught_lecture) { create(:lecture, teacher: regular_user, released: nil) }

    # 3. An unpublished lecture where the user is an editor.
    let!(:edited_lecture) { create(:lecture, editors: [regular_user], released: nil) }

    # 4. A completely private, unpublished lecture.
    let!(:private_lecture) { create(:lecture, released: nil) }

    let(:scope) { Lecture.all }
    let(:all_lectures) { [published_lecture, taught_lecture, edited_lecture, private_lecture] }

    subject(:filtered_scope) { described_class.new(scope, {}, user: current_user).call }

    context "when the user is an admin" do
      let(:current_user) { admin }

      it "returns the original scope without filtering" do
        expect(filtered_scope).to match_array(all_lectures)
      end
    end

    context "when the user is not an admin" do
      let(:current_user) { regular_user }

      it "returns all lectures that are published, taught by the user, or edited by the user" do
        expected_lectures = [published_lecture, taught_lecture, edited_lecture]
        expect(filtered_scope).to match_array(expected_lectures)
      end

      it "does not return private lectures where the user has no role" do
        expect(filtered_scope).not_to include(private_lecture)
      end
    end
  end
end
