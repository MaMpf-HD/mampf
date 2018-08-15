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
      @preceding_course = FactoryBot.create(:course)
      @course = FactoryBot.create(:course)
      @another_course = FactoryBot.create(:course)
      @course.preceding_courses << @preceding_course
      @user = FactoryBot.create(:user)
      @user.update(courses: [@course])
    end
    context 'if subscription type is 1' do
      it 'gives the correct list of related courses' do
        @user.update(subscription_type: 1)
        expect(@user.related_courses.to_a).to match_array([@course, @preceding_course])
      end
    end
    context 'if subscription type is 2' do
      it 'gives the correct list of related lectures' do
        @user.update(subscription_type: 2)
        expect(@user.related_courses).to eq(Course.all)
      end
    end
    context 'if subscription type is 3' do
      it 'gives the correct list of related lectures' do
        @user.update(subscription_type: 3)
        expect(@user.related_courses.to_a).to match_array([@course])
      end
    end
  end
end
