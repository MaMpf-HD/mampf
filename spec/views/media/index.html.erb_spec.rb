require 'rails_helper'

RSpec.describe "media/show.html.erb", type: :view do
  it 'displays correct information' do
    lecture = FactoryBot.create(:lecture)
    @medium = FactoryBot.create(:medium, teachable: lecture)
    user = FactoryBot.create(:user)
    allow(view).to receive(:current_user).and_return(user)
    render
    expect(rendered).to match(lecture.title)
  end
end
