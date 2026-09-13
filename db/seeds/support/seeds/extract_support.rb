require "yaml"

module Seeds
  # Writes the content core of a seeded development database out as YAML, for
  # db/seeds/data. The read side of the pair Seeds::LoadSupport writes back
  # from; run it against a database that has only the content core loaded
  # (before db/seeds/scenarios.rb runs), and what it produces is reviewed
  # and committed by hand from then on.
  #
  # Records are addressed by label rather than by primary key, so nothing that
  # comes out of here depends on the ids one particular dump handed out. A
  # reference to a record the extraction leaves out (a user the demo scenarios
  # generate, say) is not written; the row that carried it is skipped and
  # counted, so that what the scenarios own stays visible in the report rather
  # than half-landing in a data file.
  module ExtractSupport
    module_function

    DIRECTORY = Rails.root.join("db/seeds/data")

    # Columns every record carries and no data file needs: the primary key the
    # labels replace, and timestamps the loader sets again.
    SKIPPED_COLUMNS = ["id", "created_at", "updated_at"].freeze

    # Accounts the demo scenarios create for themselves. Those are generated
    # again on every run and have no business in a data file.
    GENERATED_USER_PREFIXES = [
      "demo_", "seminar_", "external_", "nachruecker_",
      "solver_user_", "cohort_user_", "campaign_"
    ].freeze

    # Everything devise and the sign-in flow write about an account, none of
    # which describes who the account is.
    SKIPPED_USER_COLUMNS = [
      "encrypted_password", "reset_password_token",
      "reset_password_sent_at", "remember_created_at",
      "confirmation_token", "confirmed_at", "confirmation_sent_at",
      "unconfirmed_email", "locked_at", "unlock_token", "failed_attempts",
      "sign_in_count", "current_sign_in_at", "last_sign_in_at",
      "current_sign_in_ip", "last_sign_in_ip", "password_policy_version",
      "password_changed_at", "current_lecture_id"
    ].freeze

    # The order is the order the files are written in, and the order a loader
    # will want to read them in: nothing refers forward.
    #
    # `list` marks a group whose rows nothing refers to -- join rows, mostly --
    # which is written as a plain sequence instead of a mapping of labels.
    def groups
      [
        group("subjects", Subject, &:name),
        group("programs", Program) { |p| "#{p.subject&.name} #{p.name}" },
        group("divisions", Division) { |d| "#{d.program&.name} #{d.name}" },
        group("terms", Term) { |t| "#{t.season} #{t.year}" },
        group("users", User, scope: persona_users,
                             skip: SKIPPED_USER_COLUMNS) { |u| u.email.split("@").first },
        group("courses", Course) { |c| c.short_title.presence || c.title },
        group("tags", Tag) { |t| tag_label(t) },
        group("notions", Notion) { |n| "#{n.locale}_#{n.title}" },
        group("relations", Relation, list: true),
        group("lectures", Lecture) { |l| lecture_label(l) },
        group("chapters", Chapter) { |c| "#{lecture_label(c.lecture)}_#{c.position}" },
        group("sections", Section) { |s| section_label(s) },
        group("lessons", Lesson) { |l| "#{lecture_label(l.lecture)}_#{l.date}" },
        group("talks", Talk) { |t| "#{lecture_label(t.lecture)}_#{t.position}" },
        group("media", Medium) { |m| medium_label(m) },
        group("items", Item) { |i| item_label(i) },
        group("answers", Answer, list: true),
        group("referrals", Referral, list: true),
        group("assignments", Assignment) { |a| "#{lecture_label(a.lecture)}_#{a.title}" },
        group("division_course_joins", DivisionCourseJoin, list: true),
        group("course_tag_joins", CourseTagJoin, list: true),
        group("medium_tag_joins", MediumTagJoin, list: true),
        group("section_tag_joins", SectionTagJoin, list: true),
        group("lesson_tag_joins", LessonTagJoin, list: true),
        group("talk_tag_joins", TalkTagJoin, list: true),
        group("lesson_section_joins", LessonSectionJoin, list: true),
        group("speaker_talk_joins", SpeakerTalkJoin, list: true),
        group("editable_user_joins", EditableUserJoin, list: true)
      ]
    end

    Group = Struct.new(:name, :model, :scope, :list, :skip, :label,
                       keyword_init: true)

    def group(name, model, scope: nil, list: false, skip: [], &label)
      Group.new(name: name, model: model, scope: scope || model.order(:id),
                list: list, skip: skip, label: label)
    end

    def extract!(directory: DIRECTORY)
      ensure_development!
      FileUtils.mkdir_p(directory)

      all = groups
      labels = all.to_h { |g| [g.model.table_name, labels_for(g)] }
      report = all.map { |g| write!(g, labels, directory) }
      write_meta!(report, directory)
      report
    end

    # Labels are handed out in id order, so a name that has to be made unique
    # gets its suffix in a reproducible place.
    def labels_for(group)
      taken = {}
      group.scope.each_with_object({}) do |record, result|
        base = label_for(group, record)
        taken[base] = taken.fetch(base, 0) + 1
        result[record.id] = taken[base] > 1 ? "#{base}_#{taken[base]}" : base
      end
    end

    def label_for(group, record)
      raw = group.label ? group.label.call(record) : group.name.singularize
      slug(raw).presence || group.name.singularize
    end

    def write!(group, labels, directory)
      rows = []
      skipped = 0
      own = labels[group.model.table_name] || {}

      group.scope.each do |record|
        attributes = attributes_for(record, group, labels)
        if attributes == :incomplete
          skipped += 1
          next
        end
        rows << [own[record.id], attributes]
      end

      content = group.list ? rows.map(&:last) : rows.to_h
      path = File.join(directory, "#{group.name}.yml")
      File.write(path, YAML.dump(content))
      { group: group.name, written: rows.size, skipped: skipped, path: path }
    end

    # Returns `:incomplete` when the record points at something the extraction
    # does not cover: half a row is worse than none.
    def attributes_for(record, group, labels)
      model = record.class
      foreign_keys = belongs_to_reflections(model)
      attributes = {}

      model.column_names.each do |column|
        next if SKIPPED_COLUMNS.include?(column) || group.skip.include?(column)
        next if column.end_with?("_data")

        if (reflection = foreign_keys[column])
          next if record[column].nil?

          reference = reference_for(record, reflection, labels)
          return :incomplete if reference.nil?

          attributes[reflection.name.to_s] = reference
          next
        end
        next if polymorphic_type_column?(column, foreign_keys)

        value = record[column]
        next if value.nil? || value == "" || value == model.column_defaults[column]

        attributes[column] = serialize(value, record, column)
      end

      translations = translations_for(record)
      attributes["translations"] = translations if translations.any?

      attachments = attachments_for(record)
      attributes["attachments"] = attachments if attachments.any?
      attributes
    end

    # Mobility keeps translated attributes in a table of their own, where the
    # column scan above cannot see them.
    def translations_for(record)
      model = record.class
      return {} unless model.respond_to?(:mobility_attributes)

      translated = model.mobility_attributes.index_with do |attribute|
        locales_of(record, attribute)
      end
      translated.reject { |_attribute, values| values.empty? }
    end

    def locales_of(record, attribute)
      I18n.available_locales.filter_map do |locale|
        value = record.public_send(attribute, locale: locale)
        [locale.to_s, value] if value.present?
      end.to_h
    end

    def belongs_to_reflections(model)
      model.reflect_on_all_associations(:belongs_to)
           .index_by { |reflection| reflection.foreign_key.to_s }
    end

    def polymorphic_type_column?(column, foreign_keys)
      column.end_with?("_type") &&
        foreign_keys.key?(column.sub(/_type\z/, "_id"))
    end

    # A reference reads "<file>/<label>", so that a polymorphic one says what
    # kind of record it points at without a second column.
    def reference_for(record, reflection, labels)
      klass = if reflection.polymorphic?
        record[reflection.foreign_type].to_s.safe_constantize
      else
        reflection.klass
      end
      return if klass.nil?

      label = labels.dig(klass.table_name, record[reflection.foreign_key])
      return if label.nil?

      "#{klass.table_name}/#{label}"
    end

    # Shrine keeps what it knows about an upload next to it; the file itself
    # is not the data file's business, but which record wants one is.
    def attachments_for(record)
      record.class.column_names.select { |c| c.end_with?("_data") }
            .filter_map do |column|
        data = parse_json(record[column])
        next if data.blank?

        [column.delete_suffix("_data"), data.dig("metadata", "filename")]
      end.to_h
    end

    def parse_json(value)
      return value if value.is_a?(Hash)
      return if value.blank?

      JSON.parse(value)
    rescue JSON::ParserError
      nil
    end

    # A column whose value is an object of its own -- a time stamp the app
    # keeps as serialized Ruby in a text column -- is written the way a person
    # would type it, not the way the database happens to hold it.
    PLAIN_TYPES = [String, Numeric, TrueClass, FalseClass, Hash, Array].freeze

    def serialize(value, record, column)
      case value
      when Time, ActiveSupport::TimeWithZone then value.iso8601
      when Date then value.to_s
      when BigDecimal then value.to_f
      when TimeStamp then value.vtt_string
      else
        plain?(value) ? value : opaque(record, column)
      end
    end

    def plain?(value)
      PLAIN_TYPES.any? { |type| value.is_a?(type) }
    end

    # A quiz graph and a solution are objects the app stores as serialized Ruby
    # in a text column. There is no readable form of them to write here, so
    # what the database holds is carried over verbatim, marked as the blob it
    # is: a loader has to hand it back to the column unchanged, and whether
    # these belong in a data file at all is a question for the loader.
    def opaque(record, column)
      { "serialized" => record.read_attribute_before_type_cast(column) }
    end

    # The accounts a developer signs in with, and whoever else was not made up
    # by a demo scenario.
    def persona_users
      generated = GENERATED_USER_PREFIXES.map { |prefix| "#{prefix}%" }
      condition = generated.map { "email LIKE ?" }.join(" OR ")
      User.where.not(condition, *generated).order(:id)
    end

    def tag_label(tag)
      notion = tag.notions.find_by(locale: "en") || tag.notions.first
      notion&.title || "tag"
    end

    def lecture_label(lecture)
      return "lecture" if lecture.nil?

      course = lecture.course&.short_title || lecture.course&.title
      term = lecture.term
      [course, lecture.sort, term && "#{term.season}#{term.year}"].compact.join(" ")
    end

    def section_label(section)
      chapter = section.chapter
      return "section_#{section.position}" if chapter.nil?

      "#{lecture_label(chapter.lecture)}_#{chapter.position}_#{section.position}"
    end

    def medium_label(medium)
      teachable = medium.teachable
      context = case teachable
                when Lecture then lecture_label(teachable)
                when Lesson, Talk then lecture_label(teachable.lecture)
                when Course then teachable.short_title
      end
      [context, medium.sort, medium.description].compact.join(" ")
    end

    def item_label(item)
      medium = item.medium
      context = medium ? medium_label(medium) : "item"
      [context, item.sort, item.ref_number || item.position].compact.join(" ")
    end

    def slug(value)
      value.to_s.parameterize(separator: "_").first(80)
    end

    # What the loader needs to know about when this was taken: the dates in the
    # files are the ones the dump carried, and only mean anything against the
    # term the data was in on that day.
    def write_meta!(report, directory)
      term = Term.active || Term.order(:year, :season).last
      meta = {
        "extracted_at" => Time.zone.today.to_s,
        "reference_date" => Time.zone.today.to_s,
        "active_term" => term && "#{term.season} #{term.year}",
        "counts" => report.to_h { |row| [row[:group], row[:written]] },
        "skipped" => report.reject { |row| row[:skipped].zero? }
                           .to_h { |row| [row[:group], row[:skipped]] }
      }
      File.write(File.join(directory, "_meta.yml"), YAML.dump(meta))
    end

    # rubocop:disable Rails/Exit
    def ensure_development!
      return if Rails.env.development?

      abort("This reads the development seed data: refusing to run in #{Rails.env}.")
    end
    # rubocop:enable Rails/Exit
  end
end
