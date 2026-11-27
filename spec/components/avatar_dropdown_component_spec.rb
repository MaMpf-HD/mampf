require "rails_helper"

# Only the cases the e2e specs can't reach: single-role users (there are no
# such Playwright fixtures), prefix matching of the active item and the
# production guard of the dev user switcher.
RSpec.describe(AvatarDropdownComponent, type: :component) do
  around { |example| I18n.with_locale(:en) { example.run } }

  def render_menu(user, path: "/")
    vc_test_request.path_info = path
    render_inline(described_class.new(user: user))
  end

  def link_labels(user)
    render_menu(user).css("a.dropdown-item").map { |link| link.text.strip }
  end

  it "shows the role links only to users having the role" do
    support_labels = link_labels(build(:user, support: true))
    expect(support_labels).to include("Support")
    expect(support_labels).not_to include("Dean's office", "Administration")

    deans_office_labels = link_labels(build(:user, deans_office: true))
    expect(deans_office_labels).to include("Dean's office")
    expect(deans_office_labels).not_to include("Support", "Administration")
  end

  it "marks the watchlists link as active on a single watchlist" do
    active = render_menu(build(:user), path: "/watchlists/1").css("a.active")

    expect(active.map { |link| link.text.strip }).to eq(["My Watchlists"])
    expect(active.first["aria-current"]).to eq("page")
  end

  it "hides the user switcher outside of development and test" do
    allow(Rails.env).to receive(:local?).and_return(false)

    menu = render_menu(build(:user))

    expect(menu.css("[data-controller~='impersonate-list']")).to be_empty
    expect(menu.text).not_to include("Switch user")
  end
end
