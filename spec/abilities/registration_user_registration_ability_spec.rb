require "rails_helper"

RSpec.describe(RegistrationUserRegistrationAbility) do
  subject(:ability) { described_class.new(user) }

  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }

  it "allows students to view the home page of and register for " \
     "published lectures" do
    expect(ability.can?(:index, lecture)).to be(true)
    expect(ability.can?(:create, lecture)).to be(true)
    expect(ability.can?(:add, lecture)).to be(true)
  end

  it "does not require a subscription or passphrase (registration is " \
     "decoupled from content access)" do
    passphrase_lecture = create(:lecture, :released_for_all,
                                passphrase: "secret")

    expect(ability.can?(:index, passphrase_lecture)).to be(true)
    expect(ability.can?(:create, passphrase_lecture)).to be(true)
    expect(ability.can?(:add, passphrase_lecture)).to be(true)
  end

  it "does not allow students to access unpublished lectures" do
    unpublished_lecture = create(:lecture)
    create(:lecture_user_join, user: user, lecture: unpublished_lecture)

    expect(ability.can?(:index, unpublished_lecture)).to be(false)
    expect(ability.can?(:create, unpublished_lecture)).to be(false)
    expect(ability.can?(:add, unpublished_lecture)).to be(false)
  end

  it "allows lecture staff to view the home page but not to register" do
    staff_lecture = create(:lecture, teacher: user)

    expect(ability.can?(:index, staff_lecture)).to be(true)
    expect(ability.can?(:create, staff_lecture)).to be(false)
    expect(ability.can?(:add, staff_lecture)).to be(false)
  end
end
