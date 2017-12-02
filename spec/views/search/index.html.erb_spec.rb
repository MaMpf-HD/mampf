require 'rails_helper'

RSpec.describe "search/index.html.erb", type: :view do
  it 'renders correctly' do
    @search_string = 'Spezialsuche'
    @tags = FactoryBot.create_list(:tag, 2)
    user = FactoryBot.create(:user)
    allow(view).to receive(:current_user).and_return(user)
    render
    expect(rendered).to match('Spezialsuche')
  end
end
