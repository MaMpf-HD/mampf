require "rails_helper"

RSpec.describe("Main", type: :request) do
  let(:user) { create(:confirmed_user) }

  before do
    sign_in user
  end

  describe "GET / (start page)" do
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

      it "shows a lecture the user has applied to, apart from the rest" do
        lecture = create(:lecture, :released_for_all, term: next_term)
        campaign = create(:registration_campaign, :open, campaignable: lecture)
        create(:registration_user_registration, :pending,
               user: user, registration_campaign: campaign)

        get root_path

        expect(cards_in("next-term-registrations")).to include(lecture.id.to_s)
        expect(cards_in("next-term-subscribed")).to be_empty
      end

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

      # A lecturer's lecture is theirs without a subscription - that is a
      # student's tie - and stays so when the term turns.
      describe "the lectures the user holds or edits" do
        it "lists the user's own lecture for the coming term without a subscription" do
          lecture = create(:lecture, :released_for_all, term: next_term, teacher: user)

          get root_path

          expect(cards_in("next-term-subscribed")).to include(lecture.id.to_s)
          empty_state = Nokogiri::HTML(response.body).at_css("#emptyNextTermStuff")
          expect(empty_state["style"]).to include("display: none")
        end

        it "lists a lecture the user edits, once, whether subscribed or not" do
          lecture = create(:lecture, :released_for_all, term: next_term)
          lecture.editors << user
          user.subscribe_lecture!(lecture)

          get root_path

          expect(cards_in("next-term-subscribed")).to eq([lecture.id.to_s])
        end

        it "lists the user's own lecture of the current term as well" do
          lecture = create(:lecture, :released_for_all, term: current_term, teacher: user)

          get root_path

          fold = Nokogiri::HTML(response.body).at_css("#collapseCurrentStuffContent")
          card = fold.at_css(".lectureCard[data-id='#{lecture.id}']")
          expect(card).to be_present
          expect(card.css("a").pluck("href")).to include(lecture_path(lecture))
          expect(card.css("a[title]").pluck("title"))
            .not_to include(I18n.t("basics.subscribe"), I18n.t("basics.unsubscribe"))
        end

        it "lists an own lecture without a term in the current fold, as the subscriptions are" do
          lecture = create(:lecture, :released_for_all, :term_independent, teacher: user)

          get root_path

          fold = Nokogiri::HTML(response.body).at_css("#collapseCurrentStuffContent")
          expect(fold.at_css(".lectureCard[data-id='#{lecture.id}']")).to be_present
        end

        # With the current fold filled, the fold of terms gone by is not the
        # one to open, and it is not drawn empty.
        it "keeps the fold of terms gone by closed when an own lecture fills the current one" do
          create(:lecture, :released_for_all, term: current_term, teacher: user)
          gone = create(:term, :winter, year: 2023)
          old_lecture = create(:lecture, :released_for_all, term: gone)
          user.subscribe_lecture!(old_lecture)

          get root_path

          page = Nokogiri::HTML(response.body)
          expect(page.at_css("#collapseCurrentStuff")["class"]).to include("show")
          expect(page.at_css("#collapseInactiveLectures")["class"]).not_to include("show")
          expect(page.at_css("#emptyInactiveLectures")["style"]).to include("display: none")
        end

        # The fold reloads its cards when it is opened again.
        it "draws the own lecture again when the current fold is reopened" do
          lecture = create(:lecture, :released_for_all, term: current_term, teacher: user)

          get show_accordion_path(id: "collapseCurrentStuff"), xhr: true

          expect(response.body).to include("data-id=\\\"#{lecture.id}\\\"")
          expect(response.body).not_to include("$('#emptyCurrentStuff').show()")
        end

        it "does not pin a course editor's every lecture to the page" do
          lecture = create(:lecture, :released_for_all, term: next_term)
          lecture.course.editors << user

          get root_path

          expect(cards_in("next-term-subscribed")).to be_empty
        end
      end

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
