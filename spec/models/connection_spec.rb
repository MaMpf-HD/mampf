require 'rails_helper'

RSpec.describe Connection, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:connection)).to be_valid
  end
  it 'destroys a connection if it is a self-connection' do
    lecture = FactoryBot.create(:lecture)
    connection = FactoryBot.create(:connection, lecture: lecture,
                                               preceding_lecture: lecture)
    id = connection.id
    expect(Connection.exists?(id)).to be false
  end
end
