require 'rails_helper'

RSpec.describe "lectures/show.html.erb", type: :view do
  it 'shows the correct title' do
    @lecture = FactoryBot.create(:lecture)
    user = FactoryBot.create(:user)
    allow(view).to receive(:current_user).and_return(user)
    render
    expect(rendered).to match(@lecture.course.title)
  end
end
