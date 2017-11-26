require 'rails_helper'

RSpec.describe "chapters/show.html.erb", type: :view do
  it 'shows the correct title' do
    assign(:chapter, FactoryBot.create(:chapter, title: 'Star Wars', number: 5))
    render
    expect(rendered).to match('Kapitel 5. Star Wars')
  end
end
