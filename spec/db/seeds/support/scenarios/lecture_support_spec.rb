require "rails_helper"

# The demo data used to find its lecture at id 1, which held only because the
# shipped dump handed out that id. What these examples are about is that the
# lecture is found by what it is instead.
RSpec.describe(Demo::LectureSupport, type: :model) do
  let(:course) do
    create(:course, title: described_class::COURSE_TITLE, short_title: "LA 2")
  end

  describe ".find" do
    it "finds the demo course's lecture in the active term, whatever its id" do
      term = create(:term, :active)
      lecture = create(:lecture, course: course, term: term)

      expect(described_class.find).to eq(lecture)
    end

    it "ignores a lecture of another course in the same term" do
      term = create(:term, :active)
      create(:lecture, term: term)
      lecture = create(:lecture, course: course, term: term)

      expect(described_class.find).to eq(lecture)
    end

    # A build that has just moved the data forward leaves the course running in
    # a term that is not the active one.
    it "falls back to the latest term the course ran in" do
      create(:term, :active, year: 2030, season: "SS")
      create(:lecture, course: course, term: create(:term, year: 2019, season: "WS"))
      recent = create(:lecture, course: course,
                                term: create(:term, year: 2020, season: "SS"))

      expect(described_class.find).to eq(recent)
    end

    it "returns nothing when the demo course is not there" do
      expect(described_class.find).to be_nil
    end
  end

  describe ".find!" do
    it "says what is missing instead of handing back nothing" do
      expect { described_class.find! }
        .to raise_error(described_class::MISSING_LECTURE_MESSAGE)
    end
  end

  describe ".teacher!" do
    it "finds the account the demo data is taught by" do
      teacher = create(:confirmed_user, email: described_class::TEACHER_EMAIL)

      expect(described_class.teacher!).to eq(teacher)
    end

    it "says what is missing when that account is not there" do
      expect { described_class.teacher! }
        .to raise_error(described_class::MISSING_TEACHER_MESSAGE)
    end
  end
end
