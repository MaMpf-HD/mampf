require "rails_helper"

RSpec.describe(LectureAbility) do
  subject(:ability) { described_class.new(user) }

  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }

  describe "content pages of a lecture" do
    let(:actions) do
      [:show_announcements, :organizational, :show_random_quizzes, :display_course]
    end

    it "grants them to a subscriber" do
      create(:lecture_user_join, lecture: lecture, user: user)

      actions.each { |action| expect(ability.can?(action, lecture)).to be(true) }
    end

    it "grants them to an editor who is not subscribed" do
      lecture.editors << user

      actions.each { |action| expect(ability.can?(action, lecture)).to be(true) }
    end

    it "grants them to the teacher who is not subscribed" do
      lecture.update!(teacher: user)

      actions.each { |action| expect(ability.can?(action, lecture)).to be(true) }
    end

    it "denies them to everybody else" do
      actions.each { |action| expect(ability.can?(action, lecture)).to be(false) }
    end
  end

  it "allows students to self-materialize for published lectures" do
    expect(ability.can?(:self_materialize, lecture)).to be(true)
    expect(ability.can?(:enroll, lecture)).to be(true)
  end

  it "does not require a subscription (registration is decoupled from " \
     "content access)" do
    passphrase_lecture = create(:lecture, :released_for_all,
                                passphrase: "secret")

    expect(ability.can?(:self_materialize, passphrase_lecture)).to be(true)
    expect(ability.can?(:enroll, passphrase_lecture)).to be(true)
  end

  it "does not allow students to self-materialize for unpublished lectures" do
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
