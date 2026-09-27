require "rails_helper"

RSpec.describe(LectureAbility) do
  subject(:ability) { described_class.new(user) }

  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }

  describe "content pages of a lecture" do
    let(:actions) do
      [:show_announcements, :organizational, :show_random_quizzes, :display_course]
    end

    it "grants them to everybody for an unprotected lecture" do
      actions.each { |action| expect(ability.can?(action, lecture)).to be(true) }
    end

    it "grants them to an editor who has not bookmarked it" do
      lecture.editors << user

      actions.each { |action| expect(ability.can?(action, lecture)).to be(true) }
    end

    it "grants them to the teacher who has not bookmarked it" do
      lecture.update!(teacher: user)

      actions.each { |action| expect(ability.can?(action, lecture)).to be(true) }
    end

    context "with a passphrase-protected lecture" do
      let(:lecture) do
        create(:lecture, :released_for_all, passphrase: "secret")
      end

      it "grants them to a user who unlocked (bookmarked) it" do
        create(:lecture_bookmark, lecture: lecture, user: user)

        actions.each { |action| expect(ability.can?(action, lecture)).to be(true) }
      end

      it "grants them to an editor who has not unlocked it" do
        lecture.editors << user

        actions.each { |action| expect(ability.can?(action, lecture)).to be(true) }
      end

      it "denies them to everybody else" do
        actions.each { |action| expect(ability.can?(action, lecture)).to be(false) }
      end
    end

    it "denies them to everybody but the staff for an unpublished lecture" do
      unpublished_lecture = create(:lecture)

      actions.each do |action|
        expect(ability.can?(action, unpublished_lecture)).to be(false)
      end
    end
  end

  it "allows students to self-materialize for published lectures" do
    expect(ability.can?(:self_materialize, lecture)).to be(true)
    expect(ability.can?(:enroll, lecture)).to be(true)
  end

  it "does not require unlocking (registration is decoupled from " \
     "content access)" do
    passphrase_lecture = create(:lecture, :released_for_all,
                                passphrase: "secret")

    expect(ability.can?(:self_materialize, passphrase_lecture)).to be(true)
    expect(ability.can?(:enroll, passphrase_lecture)).to be(true)
  end

  it "does not allow students to self-materialize for unpublished lectures" do
    unpublished_lecture = create(:lecture)
    create(:lecture_bookmark, user: user, lecture: unpublished_lecture)

    expect(ability.can?(:self_materialize, unpublished_lecture)).to be(false)
    expect(ability.can?(:enroll, unpublished_lecture)).to be(false)
  end

  it "does not allow lecture staff" do
    staff_lecture = create(:lecture, :released_for_all, teacher: user)
    create(:lecture_bookmark, user: user, lecture: staff_lecture)

    expect(ability.can?(:self_materialize, staff_lecture)).to be(false)
    expect(ability.can?(:enroll, staff_lecture)).to be(false)
  end
end
