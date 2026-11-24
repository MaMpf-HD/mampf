require "rails_helper"

RSpec.describe(AvatarDropdownComponent, type: :component) do
  around { |example| I18n.with_locale(:en) { example.run } }

  def render_menu(user, path: "/")
    vc_test_request.path_info = path
    render_inline(described_class.new(user: user))
  end

  def link_labels(user)
    render_menu(user).css("a.dropdown-item").map { |link| link.text.strip }
  end

  it "shows the personal links and the logout link" do
    expect(link_labels(build(:user)))
      .to eq(["Profile", "My Annotations", "My Watchlists", "Logout"])
  end

  it "shows the role links only to users having the role" do
    support_labels = link_labels(build(:user, support: true))
    expect(support_labels).to include("Support")
    expect(support_labels).not_to include("Dean's office", "Administration")

    deans_office_labels = link_labels(build(:user, deans_office: true))
    expect(deans_office_labels).to include("Dean's office")
    expect(deans_office_labels).not_to include("Support", "Administration")

    expect(link_labels(build(:user, admin: true)))
      .to include("Support", "Dean's office", "Administration")
  end

  it "marks the link of the current page as active" do
    active = render_menu(build(:user), path: "/watchlists/1").css("a.active")

    expect(active.map { |link| link.text.strip }).to eq(["My Watchlists"])
    expect(active.first["aria-current"]).to eq("page")
  end
end
