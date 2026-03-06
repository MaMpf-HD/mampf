require "rails_helper"

RSpec.describe(AchievementDashboardComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let!(:achievement) do
    create(:achievement, lecture: lecture, title: "Blackboard Talk")
  end

  let(:component) do
    described_class.new(achievement: achievement, lecture: lecture)
  end

  describe "rendering" do
    before { render_inline(component) }

    it "renders the achievement title" do
      expect(rendered_content).to include("Blackboard Talk")
    end

    it "renders a back link" do
      expect(rendered_content).to include(I18n.t("back"))
      expect(rendered_content).to include("tab=achievements")
    end

    it "renders the settings tab" do
      expect(rendered_content).to include(
        "data-bs-target=\"##{component.dom_prefix}-settings\""
      )
    end
  end

  describe "#tabs" do
    it "returns only settings" do
      keys = component.tabs.map(&:key)
      expect(keys).to eq(["settings"])
    end
  end

  describe "#dom_prefix" do
    it "includes the achievement id" do
      expect(component.dom_prefix).to eq(
        "dashboard-achievement-#{achievement.id}"
      )
    end
  end

  describe "#back_path" do
    it "points to the assessments overview with achievements tab" do
      render_inline(component)
      expect(component.back_path).to include("tab=achievements")
    end
  end

  describe "#tab_active?" do
    it "defaults to settings" do
      expect(component.tab_active?("settings")).to be(true)
    end

    it "respects active_tab param" do
      c = described_class.new(
        achievement: achievement, lecture: lecture,
        active_tab: "other"
      )
      expect(c.tab_active?("settings")).to be(false)
      expect(c.tab_active?("other")).to be(true)
    end
  end
end
