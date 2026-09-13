require "rails_helper"
require Rails.root.join("db/seeds/support/extract_support")

# The extraction runs once against a seeded development database, which is not
# something an example can stand up. What these examples are about is the shape
# of what it writes: records named after what they are, references that carry a
# label instead of an id, and a row dropped rather than half-written when it
# points at something the extraction does not cover.
RSpec.describe(Seeds::ExtractSupport, type: :model) do
  let(:terms) { described_class.group("terms", Term) { |t| "#{t.season} #{t.year}" } }
  let(:users) { described_class.group("users", User) { |u| u.email.split("@").first } }
  let(:courses) { described_class.group("courses", Course, &:short_title) }
  let(:lectures) do
    described_class.group("lectures", Lecture) { |l| l.course.short_title }
  end
  let(:media) { described_class.group("media", Medium) { "medium" } }
  # Everything a lecture points at, so that a row is only dropped where an
  # example is about a row being dropped.
  let(:lecture_labels) { labels_for(terms, users, courses, lectures) }

  def labels_for(*groups)
    groups.to_h { |group| [group.model.table_name, described_class.labels_for(group)] }
  end

  describe ".labels_for" do
    it "names a record after what it is" do
      term = create(:term, year: 2026, season: "SS")

      expect(described_class.labels_for(terms)).to eq(term.id => "ss_2026")
    end

    it "counts out a name two records share" do
      first = create(:term, year: 2026, season: "SS")
      second = create(:term, year: 2027, season: "SS")
      group = described_class.group("terms", Term) { "SS" }

      expect(described_class.labels_for(group))
        .to eq(first.id => "ss", second.id => "ss_2")
    end
  end

  describe ".attributes_for" do
    it "writes a reference as the file and label it points at" do
      term = create(:term, year: 2026, season: "SS")
      lecture = create(:lecture, term: term, course: create(:course, short_title: "LA 2"))

      attributes = described_class.attributes_for(lecture, lectures, lecture_labels)

      expect(attributes["term"]).to eq("terms/ss_2026")
    end

    # Half a row is worse than none: a teacher the extraction leaves out would
    # otherwise land in the file as a lecture without one.
    it "drops a row that points at a record the extraction does not cover" do
      create(:lecture, course: create(:course, short_title: "LA 2"))
      lecture = create(:lecture, course: create(:course, short_title: "LA 1"))

      attributes = described_class.attributes_for(lecture, lectures,
                                                  labels_for(terms, courses, lectures))

      expect(attributes).to eq(:incomplete)
    end

    it "leaves the primary key and the timestamps out" do
      term = create(:term, year: 2026, season: "SS")

      attributes = described_class.attributes_for(term, terms, labels_for(terms))

      expect(attributes.keys).to contain_exactly("year", "season")
    end

    # The file itself is not the data file's business, but which record wants
    # one is.
    it "lists an attachment by the name of the file it was uploaded as" do
      medium = create(:valid_medium)
      # rubocop:disable Rails/SkipsModelValidations
      medium.update_column(:video_data,
                           { "id" => "abc", "storage" => "store",
                             "metadata" => { "filename" => "LA2.E01.mp4" } }.to_json)
      # rubocop:enable Rails/SkipsModelValidations

      attributes = described_class.attributes_for(medium.reload, media,
                                                  labels_for(lectures))

      expect(attributes["attachments"]).to eq("video" => "LA2.E01.mp4")
    end

    # A quiz graph is an object of the app's own, which the column holds as
    # serialized Ruby. There is no readable form of it to write, so what the
    # database holds is carried over as the blob it is.
    it "carries a column the app stores as serialized Ruby over verbatim" do
      quiz = create(:valid_quiz, :with_quiz_graph, teachable_sort: :lecture)
      serialized = quiz.read_attribute_before_type_cast("quiz_graph")

      attributes = described_class.attributes_for(quiz, media, labels_for(lectures))

      expect(attributes["quiz_graph"]).to eq("serialized" => serialized)
    end
  end

  describe ".write!" do
    let(:directory) { Dir.mktmpdir }

    after { FileUtils.remove_entry(directory) }

    it "writes a mapping of labels for a group other records refer to" do
      create(:term, year: 2026, season: "SS")

      described_class.write!(terms, labels_for(terms), directory)

      expect(YAML.load_file(File.join(directory, "terms.yml")))
        .to eq("ss_2026" => { "year" => 2026, "season" => "SS" })
    end

    it "writes a plain sequence for a group nothing refers to" do
      tag = create(:tag)
      create(:medium_tag_join, medium: create(:valid_medium), tag: tag)
      tags = described_class.group("tags", Tag) { "tag" }
      joins = described_class.group("medium_tag_joins", MediumTagJoin, list: true)

      report = described_class.write!(joins, labels_for(media, tags), directory)

      expect(YAML.load_file(File.join(directory, "medium_tag_joins.yml")))
        .to eq([{ "medium" => "media/medium", "tag" => "tags/tag" }])
      expect(report[:written]).to eq(1)
    end

    it "counts the rows it had to drop" do
      create(:lecture, course: create(:course, short_title: "LA 2"))

      report = described_class.write!(lectures, labels_for(terms, courses, lectures),
                                      directory)

      expect(report).to include(written: 0, skipped: 1)
    end
  end
end
