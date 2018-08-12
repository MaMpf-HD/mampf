require 'rails_helper'

RSpec.describe User, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:user)).to be_valid
  end
  it 'is given the default subscription type if subscription type is nil' do
    user = FactoryBot.create(:user)
    user.subscription_type = nil
    user.save
    expect(user.subscription_type).to eq(1)
  end
  it 'is given admin status false if admin is nil' do
    user = FactoryBot.create(:user)
    user.admin = nil
    user.save
    expect(user.admin).to be false
  end
  describe '#related_lectures' do
    before do
      @preceding_lecture = FactoryBot.create(:lecture)
      @lecture = FactoryBot.create(:lecture)
      @user = FactoryBot.create(:user)
      @user.update(lectures: [@lecture])
    end
    context 'if subscription type is 1' do
      it 'gives the correct list of related lectures' do
        @user.update(subscription_type: 1)
        expect(@user.related_lectures.to_a).to match_array([@lecture, @preceding_lecture])
      end
    end
    context 'if subscription type is 2' do
      it 'gives the correct list of related lectures' do
        @user.update(subscription_type: 2)
        expect(@user.related_lectures).to eq(Lecture.all)
      end
    end
    context 'if subscription type is 3' do
      it 'gives the correct list of related lectures' do
        @user.update(subscription_type: 3)
        expect(@user.related_lectures.to_a).to match_array([@lecture])
      end
    end
  end
end
