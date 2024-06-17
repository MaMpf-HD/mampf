require "rails_helper"

RSpec.describe(User, type: :model) do
  it "has a valid factory" do
    expect(FactoryBot.build(:user)).to be_valid
  end

  # test validations - SOME ARE MISSING

  it "is invalid if it is persisted and no name is given" do
    user = FactoryBot.create(:confirmed_user)
    user.name = nil
    expect(user).not_to be_valid
  end

  it "is invalid if homepage is given but with an invalid url" do
    user = FactoryBot.build(:confirmed_user)
    user.homepage = "usual_bs"
    expect(user).not_to be_valid
  end

  # test traits and subfactories

  describe "confirmed user" do
    it "has a valid factory for building" do
      expect(FactoryBot.build(:confirmed_user)).to be_valid
    end
    it "has a valid factory for creating" do
      expect(FactoryBot.create(:confirmed_user)).to be_valid
    end
    it "is confirmed when created" do
      expect(FactoryBot.create(:confirmed_user).confirmed_at).not_to be_nil
    end
  end

  describe "user with subscribed lectures" do
    before :each do
      @user = FactoryBot.build(:user, :with_lectures)
    end
    it "has a valid factory" do
      expect(@user).to be_valid
    end
    it "has subscribed lectures" do
      expect(@user.lectures).not_to be_nil
    end
    it "has 2 subscribed lectures when called without lecture_count param" do
      expect(@user.lectures.size).to eq(2)
    end
    it "has correct number of lectures when called with lecture_count param" do
      user = FactoryBot.build(:user, :with_lectures, lecture_count: 3)
      expect(user.lectures.size).to eq(3)
    end
  end

  # test callbacks - NEEDS TO BE REFACTORED

  # it 'is given the default subscription type if subscription type is nil' do
  #   user = FactoryBot.create(:confirmed_user)
  #   user.subscription_type = nil
  #   user.save
  #   expect(user.subscription_type).to eq(1)
  # end
  # it 'is given admin status false if admin is nil' do
  #   user = FactoryBot.create(:confirmed_user)
  #   user.admin = nil
  #   user.save
  #   expect(user.admin).to be false
  # end

  # test methods - NEEDS TO BE REFACTORED

  # describe '#related_lectures' do
  #   before :each do
  #     @preceding_course = FactoryBot.create(:course)
  #     @course = FactoryBot.create(:course)
  #     @lecture = FactoryBot.create(:lecture, course: @course)
  #     @another_course = FactoryBot.create(:course)
  #     @course.preceding_courses << @preceding_course
  #     @user = FactoryBot.create(:confirmed_user)
  #     @user.update(lectures: [@lecture])
  #   end
  #   context 'if subscription type is 1' do
  #     it 'gives the correct list of related courses' do
  #       @user.update(subscription_type: 1)
  #       expect(@user.related_courses.to_a)
  #         .to match_array([@course, @preceding_course])
  #     end
  #   end
  #   context 'if subscription type is 2' do
  #     it 'gives the correct list of related lectures' do
  #       @user.update(subscription_type: 2)
  #       expect(@user.related_courses).to eq(Course.all)
  #     end
  #   end
  #   context 'if subscription type is 3' do
  #     it 'gives the correct list of related lectures' do
  #       @user.update(subscription_type: 3)
  #       expect(@user.related_courses.to_a).to match_array([@course])
  #     end
  #   end
  # end

  describe("#destroy_talk_media") do
    let(:medium) do
      medium = FactoryBot.build(:medium)
      medium.teachable_type = "Lecture"
      medium.save(validate: false)
      medium
    end

    let(:medium_talk) do
      medium = FactoryBot.build(:medium)
      medium.teachable_type = "Talk"
      medium.save(validate: false)
      medium
    end

    context("when user is destroyed") do
      it("method is called") do
        user = FactoryBot.create(:confirmed_user)
        expect(user).to receive(:destroy_talk_media_upon_user_deletion)
        user.destroy
      end

      context("when user self-deletes (archive & destroy)") do
        it("method is not called") do
          user = FactoryBot.create(:confirmed_user)
          expect(user).not_to receive(:destroy_talk_media_upon_user_deletion)
          user.archive_and_destroy("dummy archive user name")
        end
      end
    end

    context("when user has media other than talk media") do
      it("does not destroy any media") do
        user = FactoryBot.create(:confirmed_user)
        medium
        medium_talk

        # use .send(:...) to access private method
        expect { user.send(:destroy_talk_media_upon_user_deletion) }
          .not_to(change { Medium.count })
      end
    end

    context("when user has only talk media") do
      it("does not destroy talk media that has multiple editors") do
        user = FactoryBot.create(:confirmed_user)
        user2 = FactoryBot.create(:confirmed_user)
        medium_talk.editors << user
        medium_talk.editors << user2

        expect { user.send(:destroy_talk_media_upon_user_deletion) }
          .not_to(change { Medium.count })
      end

      it("destroys talk media that has only one editor") do
        user = FactoryBot.create(:confirmed_user)
        medium_talk.editors << user

        expect { user.send(:destroy_talk_media_upon_user_deletion) }
          .to(change { Medium.count }.by(-1)
          .and(change { Medium.exists?(medium_talk.id) }.from(true).to(false)))
      end
    end
  end
end
