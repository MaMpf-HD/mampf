require 'rails_helper'

RSpec.describe "profile/edit.html.erb", type: :view do
  it 'shows the correct profile' do
    lecture = FactoryBot.create(:lecture)
    @user = FactoryBot.create(:user, lectures: [lecture])
    allow(view).to receive(:current_user).and_return(@user)
    render
    expect(rendered).to match(lecture.to_label)
  end
end
