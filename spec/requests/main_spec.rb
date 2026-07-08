require "rails_helper"

RSpec.describe("Main", type: :request) do
  let(:user) { create(:confirmed_user) }

  before do
    sign_in user
  end

  describe "GET / (start page)" do
    describe "next term banner" do
      let!(:current_term) { create(:term, :summer, :active, year: 2025) }

      def create_next_term
        create(:term, :winter, year: 2025)
      end

      def create_published_lecture(term)
        create(:lecture, :released_for_all, term: term)
      end

      context "when the feature flag is enabled" do
        before do
          Flipper.enable(:next_term_banner)
        end

        after do
          Flipper.disable(:next_term_banner)
        end

        it "shows the banner when a published lecture for the next term " \
           "exists" do
          next_term = create_next_term
          create_published_lecture(next_term)

          get root_path

          expect(response).to be_successful
          expect(response.body).to include("next-term-banner")
          expect(response.body).to include(next_term.to_label)
          expect(response.body).to include("next-term-banner-construction-icon")
          expect(response.body).to include(I18n.t("main.next_term_banner.transition_label"))
          expect(response.body).to include(I18n.t("main.next_term_banner.transition_notice"))
        end

        it "links to the next term lecture search" do
          create_published_lecture(create_next_term)

          get root_path

          expect(response.body)
            .to include(root_path(term_scope: "next", anchor: "lecture-search"))
        end

        it "does not count unpublished lectures" do
          next_term = create_next_term
          create(:lecture, term: next_term)

          get root_path

          expect(response.body).not_to include("next-term-banner")
        end

        it "does not count published lectures of other terms" do
          create_next_term
          create_published_lecture(current_term)

          get root_path

          expect(response.body).not_to include("next-term-banner")
        end

        it "does not show the banner when no next term exists" do
          get root_path

          expect(response.body).not_to include("next-term-banner")
        end
      end

      context "when the feature flag is disabled" do
        it "does not show the banner" do
          create_published_lecture(create_next_term)

          get root_path

          expect(response.body).not_to include("next-term-banner")
        end
      end
    end
  end
end
