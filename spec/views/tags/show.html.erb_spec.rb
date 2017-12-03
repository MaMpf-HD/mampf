require 'rails_helper'

RSpec.describe "tags/show.html.erb", type: :view do
  it 'shows the correct title' do
    @tag = FactoryBot.create(:tag, title: 'Star Wars')
    user = FactoryBot.create(:user)
    allow(view).to receive(:current_user).and_return(user)
    render
    expect(rendered).to match('Star Wars')
  end
end
