require "rails_helper"

# The loader is exercised against small, synthetic data files rather than the
# real db/seeds/data -- these examples are about how a group of records is
# built (references, translations, dates, the columns that need special
# handling), not about the content the shipped seed happens to carry.
RSpec.describe(Seeds::LoadSupport, type: :model) do
  include ActiveSupport::Testing::TimeHelpers

  let(:directory) { Pathname.new(Dir.mktmpdir) }

  after { FileUtils.remove_entry(directory) }

  # Writes with string keys throughout, like the real extraction does --
  # symbol keys would round-trip through YAML as `!ruby/symbol`, which
  # Psych.safe_load (rightly) refuses to load back.
  def write(name, content)
    File.write(directory.join("#{name}.yml"), YAML.dump(content.deep_stringify_keys))
  end

  def write_list(name, rows)
    File.write(directory.join("#{name}.yml"), YAML.dump(rows.map(&:deep_stringify_keys)))
  end

  # Every group needs a file to exist (the loader always walks the full list),
  # so examples start from an all-empty set and only fill in what they test.
  def write_empty_groups!(active_term: "SS 2026")
    described_class.groups.each do |group|
      group.list ? write_list(group.name, []) : write(group.name, {})
    end
    write("_meta", "active_term" => active_term)
  end

  def load!
    described_class.load!(directory: directory)
  end

  before { write_empty_groups! }

  it "resolves a reference by label, not by id" do
    write("terms", "ss_2026" => { "year" => 2026, "season" => "SS" })
    write("users", "teacher" => { "email" => "teacher@mampf.edu" })
    write("courses", "la_2" => { "title" => "Lineare Algebra 2", "short_title" => "LA 2" })
    write("lectures", "la_2_lecture" => {
            "course" => "courses/la_2", "term" => "terms/ss_2026", "teacher" => "users/teacher"
          })

    load!

    lecture = Lecture.sole
    expect(lecture.course.short_title).to eq("LA 2")
    expect(lecture.term).to eq(Term.sole)
    expect(lecture.teacher.email).to eq("teacher@mampf.edu")
  end

  it "writes a Mobility translation for every locale it was given" do
    write("subjects", "mathematik" => {
            "translations" => { "name" => { "de" => "Mathematik", "en" => "Mathematics" } }
          })

    load!

    subject = Subject.sole
    expect(subject.name(locale: :de)).to eq("Mathematik")
    expect(subject.name(locale: :en)).to eq("Mathematics")
  end

  it "gives every persona a password they can sign in with" do
    write("users", "teacher" => { "email" => "teacher@mampf.edu" })

    load!

    expect(User.sole.valid_password?(described_class::PASSWORD)).to be(true)
  end

  it "saves a tag before it has a notion, without failing its own presence validation" do
    write("tags", "ring" => {})
    write("notions", "de_ring" => { "title" => "Ring", "locale" => "de", "tag" => "tags/ring" })

    load!

    tag = Tag.sole
    expect(tag.notions.pluck(:title)).to eq(["Ring"])
  end

  it "does not duplicate a relation's model-created inverse" do
    write("tags", "ring" => {}, "ideal" => {})
    write_list("relations", [
                 { "tag" => "tags/ring", "related_tag" => "tags/ideal" },
                 { "tag" => "tags/ideal", "related_tag" => "tags/ring" }
               ])

    load!

    expect(Relation.count).to eq(2)
  end

  it "loads a TimeStamp-serialized column from its human-readable string" do
    write("terms", "ss_2026" => { "year" => 2026, "season" => "SS" })
    write("users", "teacher" => { "email" => "teacher@mampf.edu" })
    write("courses", "la_2" => { "title" => "LA 2", "short_title" => "LA 2" })
    write("lectures", "la_2_lecture" => {
            "course" => "courses/la_2", "term" => "terms/ss_2026", "teacher" => "users/teacher"
          })
    write("media",
          "medium" => { "sort" => "LessonMaterial", "teachable" => "lectures/la_2_lecture" })
    write("items", "item" => {
            "sort" => "remark", "start_time" => "00:01:02.500", "medium" => "media/medium"
          })

    load!

    item = Item.find_by!(sort: "remark")
    expect(item.start_time).to be_a(TimeStamp)
    expect(item.start_time.vtt_string).to eq("00:01:02.500")
  end

  it "carries an opaque serialized column over unchanged, bypassing its coder" do
    write("terms", "ss_2026" => { "year" => 2026, "season" => "SS" })
    write("users", "teacher" => { "email" => "teacher@mampf.edu" })
    write("courses", "la_2" => { "title" => "LA 2", "short_title" => "LA 2" })
    write("lectures", "la_2_lecture" => {
            "course" => "courses/la_2", "term" => "terms/ss_2026", "teacher" => "users/teacher"
          })
    raw = "--- !ruby/object:QuizGraph\nvertices: []\n"
    write("media", "quiz" => {
            "sort" => "Quiz", "teachable" => "lectures/la_2_lecture",
            "quiz_graph" => { "serialized" => raw }
          })

    load!

    medium = Medium.sole
    expect(medium.read_attribute_before_type_cast(:quiz_graph)).to eq(raw)
  end

  it "shifts a date column by whole semesters, moving with the extracted term" do
    write_empty_groups!(active_term: "SS 2020")
    write("terms", "ss_2020" => { "year" => 2020, "season" => "SS" })
    write("users", "teacher" => { "email" => "teacher@mampf.edu" })
    write("courses", "la_2" => { "title" => "LA 2", "short_title" => "LA 2" })
    write("lectures", "la_2_lecture" => {
            "course" => "courses/la_2", "term" => "terms/ss_2020", "teacher" => "users/teacher"
          })
    write("assignments", "sheet_1" => {
            "lecture" => "lectures/la_2_lecture", "title" => "Blatt 1",
            "deadline" => "2020-05-01T17:00:00+02:00"
          })

    travel_to(Time.zone.local(2022, 5, 1)) { load! }

    # SS 2020 -> SS 2022 is four semesters, i.e. 24 months.
    expect(Term.sole.year).to eq(2022)
    expect(Assignment.sole.deadline).to eq(Time.zone.parse("2022-05-01T17:00:00+02:00"))
  end

  it "loads only once, so a second run does not duplicate the content core" do
    write("courses", "la_2" => { "title" => "LA 2", "short_title" => "LA 2" })

    load!
    result = load!

    expect(result).to eq(:already_loaded)
    expect(Course.count).to eq(1)
  end
end
