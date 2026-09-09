require "rails_helper"

RSpec.describe("Main", type: :request) do
  let(:user) { create(:confirmed_user) }

  before do
    sign_in user
  end

  describe "GET / (start page)" do
    # Transitional, until the dashboard replaces the accordion: what the user
    # has subscribed for the term being prepared gets its own fold instead of
    # sitting among the terms gone by.
    describe "the fold for the coming term" do
      let!(:current_term) { create(:term, :summer, :active, year: 2025) }
      let(:next_term) { create(:term, :winter, year: 2025) }

      def cards_in(testid)
        Nokogiri::HTML(response.body)
                .css("[data-testid='#{testid}'] .lectureCard")
                .pluck("data-id")
      end

      def heading_for(term)
        CGI.escapeHTML(
          I18n.t("profile.my_next_term_html", term: term.to_label)
        ).gsub("&amp;ndash;", "&ndash;")
      end

      it "lists a lecture the user subscribed for the coming term" do
        lecture = create(:lecture, :released_for_all, term: next_term)
        user.subscribe_lecture!(lecture)

        get root_path

        expect(response.body).to include(heading_for(next_term))
        expect(cards_in("next-term-subscribed")).to include(lecture.id.to_s)
      end

      it "stands there empty when nothing is subscribed for that term" do
        create(:lecture, :released_for_all, term: next_term)

        get root_path

        expect(response.body).to include(heading_for(next_term))
        expect(cards_in("next-term-subscribed")).to be_empty
        expect(response.body).to include(
          CGI.escapeHTML(I18n.t("profile.no_next_term_stuff").strip)
        )
      end

      # A registration is not a seat, so the lecture stands in its own group
      # rather than among the subscriptions.
      it "shows a lecture the user has applied to, apart from the rest" do
        lecture = create(:lecture, :released_for_all, term: next_term)
        campaign = create(:registration_campaign, :open, campaignable: lecture)
        create(:registration_user_registration, :pending,
               user: user, registration_campaign: campaign)

        get root_path

        expect(cards_in("next-term-registrations")).to include(lecture.id.to_s)
        expect(cards_in("next-term-subscribed")).to be_empty
      end

      # A cohort that does not enrol its members leaves them without a
      # subscription, and the lecture would say nothing for itself.
      it "shows a lecture the user has a seat in without a subscription" do
        lecture = create(:lecture, :released_for_all, term: next_term)
        cohort = create(:cohort, context: lecture, propagate_to_lecture: false)
        create(:cohort_membership, cohort: cohort, user: user)

        get root_path

        expect(cards_in("next-term-seats")).to include(lecture.id.to_s)
        expect(user.lectures).not_to include(lecture)
      end

      it "says nothing about an application that was turned down" do
        lecture = create(:lecture, :released_for_all, term: next_term)
        campaign = create(:registration_campaign, :open, campaignable: lecture)
        create(:registration_user_registration, :rejected,
               user: user, registration_campaign: campaign)

        get root_path

        expect(response.body).not_to include("next-term-registrations")
      end

      # Applying and subscribing are different things, but one card is enough:
      # the subscription is the stronger statement and already stands there.
      it "shows a subscribed lecture once, even when applied for as well" do
        lecture = create(:lecture, :released_for_all, term: next_term)
        campaign = create(:registration_campaign, :open, campaignable: lecture)
        create(:registration_user_registration, :pending,
               user: user, registration_campaign: campaign)
        user.subscribe_lecture!(lecture)

        get root_path

        expect(cards_in("next-term-subscribed")).to include(lecture.id.to_s)
        expect(response.body).not_to include("next-term-registrations")
      end

      it "has no fold where there is no term to prepare for" do
        get root_path

        expect(response.body).not_to include("collapseNextTermStuff")
      end

      # Both folds would otherwise show the same lecture, one of them under
      # "further subscribed".
      it "takes the lecture out of the subscriptions of terms gone by" do
        lecture = create(:lecture, :released_for_all, term: next_term)
        user.subscribe_lecture!(lecture)

        get root_path

        expect(cards_in("further-subscribed")).not_to include(lecture.id.to_s)
      end
    end

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

        it "counts published term-independent lectures (they are part of " \
           "the results the banner links to)" do
          next_term = create_next_term
          create_published_lecture(next_term)
          course = create(:course, :term_independent)
          create(:lecture, :term_independent, :released_for_all,
                 course: course)

          get root_path

          heading = I18n.t("main.next_term_banner.heading",
                           term: next_term.to_label, count: 2)
          lead, rest = heading.split(" — ", 2)
          expect(response.body).to include(lead)
          expect(response.body).to include("— #{rest}")
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
