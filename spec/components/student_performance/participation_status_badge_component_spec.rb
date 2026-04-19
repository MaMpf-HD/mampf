require "rails_helper"

RSpec.describe(
  ParticipationStatusBadgeComponent,
  type: :component
) do
  describe "full variant" do
    it "renders reviewed with success styling" do
      render_inline(described_class.new(status: :reviewed, variant: :full))
      expect(rendered_content).to include("text-success")
      expect(rendered_content).to include("bi-check-circle-fill")
      expect(rendered_content).to include(
        I18n.t("student_performance.records.columns.reviewed")
      )
    end

    it "renders pending_grading with warning styling" do
      render_inline(described_class.new(
                      status: :pending_grading, variant: :full
                    ))
      expect(rendered_content).to include("text-warning")
      expect(rendered_content).to include("bi-hourglass-split")
    end

    it "renders not_submitted with danger styling" do
      render_inline(described_class.new(
                      status: :not_submitted, variant: :full
                    ))
      expect(rendered_content).to include("text-danger")
      expect(rendered_content).to include("bi-x-circle-fill")
    end

    it "renders exempt with secondary styling" do
      render_inline(described_class.new(status: :exempt, variant: :full))
      expect(rendered_content).to include("text-secondary")
      expect(rendered_content).to include("bi-dash-circle")
    end

    it "renders absent with secondary styling" do
      render_inline(described_class.new(status: :absent, variant: :full))
      expect(rendered_content).to include("text-secondary")
      expect(rendered_content).to include("bi-person-slash")
    end
  end

  describe "compact variant" do
    it "renders reviewed as numeric points" do
      render_inline(described_class.new(
                      status: :reviewed, variant: :compact, points: 8.5
                    ))
      expect(rendered_content).to match(/8[.,]5/)
    end

    it "renders pending_grading as dash" do
      render_inline(described_class.new(
                      status: :pending_grading, variant: :compact
                    ))
      expect(rendered_content).to include("text-warning")
    end

    it "renders not_submitted as cross mark" do
      render_inline(described_class.new(
                      status: :not_submitted, variant: :compact
                    ))
      expect(rendered_content).to include("text-muted")
    end
  end

  describe "#tooltip" do
    it "returns points tooltip for reviewed status" do
      component = described_class.new(
        status: :reviewed, variant: :compact, points: 7
      )
      tip = component.tooltip("Homework 1") { 10 }
      expect(tip).to include("Homework 1")
      expect(tip).to include("7")
      expect(tip).to include("10")
    end

    it "returns label tooltip for non-reviewed status" do
      component = described_class.new(
        status: :not_submitted, variant: :compact
      )
      tip = component.tooltip("Homework 2")
      expect(tip).to include("Homework 2")
      expect(tip).to include(
        I18n.t("student_performance.records.columns.not_submitted")
      )
    end
  end
end
