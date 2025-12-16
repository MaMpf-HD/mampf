require "rails_helper"

# Missing top-level docstring, please formulate one yourself 😁
RSpec.describe(Registration::ItemsHelper, type: :helper) do
  describe "#format_capacity" do
    it "returns unlimited for nil capacity" do
      expect(helper.format_capacity(nil)).to eq(I18n.t("basics.unlimited"))
    end

    it "returns formatted string for integer capacity" do
      expect(helper.format_capacity(10)).to eq("10 #{I18n.t("basics.seats")}")
    end
  end
end
