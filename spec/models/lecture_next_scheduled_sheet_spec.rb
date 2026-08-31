require "rails_helper"

RSpec.describe(Lecture, type: :model) do
  # What the submissions card says when nothing is due. The date is not
  # guessed: it is what the lecturer set when scheduling the exercise medium.
  describe "#next_scheduled_sheet" do
    let(:lecture) { create(:lecture, :released_for_all) }

    def schedule(release_date:, title: "Homework 11", deadline: nil,
                 create_assignment: true)
      medium = create(:medium, :with_description, :with_editors,
                      sort: "Exercise", teachable: lecture)
      medium.update!(publisher: build(:medium_publisher,
                                      medium_id: medium.id,
                                      release_now: false,
                                      release_date: release_date,
                                      create_assignment: create_assignment,
                                      assignment_title: title,
                                      assignment_deadline: deadline))
      medium
    end

    it "is nil for a lecture with nothing scheduled" do
      expect(lecture.next_scheduled_sheet).to be_nil
    end

    it "carries the release date, the title and the deadline" do
      deadline = 3.weeks.from_now.change(usec: 0)
      release = 2.weeks.from_now.change(usec: 0)
      schedule(release_date: release, deadline: deadline)

      scheduled = lecture.next_scheduled_sheet

      expect(scheduled.release_date).to be_within(1.second).of(release)
      expect(scheduled.title).to eq("Homework 11")
      expect(scheduled.deadline).to be_within(1.second).of(deadline)
    end

    it "takes the soonest of several" do
      schedule(release_date: 3.weeks.from_now, title: "Homework 12")
      schedule(release_date: 1.week.from_now, title: "Homework 11")

      expect(lecture.next_scheduled_sheet.title).to eq("Homework 11")
    end

    # A medium scheduled for release without a sheet is not a sheet.
    it "ignores a release that creates no sheet" do
      schedule(release_date: 1.week.from_now, create_assignment: false)

      expect(lecture.next_scheduled_sheet).to be_nil
    end

    # Once the date has passed the sheet exists, so it is no longer scheduled.
    it "ignores a release date that has passed" do
      schedule(release_date: 1.week.ago)

      expect(lecture.next_scheduled_sheet).to be_nil
    end
  end
end
