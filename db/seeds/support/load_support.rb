require "yaml"

module Seeds
  # Loads db/seeds/data/*.yml into the database.
  #
  # This is the write side of the seed rewrite; Seeds::ExtractSupport is the
  # read side. Groups are loaded in the order they were extracted (see
  # ExtractSupport.groups), so a reference never points forward: by the time a
  # lecture asks for its course, the course already has a record to hand back.
  #
  # Records are resolved by the label the extraction gave them
  # ("courses/la_2"), not by a primary key nothing here controls.
  #
  # A record is saved without validation. The data came out of a database that
  # already enforced it, and some of what a validation checks is only true
  # once a later group has run -- a tag needs a notion, a lesson needs a
  # section, a medium with editors needs its editable_user_joins row -- all of
  # which are their own group, loaded afterward. Validating a record the
  # moment it is built would reject data that is merely incomplete so far.
  module LoadSupport
    module_function

    DIRECTORY = Rails.root.join("db/seeds/data")
    FIXTURES_DIRECTORY = Rails.root.join("spec/cypress/fixtures/files")

    # The password every seeded persona signs in with.
    PASSWORD = "lemon-floppy-curtain-42".freeze

    # An attachment column maps to a small fixture file that stands in for
    # it. The data files remember what a record was originally uploaded with
    # (see db/seeds/data/README.md), not the file itself -- these fixtures
    # (also used by the request specs) are close enough to look right in the
    # UI, without shipping the 82 MB the dump carried.
    FIXTURE_FILES = {
      "video" => "talk.mp4",
      "screenshot" => "image.png",
      "manuscript" => "manuscript.pdf",
      "geogebra" => "geogebra.ggb",
      "image" => "image.png",
      "home_attachment" => "manuscript.pdf"
    }.freeze

    Group = Struct.new(:name, :model, :list, keyword_init: true)

    # Same tables, same order as Seeds::ExtractSupport.groups.
    def groups
      [
        Group.new(name: "subjects", model: Subject),
        Group.new(name: "programs", model: Program),
        Group.new(name: "divisions", model: Division),
        Group.new(name: "terms", model: Term),
        Group.new(name: "users", model: User),
        Group.new(name: "courses", model: Course),
        Group.new(name: "tags", model: Tag),
        Group.new(name: "notions", model: Notion),
        Group.new(name: "relations", model: Relation, list: true),
        Group.new(name: "lectures", model: Lecture),
        Group.new(name: "chapters", model: Chapter),
        Group.new(name: "sections", model: Section),
        Group.new(name: "lessons", model: Lesson),
        Group.new(name: "talks", model: Talk),
        Group.new(name: "media", model: Medium),
        Group.new(name: "items", model: Item),
        Group.new(name: "answers", model: Answer, list: true),
        Group.new(name: "referrals", model: Referral, list: true),
        Group.new(name: "assignments", model: Assignment),
        Group.new(name: "division_course_joins", model: DivisionCourseJoin, list: true),
        Group.new(name: "course_tag_joins", model: CourseTagJoin, list: true),
        Group.new(name: "medium_tag_joins", model: MediumTagJoin, list: true),
        Group.new(name: "section_tag_joins", model: SectionTagJoin, list: true),
        Group.new(name: "lesson_tag_joins", model: LessonTagJoin, list: true),
        Group.new(name: "talk_tag_joins", model: TalkTagJoin, list: true),
        Group.new(name: "lesson_section_joins", model: LessonSectionJoin, list: true),
        Group.new(name: "speaker_talk_joins", model: SpeakerTalkJoin, list: true),
        Group.new(name: "editable_user_joins", model: EditableUserJoin, list: true)
      ]
    end

    # Loaded once: a database that already has courses in it is a database
    # this already ran against. `db:seed:replant` truncates first, so this
    # guard does not stand in the way of a deliberate reseed.
    def load!(directory: DIRECTORY)
      ensure_development_or_test!
      return :already_loaded if Course.exists?

      @records = Hash.new { |hash, table| hash[table] = {} }
      @semesters = semester_offset(directory)

      groups.map { |group| load_group!(group, directory) }
    end

    def load_group!(group, directory)
      rows = read(group, directory)
      loaded = if group.model == Relation
        load_relations!(rows)
      elsif group.list
        rows.each { |attributes| build_record(group.model, attributes) }.size
      else
        rows.each { |label, attributes| store!(group.name, label, group.model, attributes) }.size
      end
      { group: group.name, loaded: loaded }
    end

    # A bare date such as `2022-08-05` (Talk#dates) round-trips through YAML's
    # implicit typing as a Date even though it was written as a String value;
    # a full timestamp does the same as a Time. Permitted here rather than
    # avoided, since a data file is meant to be read by eye, and quoting every
    # date-shaped scalar to keep it a String would fight that.
    def read(group, directory)
      content = YAML.safe_load_file(directory.join("#{group.name}.yml"),
                                    permitted_classes: [Date, Time])
      content || (group.list ? [] : {})
    end

    def store!(table, label, model, attributes)
      @records[table][label] = build_record(model, attributes)
    end

    # A relation's inverse is created by the model itself (Relation#create_inverse),
    # so the data file's two directions of the same pair would otherwise land
    # as a duplicate: the second row finds the first one's auto-created
    # inverse already sitting there.
    def load_relations!(rows)
      rows.count do |attributes|
        tag = resolve(attributes.fetch("tag"))
        related_tag = resolve(attributes.fetch("related_tag"))
        Relation.find_or_create_by!(tag: tag, related_tag: related_tag)
      end
    end

    # Medium#create_self_item already makes this row the moment the medium it
    # belongs to is built; recorded here only so other groups have something
    # to point at, it names the row that already exists instead of adding a
    # second one.
    def build_record(model, attributes)
      return self_item(attributes) if model == Item && attributes["sort"] == "self"

      record = instantiate(model, attributes)
      raw_columns = {}

      attributes.each do |key, value|
        case key
        when "translations" then assign_translations!(record, value)
        when "attachments" then assign_attachments!(record, value)
        else assign_attribute!(record, model, key, value, raw_columns)
        end
      end

      assign_password!(record) if model == User
      apply_term_shift!(record) if model == Term
      # Assignment#after_create builds its assessment with requires_submission
      # true by default, which a deadline already in the past (most of them,
      # loaded as historical data) refuses to accept.
      record.requires_submission = false if model == Assignment

      record.save!(validate: false)
      apply_raw_columns!(record, raw_columns)
      record
    end

    # `Medium.new(type: "Question")` stays a Medium in memory -- STI only
    # switches the Ruby class when the subclass itself builds the record, so
    # a "type" column in the data has to be read before `.new` is called, not
    # assigned after.
    def instantiate(model, attributes)
      klass = attributes["type"]&.safe_constantize
      klass && klass <= model ? klass.new : model.new
    end

    def assign_attribute!(record, model, key, value, raw_columns)
      reflection = model.reflect_on_association(key)
      if reflection&.belongs_to?
        record.public_send("#{key}=", resolve(value))
      elsif value.is_a?(Hash) && value.key?("serialized")
        raw_columns[key] = value["serialized"]
      elsif timestamp_column?(model, key)
        record.public_send("#{key}=", TimeStamp.new(time_string: value))
      elsif shiftable_column?(model, key)
        record.public_send("#{key}=", shift(value, model.columns_hash[key]))
      else
        record.public_send("#{key}=", value)
      end
    end

    def self_item(attributes)
      resolve(attributes.fetch("medium")).items.find_by!(sort: "self")
    end

    def resolve(reference)
      table, label = reference.split("/", 2)
      @records.dig(table, label) ||
        raise("Seed data: unresolved reference #{reference.inspect}")
    end

    def assign_translations!(record, translations)
      translations.each do |attribute, per_locale|
        per_locale.each do |locale, value|
          record.public_send("#{attribute}=", value, locale: locale.to_sym)
        end
      end
    end

    def assign_attachments!(record, attachments)
      attachments.each_key do |column|
        filename = FIXTURE_FILES[column]
        next if filename.nil?

        record.public_send("#{column}=", File.open(FIXTURES_DIRECTORY.join(filename), "rb"))
      end
    end

    def assign_password!(record)
      record.password = PASSWORD
      record.password_confirmation = PASSWORD
    end

    # A column the app stores as an opaque serialized object (a quiz graph, a
    # solution) is handed back to it byte for byte, bypassing the coder: it
    # was not written by hand and has no business being decoded and re-encoded
    # by one.
    def apply_raw_columns!(record, raw_columns)
      return if raw_columns.empty?

      raw_columns.each do |column, raw|
        # rubocop:disable Rails/SkipsModelValidations
        # update_all writes the quoted value as-is; an ordinary assignment
        # would run it through the column's coder, decoding and re-encoding a
        # blob this loader was explicitly handed to avoid touching.
        record.class.where(id: record.id).update_all(["#{column} = ?", raw])
        # rubocop:enable Rails/SkipsModelValidations
      end
    end

    def timestamp_column?(model, key)
      type = model.type_for_attribute(key)
      type.respond_to?(:coder) && type.coder == TimeStamp
    end

    def shiftable_column?(model, key)
      column = model.columns_hash[key]
      column && [:date, :datetime].include?(column.type)
    end

    # Terms are counted in half years, so that WS follows SS within a year;
    # shifting one by the same number of semesters as every other date column
    # moves it exactly as far.
    def apply_term_shift!(record)
      return if @semesters.zero?

      index = term_index(record.year, record.season) + @semesters
      record.year = index / 2
      record.season = index.even? ? "SS" : "WS"
    end

    def shift(value, column)
      return value if @semesters.zero? || value.blank?

      if column.try(:array?)
        Array(value).map { |element| shift_scalar(element, column.type) }
      else
        shift_scalar(value, column.type)
      end
    end

    def shift_scalar(value, type)
      parsed = if value.is_a?(String)
        type == :date ? Date.parse(value) : Time.zone.parse(value)
      else
        value
      end
      parsed + (6 * @semesters).months
    end

    # How many semesters separate the term the data was extracted in
    # (`_meta.yml`) from the term "now" (by the same season boundary the rest
    # of the app uses, see Term.previous_by_date) falls into. A seed loaded
    # today plays out today; loaded again in two years, it has moved on four
    # semesters with it -- the whole reason the old, dump-based seed needed a
    # `seeds:build` step to move forward is gone.
    def semester_offset(directory)
      meta = YAML.safe_load_file(directory.join("_meta.yml"), permitted_classes: [Date, Time])
      term_index(*current_term_label) - term_index(*parse_term_label(meta["active_term"]))
    end

    def parse_term_label(label)
      season, year = label.split
      [Integer(year), season]
    end

    def current_term_label
      today = Date.current
      season = today.month.in?(4..9) ? "SS" : "WS"
      [today.year, season]
    end

    def term_index(year, season)
      (year * 2) + (season == "WS" ? 1 : 0)
    end

    # rubocop:disable Rails/Exit
    def ensure_development_or_test!
      return if Rails.env.local?

      abort("This loads the development seed data: refusing to run in #{Rails.env}.")
    end
    # rubocop:enable Rails/Exit
  end
end
