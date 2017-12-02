require 'rails_helper'

RSpec.describe "sections/show.html.erb", type: :view do
  it 'shows the correct title' do
    @section = FactoryBot.create(:section, number: 5, title: 'Star Wars')
    user = FactoryBot.create(:user)
    allow(view).to receive(:current_user).and_return(user)
    render
    expect(rendered).to match('§5. Star Wars')
  end
end
