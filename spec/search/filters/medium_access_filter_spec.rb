require "rails_helper"

RSpec.describe(Search::Filters::MediumAccessFilter, type: :filter) do
  describe "#call" do
    let(:user) { create(:user) }
    let(:published_lecture) { create(:lecture, :released_for_all) }

    # All of our test media are associated to a published lecture.
    # Otherwise the released setting would be overriden by the
    # :reset_released_status before_save action in medium.rb
    let!(:medium_all) { create(:valid_medium, teachable: published_lecture, released: "all") }
    let!(:medium_users) { create(:valid_medium, teachable: published_lecture, released: "users") }
    let!(:medium_subscribers) do
      create(:valid_medium, teachable: published_lecture, released: "subscribers")
    end
    let!(:medium_locked) { create(:valid_medium, teachable: published_lecture, released: "locked") }
    let!(:medium_unpublished) { create(:valid_medium, teachable: published_lecture, released: nil) }

    let(:scope) { Medium.all }
    let(:all_media) do
      [medium_all, medium_users, medium_subscribers, medium_locked, medium_unpublished]
    end

    subject(:filtered_scope) { described_class.new(scope, params, user: user).call }

    context "when the filter is not applicable" do
      context "because access is 'irrelevant'" do
        let(:params) { { access: "irrelevant" } }

        it "returns the original scope" do
          expect(filtered_scope).to match_array(all_media)
        end
      end

      context "because access is blank" do
        let(:params) { { access: "" } }

        it "returns the original scope" do
          expect(filtered_scope).to match_array(all_media)
        end
      end

      context "because access is nil" do
        let(:params) { { access: nil } }

        it "returns the original scope" do
          expect(filtered_scope).to match_array(all_media)
        end
      end
    end

    context "when filtering for a specific access level" do
      context "for 'unpublished'" do
        let(:params) { { access: "unpublished" } }

        it "returns only media where released is nil" do
          expect(filtered_scope).to contain_exactly(medium_unpublished)
        end
      end

      context "for 'all'" do
        let(:params) { { access: "all" } }

        it "returns only media where released is 'all'" do
          expect(filtered_scope).to contain_exactly(medium_all)
        end
      end

      context "for 'users'" do
        let(:params) { { access: "users" } }

        it "returns only media where released is 'users'" do
          expect(filtered_scope).to contain_exactly(medium_users)
        end
      end

      context "for 'subscribers'" do
        let(:params) { { access: "subscribers" } }

        it "returns only media where released is 'subscribers'" do
          expect(filtered_scope).to contain_exactly(medium_subscribers)
        end
      end

      context "for 'locked'" do
        let(:params) { { access: "locked" } }

        it "returns only media where released is 'locked'" do
          expect(filtered_scope).to contain_exactly(medium_locked)
        end
      end
    end
  end
end
