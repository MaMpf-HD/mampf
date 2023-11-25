# frozen_string_literal: true

require "rails_helper"

RSpec.describe MediumPublisher, type: :model do
  it "has a factory" do
    expect(FactoryBot.build(:medium_publisher)).to be_kind_of(MediumPublisher)
  end

  it "serializes and deserializes without errors" do
    medium = FactoryBot.create(:course_medium)
    publisher = FactoryBot.build(:medium_publisher, medium_id: medium.id)
    medium.publisher = publisher
    medium.save
  end

  describe "::parse" do
    before :all do
      @medium = FactoryBot.create(:lecture_medium)
      @user = FactoryBot.create(:confirmed_user)
    end

    it "parses correctly (example 1)" do
      params = { release_now: "1", released: "all",
                 release_date: "", lock_comments: "1",
                 publish_vertices: "0", create_assignment: "0" }
      publisher = MediumPublisher.parse(@medium, @user, params)
      comp_methods = [:release_now, :release_for, :release_date, :lock_comments,
                      :vertices, :create_assignment]
      publisher_array = comp_methods.map { |m| publisher.send(m) }
      expect(publisher_array)
        .to eq([true, "all", nil, true,
                false, false])
    end

    it "parses correctly (example 2)" do
      params = { release_now: "0", released: "users",
                 release_date: "04-03-2021 13:50", lock_comments: "0",
                 publish_vertices: "1", create_assignment: "1",
                 assignment_title: "Blatt 1", assignment_file_type: ".pdf",
                 assignment_deadline: "04-03-2021 14:50",
                 assignment_deletion_date: "04-03-2021" }
      publisher = MediumPublisher.parse(@medium, @user, params)
      comp_methods = [:release_now, :release_for, :release_date, :lock_comments,
                      :vertices, :create_assignment, :assignment_title,
                      :assignment_file_type, :assignment_deadline,
                      :assignment_deletion_date]
      publisher_array = comp_methods.map { |m| publisher.send(m) }
      expect(publisher_array)
        .to eq([false, "users", Time.zone.parse("04-03-2021 13:50"), false,
                true, true, "Blatt 1", ".pdf",
                Time.zone.parse("04-03-2021 14:50"), Time.zone.parse("04-03-2021")])
    end

    it "rescues argument errors for the release date" do
      params = { release_now: "1", released: "all",
                 release_date: "w47qwhhhhkc4", lock_comments: "1",
                 publish_vertices: "0", create_assignment: "0" }
      publisher = MediumPublisher.parse(@medium, @user, params)
      expect(publisher.release_date).to be_nil
    end

    it "rescues argument errors for the assignment deadline" do
      params = { release_now: "0", released: "all",
                 release_date: "04-03-2021 13:50", lock_comments: "1",
                 publish_vertices: "0", create_assignment: "1",
                 assignment_deadline: "w47qwhhhhkc4" }
      publisher = MediumPublisher.parse(@medium, @user, params)
      expect(publisher.assignment_deadline).to be_nil
    end

    it "rescues argument errors for the assignment deletion date" do
      params = { release_now: "0", released: "all",
                 release_date: "04-03-2021 13:50", lock_comments: "1",
                 publish_vertices: "0", create_assignment: "1",
                 assignment_deletion_date: "w47qwhhhhkc4" }
      publisher = MediumPublisher.parse(@medium, @user, params)
      expect(publisher.assignment_deletion_date).to be_nil
    end
  end

  describe "#publish!" do
    context "without extra stuff" do
      before :all do
        @medium = FactoryBot.create(:lecture_medium)
        lecture = @medium.teachable
        lecture.update(released: "all")
        @user = FactoryBot.create(:confirmed_user, email_for_medium: true)
        @medium.editors << @user
        @user.lectures << lecture
        publisher = FactoryBot.build(:medium_publisher,
                                     medium_id: @medium.id,
                                     user_id: @user.id)
        publisher.publish!
        @medium.reload
      end

      it "publishes the medium" do
        expect(@medium.released).to eq "all"
      end

      it "sets a released_at date" do
        expect(@medium.released_at).not_to be nil
      end

      it "creates notifications" do
        expect(@user.notifications.size).to eq 1
      end
    end

    it "publishes the vertices if medium is a quiz and vertices flag is set" do
      medium = FactoryBot.create(:valid_quiz, :with_quiz_graph,
                                 teachable_sort: :lecture)
      lecture = medium.teachable
      lecture.update(released: "all")
      user = FactoryBot.create(:confirmed_user, email_for_medium: true)
      medium.editors << user
      user.lectures << lecture
      lecture.editors << user
      # rubocop:todo Rails/SkipsModelValidations
      medium.questions.update_all(teachable_type: "Lecture",
                                  # rubocop:enable Rails/SkipsModelValidations
                                  teachable_id: lecture.id)
      publisher = FactoryBot.build(:medium_publisher,
                                   medium_id: medium.id,
                                   user_id: user.id,
                                   vertices: true)
      medium.update(publisher:)
      publisher.publish!
      expect(medium.questions.map(&:released).uniq).to eq(["all"])
    end

    it "creates an assignment if the create_assignment flag is set" do
      medium = FactoryBot.create(:lecture_medium)
      lecture = medium.teachable
      user = FactoryBot.create(:confirmed_user)
      medium.editors << user
      publisher = FactoryBot.build(:medium_publisher,
                                   medium_id: medium.id,
                                   user_id: user.id,
                                   create_assignment: true,
                                   assignment_title: "Blatt 1",
                                   assignment_deadline: "2025-05-02 12:00",
                                   assignment_deletion_date: "2025-05-02",
                                   assignment_file_type: ".pdf")
      publisher.publish!
      lecture.reload
      expect(lecture.assignments.size).to eq 1
    end

    it "locks the medium thread if the lock_assignment flag is set" do
      medium = FactoryBot.create(:lecture_medium)
      user = FactoryBot.create(:confirmed_user)
      medium.editors << user
      publisher = FactoryBot.build(:medium_publisher,
                                   medium_id: medium.id,
                                   user_id: user.id,
                                   lock_comments: true)
      publisher.publish!
      expect(medium.commontator_thread.reload.closed_at).not_to be_nil
    end

    # TODO: check if emails are sent out
  end

  describe "#assignment" do
    before :all do
      @medium = FactoryBot.create(:lecture_medium)
      @lecture = @medium.teachable
      user = FactoryBot.create(:confirmed_user)
      @medium.editors << user
      @publisher = FactoryBot.build(:medium_publisher,
                                    medium_id: @medium.id,
                                    user_id: user.id,
                                    create_assignment: true,
                                    assignment_title: "Blatt 1",
                                    assignment_deadline:
                                     Time.zone.parse("2025-05-02 12:00"),
                                    assignment_deletion_date:
                                     Time.zone.parse("2025-05-02"),
                                    assignment_file_type: ".pdf")
    end

    it "returns an assignment" do
      expect(@publisher.assignment).to be_kind_of(Assignment)
    end

    it "builds the correspnding assignment if the create_assignment flag is " \
       "set" do
      assignment = @publisher.assignment
      expect([assignment.medium, assignment.lecture, assignment.title,
              assignment.deadline, assignment.accepted_file_type])
        .to eq([@medium, @lecture, "Blatt 1",
                Time.zone.parse("2025-05-02 12:00"), ".pdf"])
    end
  end

  describe "#errors" do
    before :all do
      @medium = FactoryBot.create(:lecture_medium)
      @user = FactoryBot.create(:confirmed_user)
    end

    it "returns {} if  there are no errors (example 1)" do
      publisher = FactoryBot.build(:medium_publisher,
                                   medium_id: @medium.id,
                                   user_id: @user.id,
                                   release_now: true,
                                   create_assignment: false)
      expect(publisher.errors).to eq({})
    end

    it "returns {} if  there are no errors (example 2)" do
      publisher = FactoryBot.build(:medium_publisher,
                                   medium_id: @medium.id,
                                   user_id: @user.id,
                                   release_now: false,
                                   release_date: 1.day.from_now,
                                   create_assignment: true,
                                   assignment_title: "Blatt 1",
                                   assignment_file_type: ".pdf",
                                   assignment_deadline: 2.days.from_now,
                                   assignment_deletion_date: Time.zone.today + 2.days)
      expect(publisher.errors).to eq({})
    end

    it "returns a release date error if release is scheduled later but " \
       "no release date is set" do
      publisher = FactoryBot.build(:medium_publisher,
                                   medium_id: @medium.id,
                                   user_id: @user.id,
                                   release_now: false,
                                   release_date: nil)
      expect(publisher.errors[:release_date]).not_to be_nil
    end

    it "returns a release date error if release is scheduled later but " \
       "release date is in the past" do
      publisher = FactoryBot.build(:medium_publisher,
                                   medium_id: @medium.id,
                                   user_id: @user.id,
                                   release_now: false,
                                   release_date: 1.day.ago)
      expect(publisher.errors[:release_date]).not_to be_nil
    end

    it "returns an assignment deadline error if release is scheduled now " \
       "and deadline is in the past" do
      publisher = FactoryBot.build(:medium_publisher,
                                   medium_id: @medium.id,
                                   user_id: @user.id,
                                   release_now: true,
                                   create_assignment: true,
                                   assignment_deadline: 1.day.ago)
      expect(publisher.errors[:assignment_deadline]).not_to be_nil
    end

    it "returns an assignment deletion date error if release is scheduled now " \
       "and deletion date is in the past" do
      publisher = FactoryBot.build(:medium_publisher,
                                   medium_id: @medium.id,
                                   user_id: @user.id,
                                   release_now: true,
                                   create_assignment: true,
                                   assignment_deletion_date:
                                    Time.zone.today - 1.day)
      expect(publisher.errors[:assignment_deletion_date]).not_to be_nil
    end

    it "returns an assignment deadline error if release is scheduled later " \
       "and deadline is before that" do
      publisher = FactoryBot.build(:medium_publisher,
                                   medium_id: @medium.id,
                                   user_id: @user.id,
                                   release_now: false,
                                   release_date: 2.days.from_now,
                                   create_assignment: true,
                                   assignment_deadline: 1.day.from_now)
      expect(publisher.errors[:assignment_deadline]).not_to be_nil
    end

    it "returns an assignment title error if assignment is to be created but " \
       "no title is given" do
      publisher = FactoryBot.build(:medium_publisher,
                                   medium_id: @medium.id,
                                   user_id: @user.id,
                                   release_now: true,
                                   create_assignment: true,
                                   assignment_title: "")
      expect(publisher.errors[:assignment_title]).not_to be_nil
    end

    it "returns an assignment title error if assignment is to be created but " \
       "title of an already existing assignment in the lecture is given" do
      Assignment.create(lecture: @medium.teachable, medium: @medium,
                        title: "Blatt 1", deadline: 1.day.from_now,
                        accepted_file_type: ".pdf")
      publisher = FactoryBot.build(:medium_publisher,
                                   medium_id: @medium.id,
                                   user_id: @user.id,
                                   release_now: true,
                                   create_assignment: true,
                                   assignment_title: "Blatt 1",
                                   assignment_deadline: 2.days.from_now,
                                   assignment_deletion_date: Time.zone.today + 2.days,
                                   assignment_file_type: ".pdf")
      expect(publisher.errors[:assignment_title]).not_to be_nil
    end
  end
end
