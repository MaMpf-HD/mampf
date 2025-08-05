require "rails_helper"

RSpec.describe(Search::Filters::MediumVisibilityFilter, type: :filter) do
  describe "#call" do
    let(:user) { create(:user) }
    let(:admin) { create(:user, admin: true) }
    let(:editor) { create(:user) }

    let(:course) { create(:course) }
    let(:lecture) { create(:lecture, :released_for_all, course: course) }
    let(:other_lecture) { create(:lecture, :released_for_all) }

    # Media setup
    let!(:media_in_subscribed_lecture) do
      create(:valid_medium, teachable: lecture, released: "subscribers")
    end
    let!(:media_in_other_lecture) do
      create(:valid_medium, teachable: other_lecture, released: "subscribers")
    end
    let!(:free_media) { create(:valid_medium, teachable: other_lecture, released: "all") }
    let!(:users_media) { create(:valid_medium, teachable: other_lecture, released: "users") }
    let!(:unpublished_media) { create(:valid_medium, teachable: lecture, released: nil) }
    let!(:edited_media) do
      create(:valid_medium, teachable: other_lecture, editors: [editor], released: nil)
    end

    let(:scope) { Medium.all }

    before do
      user.subscribe_lecture!(lecture)
      other_lecture.editors << editor
    end

    context "for a regular user" do
      subject(:filtered_scope) { described_class.new(scope, {}, user: user).call }

      it "includes media from subscribed lectures" do
        expect(filtered_scope).to include(media_in_subscribed_lecture)
      end

      it "includes media released for 'all' or 'users'" do
        expect(filtered_scope).to include(free_media, users_media)
      end

      it "excludes media from unsubscribed lectures" do
        expect(filtered_scope).not_to include(media_in_other_lecture)
      end

      it "excludes unpublished media" do
        expect(filtered_scope).not_to include(unpublished_media)
      end
    end

    context "for an editor" do
      subject(:filtered_scope) { described_class.new(scope, {}, user: editor).call }

      it "includes media they edit, even if unpublished" do
        expect(filtered_scope).to include(edited_media)
      end
    end

    context "for an admin" do
      subject(:filtered_scope) { described_class.new(scope, {}, user: admin).call }

      it "returns all media" do
        expect(filtered_scope).to match_array(Medium.all)
      end
    end
  end
end
