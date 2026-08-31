require "rails_helper"

RSpec.describe(NoSheetDueComponent, type: :component) do
  def scheduled(title, release, deadline)
    Lecture::ScheduledSheet.new(release_date: release, title: title,
                                deadline: deadline)
  end

  around do |example|
    I18n.with_locale(:en) { example.run }
  end

  def render_block(**)
    render_inline(described_class.new(**))
    rendered_content
  end

  describe "what is coming" do
    # The date is not guessed: without one the block says so rather than
    # inventing a week.
    it "says so when nothing is scheduled" do
      content = render_block

      expect(content).to include(I18n.t("submission.hub.card.nothing_due"))
      expect(content)
        .to include(I18n.t("submission.hub.card.nothing_scheduled"))
    end

    it "names the sheet, when it appears and how long there will be for it" do
      release = Time.zone.local(2026, 9, 10, 14, 27)
      deadline = Time.zone.local(2026, 9, 17, 14, 27)

      content = render_block(next_scheduled: scheduled("Homework 11", release, deadline))

      expect(content).to include(
        I18n.t("submission.hub.card.appears_until",
               sheet: "Homework 11",
               date: I18n.l(release, format: :submission_deadline),
               deadline: I18n.l(deadline, format: :submission_deadline))
      )
    end

    it "leaves the deadline out when the lecturer set none" do
      release = Time.zone.local(2026, 9, 10, 14, 27)

      content = render_block(next_scheduled: scheduled("Homework 11", release, nil))

      expect(content).to include(
        I18n.t("submission.hub.card.appears", sheet: "Homework 11",
                                              date: I18n.l(release, format: :submission_deadline))
      )
    end
  end

  describe "what came back most recently" do
    let(:sheet) do
      instance_double(Assessment::SubmissionsHub::Sheet,
                      points: 6.5, max_points: 16, submission: nil,
                      assignment: instance_double(Assignment,
                                                  title: "Homework 8"))
    end

    it "names the sheet and spells its number out for a reader" do
      content = render_block(latest_marked: sheet)

      expect(content)
        .to include(I18n.t("submission.hub.card.marked_recently"))
      expect(content).to include("Homework 8")
      expect(content).to include(
        I18n.t("submission.hub.points_reader", points: "6.5", max: "16")
      )
    end

    it "says nothing about it while nothing has come back" do
      content = render_block

      expect(content)
        .not_to include(I18n.t("submission.hub.card.marked_recently"))
    end
  end
end
