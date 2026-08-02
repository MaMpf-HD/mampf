require "rails_helper"

RSpec.describe(UserAbility) do
  subject(:ability) { described_class.new(user) }

  let(:user) { create(:confirmed_user) }
  let(:teacher) do
    create(:confirmed_user).tap { |u| create(:lecture, teacher: u) }
  end
  let(:other) { create(:confirmed_user) }

  describe ":image" do
    it "lets anyone view a teacher's profile image" do
      expect(ability.can?(:image, teacher)).to be(true)
    end

    it "lets a user view their own image" do
      expect(ability.can?(:image, user)).to be(true)
    end

    it "denies viewing another non-teacher's image" do
      expect(ability.can?(:image, other)).to be(false)
    end

    it "lets an admin view any image" do
      admin = create(:confirmed_user, admin: true)

      expect(described_class.new(admin).can?(:image, other)).to be(true)
    end

    it "lets an anonymous viewer see a teacher image without crashing" do
      anonymous = described_class.new(nil)

      expect(anonymous.can?(:image, teacher)).to be(true)
      expect(anonymous.can?(:image, other)).to be(false)
    end
  end
end
