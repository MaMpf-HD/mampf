require "rails_helper"

RSpec.describe(PlaceholderTabComponent, type: :component) do
  let(:message) { "Statistics are not yet available" }
  let(:component) { described_class.new(message: message) }

  it "renders the message" do
    render_inline(component)
    expect(rendered_content).to include(message)
  end

  it "renders the coming soon label" do
    render_inline(component)
    expect(rendered_content).to include(I18n.t("basics.coming_soon"))
  end

  it "renders an info alert" do
    render_inline(component)
    expect(rendered_content).to include("alert-info")
  end

  it "renders the info icon" do
    render_inline(component)
    expect(rendered_content).to include("bi-info-circle")
  end
end
