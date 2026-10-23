require "rails_helper"

RSpec.describe(Registration::Participation) do
  let(:lecture) { create(:lecture, :released_for_all, teacher: create(:confirmed_user)) }

  it "lets a student take part" do
    expect(described_class.allowed?(create(:confirmed_user), lecture)).to be(true)
  end

  it "keeps the teacher out" do
    expect(described_class.allowed?(lecture.teacher, lecture)).to be(false)
  end

  it "keeps a tutor out" do
    tutor = create(:confirmed_user)
    create(:tutorial, lecture: lecture, tutors: [tutor])

    expect(described_class.allowed?(tutor, lecture)).to be(false)
  end

  # A tutor is one before having a tutorial.
  it "keeps out a tutor who has no tutorial yet" do
    tutor = create(:confirmed_user)
    TutorAppointment.create!(lecture: lecture, user: tutor)

    expect(described_class.allowed?(tutor, lecture)).to be(false)
  end

  # Running a flexible group is no reason to miss the lecture's tutorials
  # and exams.
  it "lets the tutor of a flexible group take part" do
    tutor = create(:confirmed_user)
    create(:cohort, context: lecture).tutors << tutor

    expect(described_class.allowed?(tutor, lecture)).to be(true)
  end

  it "keeps an editor out" do
    editor = create(:confirmed_user)
    lecture.editors << editor

    expect(described_class.allowed?(editor, lecture)).to be(false)
  end

  it "keeps everyone out while the lecture is unpublished" do
    unpublished = create(:lecture, released: nil)

    expect(described_class.allowed?(create(:confirmed_user), unpublished)).to be(false)
  end
end
