require "rails_helper"

RSpec.describe(ResultsReleaseComponent, type: :component) do
  around { |example| I18n.with_locale(:en) { example.run } }

  describe "for an exam" do
    let(:exam) { create(:exam) }
    let(:assessment) { exam.assessment }

    def row(**attributes)
      create(:assessment_participation, assessment: assessment, status: :reviewed,
                                        **attributes)
    end

    def confirm
      render_inline(described_class.new(exam: exam.reload))
        .at_css("form[method=post]:has(button.btn-primary)")["data-turbo-confirm"]
    end

    # Grades entered or applied before the points were corrected would reach
    # the students unnoticed.
    it "warns when grades differ from what the scheme gives now" do
      create(:assessment_grade_scheme, assessment: assessment)
      row(points_total: 50, grade_numeric: 5.0)
      row(points_total: 50, grade_numeric: 1.3)

      expect(confirm).to include("Careful: 1 grade differs from what the scheme gives now.")
    end

    it "warns about points without a grade" do
      row(points_total: 50)

      expect(confirm).to include("1 person has points but no grade.")
    end

    it "does not warn when every grade is in place" do
      row(points_total: 50, grade_numeric: 1.3)

      expect(confirm).not_to include("Careful")
      expect(confirm).not_to include("no grade")
    end
  end

  it "names a seminar's talks by what is published and what is ready" do
    seminar = create(:lecture, sort: "seminar")
    published = create(:talk, lecture: seminar, title: "Sylow theorems")
    ready = create(:talk, lecture: seminar, title: "Compilers")
    [published, ready].each do |talk|
      create(:assessment_participation, assessment: talk.assessment, status: :reviewed,
                                        grade_numeric: 2.0)
    end
    published.assessment.update!(results_published_at: Time.current)

    rendered = render_inline(described_class.new(seminar: seminar))

    expect(rendered.text.squish).to include("Published: Sylow theorems · Ready: Compilers")
    expect(rendered.css("button").map(&:text)).to eq(["Take back", "Publish 1 talk"])
  end
end
