require "rails_helper"

RSpec.describe(Dashboard::Board) do
  describe "#staff_lectures" do
    let(:term) { create(:term, :summer, :active, year: 2025) }
    let(:user) { create(:user) }
    let(:board) { described_class.new(user: user, term: term) }

    it "includes taught and edited lectures, but not course-edited ones" do
      taught = create(:lecture, term: term, teacher: user)
      edited = create(:lecture, term: term)
      edited.editors << user
      course = create(:course)
      course.editors << user
      create(:lecture, term: term, course: course)

      expect(board.staff_lectures).to contain_exactly(taught, edited)
    end
  end

  describe "#tutored_lectures" do
    let(:term) { create(:term, :summer, :active) }
    let(:user) { create(:confirmed_user) }
    let(:board) { described_class.new(user: user, term: term) }

    # A tutor is one before having a tutorial: by a voucher or by address.
    it "includes the lectures the user tutors in, with or without a tutorial" do
      grouped = create(:lecture, term: term)
      create(:tutorial, lecture: grouped, tutors: [user])
      by_voucher = create(:lecture, term: term)
      Redemption.create!(voucher: create(:voucher, :tutor, lecture: by_voucher), user: user)
      by_address = create(:lecture, term: term)
      TutorAppointment.create!(lecture: by_address, user: user)
      with_cohort = create(:lecture, term: term)
      create(:cohort, context: with_cohort).tutors << user

      expect(board.tutored_lectures)
        .to contain_exactly(grouped, by_voucher, by_address, with_cohort)
    end

    # Running a flexible group keeps a student a student; one card is enough.
    it "leaves a flexible group's lecture to the enrolled ones when the user holds a place" do
      lecture = create(:lecture, term: term)
      create(:cohort, context: lecture).tutors << user
      create(:lecture_membership, user: user, lecture: lecture)

      expect(board.tutored_lectures).to be_empty
      expect(board.enrolled_lectures).to contain_exactly(lecture)
    end
  end

  describe "#enrolled_lectures" do
    let(:term) { create(:term, :summer, :active, year: 2025) }
    let(:user) { create(:user) }
    let(:board) { described_class.new(user: user, term: term) }

    it "includes lectures the user holds a roster seat in" do
      lecture = create(:lecture, term: term)
      create(:lecture_membership, user: user, lecture: lecture)

      expect(board.enrolled_lectures).to contain_exactly(lecture)
    end

    it "includes lectures the user is only in a non-propagating cohort of" do
      lecture = create(:lecture, term: term)
      cohort = create(:cohort, context: lecture, propagate_to_lecture: false)
      create(:cohort_membership, user: user, cohort: cohort)

      expect(board.enrolled_lectures).to contain_exactly(lecture)
    end

    it "does not count an exam registration as registering for the lecture" do
      lecture = create(:lecture, term: term)
      exam = create(:exam, :without_campaign, lecture: lecture)
      campaign = create(:registration_campaign, campaignable: lecture)
      item = create(:registration_item, registration_campaign: campaign,
                                        registerable: exam)
      campaign.update!(status: :open)
      create(:registration_user_registration, :pending,
             user: user, registration_campaign: campaign,
             registration_item: item)

      expect(board.enrolled_lectures).to be_empty
      expect(lecture.registration_status_for(user)).to be_nil
    end

    it "keeps such a lecture out of the bookmarked ones even when bookmarked" do
      lecture = create(:lecture, term: term)
      create(:lecture_membership, user: user, lecture: lecture)
      user.bookmark_lecture!(lecture)

      expect(board.bookmarked_lectures).to be_empty
    end

    it "includes a lecture with a pending registration but no roster seat" do
      lecture = create(:lecture, term: term)
      campaign = create(:registration_campaign, :open, campaignable: lecture)
      create(:registration_user_registration, :pending,
             user: user,
             registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      expect(board.enrolled_lectures).to contain_exactly(lecture)
    end

    it "includes a lecture with a rejected, not-yet-dismissed registration" do
      lecture = create(:lecture, term: term)
      campaign = create(:registration_campaign, :open, campaignable: lecture)
      create(:registration_user_registration, :rejected,
             user: user,
             registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      expect(board.enrolled_lectures).to contain_exactly(lecture)
    end

    it "excludes a lecture whose rejected registration was dismissed" do
      lecture = create(:lecture, term: term)
      campaign = create(:registration_campaign, :open, campaignable: lecture)
      create(:registration_user_registration, :rejected,
             user: user,
             registration_campaign: campaign,
             registration_item: campaign.registration_items.first,
             dismissed_at: Time.current)

      expect(board.enrolled_lectures).to be_empty
    end

    it "sorts settled lectures before pending, before rejected" do
      rejected_lecture = create(:lecture, term: term, course: create(:course, title: "Z Rejected"))
      rejected_campaign = create(:registration_campaign, :closed,
                                 campaignable: rejected_lecture)
      create(:registration_user_registration, :rejected,
             user: user, registration_campaign: rejected_campaign,
             registration_item: rejected_campaign.registration_items.first)

      pending_lecture = create(:lecture, term: term, course: create(:course, title: "A Pending"))
      pending_campaign = create(:registration_campaign, :open,
                                campaignable: pending_lecture)
      create(:registration_user_registration, :pending,
             user: user, registration_campaign: pending_campaign,
             registration_item: pending_campaign.registration_items.first)

      confirmed_lecture = create(:lecture, term: term,
                                           course: create(:course, title: "M Confirmed"))
      create(:lecture_membership, user: user, lecture: confirmed_lecture)

      expect(board.enrolled_lectures)
        .to eq([confirmed_lecture, pending_lecture, rejected_lecture])
    end
  end

  describe "talks" do
    let(:term) { create(:term, :summer, :active, year: 2025) }
    let(:user) { create(:user) }
    let(:board) { described_class.new(user: user, term: term) }
    let(:seminar) { create(:lecture, :released_for_all, sort: "seminar", term: term) }
    let!(:talk) { create(:talk, lecture: seminar, speaker_ids: [user.id]) }

    it "sits on its seminar's card, not on a card of its own" do
      create(:lecture_membership, user: user, lecture: seminar)

      expect(board.enrolled_lectures).to contain_exactly(seminar)
      expect(board.talks_for(seminar)).to eq([talk])
    end

    # Speakers of an older seminar may have no place on its roster.
    it "brings its seminar onto the board without a roster seat" do
      expect(board.enrolled_lectures).to contain_exactly(seminar)
    end

    it "sorts its seminar in with the others by title" do
      seminar.course.update!(title: "Algebra Seminar")
      later = create(:lecture, :released_for_all, term: term,
                                                  course: create(:course, title: "Zahlentheorie"))
      create(:lecture_membership, user: user, lecture: later)

      expect(board.enrolled_lectures).to eq([seminar, later])
    end

    it "does not show a seminar the user edits a second time" do
      seminar.editors << user

      expect(board.staff_lectures).to contain_exactly(seminar)
      expect(board.enrolled_lectures).to be_empty
    end
  end
end
