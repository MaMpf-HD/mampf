require "rails_helper"

RSpec.describe(LectureAbility) do
  subject(:ability) { described_class.new(user) }

  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }

  it "allows subscribed students to self-materialize" do
    create(:lecture_user_join, user: user, lecture: lecture)

    expect(ability.can?(:self_materialize, lecture)).to be(true)
    expect(ability.can?(:enroll, lecture)).to be(true)
  end

  it "does not allow users who are not subscribed to the lecture" do
    expect(ability.can?(:self_materialize, lecture)).to be(false)
    expect(ability.can?(:enroll, lecture)).to be(false)
  end

  it "does not allow students subscribed to an unpublished lecture" do
    unpublished_lecture = create(:lecture)
    create(:lecture_user_join, user: user, lecture: unpublished_lecture)

    expect(ability.can?(:self_materialize, unpublished_lecture)).to be(false)
    expect(ability.can?(:enroll, unpublished_lecture)).to be(false)
  end

  it "does not allow lecture staff" do
    staff_lecture = create(:lecture, :released_for_all, teacher: user)
    create(:lecture_user_join, user: user, lecture: staff_lecture)

    expect(ability.can?(:self_materialize, staff_lecture)).to be(false)
    expect(ability.can?(:enroll, staff_lecture)).to be(false)
  end
end
