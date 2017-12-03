require 'rails_helper'

RSpec.describe "teachers/show.html.erb", type: :view do
  it 'shows the correct title' do
    @teacher = FactoryBot.create(:teacher, name: 'Luke Skywalker')
    user = FactoryBot.create(:user)
    allow(view).to receive(:current_user).and_return(user)
    render
    expect(rendered).to match('Luke Skywalker')
  end
end
