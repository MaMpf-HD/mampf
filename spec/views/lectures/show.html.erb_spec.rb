require 'rails_helper'

RSpec.describe "lectures/show.html.erb", type: :view do
  it 'shows the correct title' do
    course = FactoryBot.create(:course, title: 'Star Wars')
    @lecture = FactoryBot.create(:lecture, course: course)
    user = FactoryBot.create(:user)
    allow(view).to receive(:current_user).and_return(user)
    render
    expect(rendered).to match('Star Wars')
  end
end
