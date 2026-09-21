require "rails_helper"

RSpec.describe(AssessmentsIndexComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  context "with a lecture" do
    let(:lecture) { create(:lecture, teacher: teacher) }

    it "includes assignments" do
      create(:valid_assignment, lecture: lecture, title: "Assignment 1")
      component = described_class.new(lecture: lecture)
      render_inline(component)
      expect(rendered_content).to include("Assignment 1")
    end

    # One table needs no heading; two do, one each.
    it "lists tests in a table of their own, and names both tables then" do
      create(:valid_assignment, lecture: lecture, title: "Assignment 1")
      page = render_inline(described_class.new(lecture: lecture))
      expect(page.css("h6")).to be_empty

      create(:valid_assignment, lecture: lecture, title: "Test 1", kind: :test)
      page = render_inline(described_class.new(lecture: lecture))
      expect(page.css("h6").map(&:text)).to eq(["Homework", "Tests"])
      expect(page.css("#assessment-tests-list").text).to include("Test 1")
      expect(page.css("#assessment-assignments-list").text).not_to include("Test 1")
    end

    it "names no table where the tests are the only one" do
      create(:valid_assignment, lecture: lecture, title: "Test 1", kind: :test)
      page = render_inline(described_class.new(lecture: lecture))

      expect(page.css("h6")).to be_empty
      expect(page.css("#assessment-tests-list").text).to include("Test 1")
    end

    # A sheet set up with a medium's release exists only from that release
    # on; the lecturer should still see it here, and where to change it.
    describe "a sheet scheduled with a medium" do
      let(:medium) do
        create(:lecture_medium, :with_lecture_by_id, lecture_id: lecture.id, sort: "Exercise")
      end

      def schedule(release_date:)
        medium.update!(publisher: MediumPublisher.new(medium_id: medium.id, user_id: teacher.id,
                                                      release_now: false,
                                                      release_date: release_date,
                                                      create_assignment: true,
                                                      assignment_title: "Sheet 2",
                                                      assignment_deadline: 9.days.from_now,
                                                      assignment_file_type: ".pdf"))
      end

      before { schedule(release_date: 2.days.from_now) }

      it "is listed before the sheets that exist, pointing at the medium's settings" do
        create(:valid_assignment, lecture: lecture, title: "Sheet 1")

        page = I18n.with_locale(:en) { render_inline(described_class.new(lecture: lecture)) }
        rows = page.css("#assessment-assignments-list tr")

        expect(rows.map { |row| row.css("td").first.text.squish })
          .to eq(["Sheet 2 appears on #{I18n.l(2.days.from_now, format: :short, locale: :en)}",
                  "Sheet 1"])
        expect(rows.first.css("a").pluck("href")).to eq(["/media/#{medium.id}/edit"])
        expect(rows.first.text).to include(".pdf")
      end

      it "says so when the release is overdue" do
        schedule(release_date: 10.minutes.ago)

        page = I18n.with_locale(:en) { render_inline(described_class.new(lecture: lecture)) }

        expect(page.css("#assessment-assignments-list tr").first.text)
          .to include("was to appear on")
      end

      it "gets the table even when no sheet exists yet" do
        page = render_inline(described_class.new(lecture: lecture))

        expect(page.css("#assessment-assignments-list tr").size).to eq(1)
        expect(page.text).not_to include(I18n.t("assessment.no_assignments_yet"))
      end
    end
  end

  context "with a seminar" do
    let(:seminar) { create(:lecture, sort: "seminar", teacher: teacher) }

    it "includes talks with speakers" do
      talk = create(:talk, lecture: seminar, title: "Talk 1")
      create(:speaker_talk_join, talk: talk)
      component = described_class.new(lecture: seminar)
      render_inline(component)
      expect(rendered_content).to include("Talk 1")
    end
  end
end
