module Seeds
  # Checks that a seeded database actually has what db/seeds/ promises: the
  # content core's row counts against what `_meta.yml` said was written, every
  # persona able to sign in, and the scenarios that make the seed worth
  # clicking around in. What used to be a diff against a dump-restored
  # database -- there being no dump to diff against any more -- this is a set
  # of standing invariants instead.
  module VerifySupport
    module_function

    DIRECTORY = Rails.root.join("db/seeds/data")

    GROUP_TO_MODEL = {
      "subjects" => Subject, "programs" => Program, "divisions" => Division,
      "terms" => Term, "courses" => Course, "tags" => Tag, "notions" => Notion,
      "relations" => Relation, "lectures" => Lecture, "chapters" => Chapter,
      "sections" => Section, "lessons" => Lesson, "talks" => Talk,
      "media" => Medium, "items" => Item, "answers" => Answer,
      "referrals" => Referral, "assignments" => Assignment
    }.freeze

    # A lower bound, not an exact match: the scenarios add courses, lectures,
    # media and the rest of it on top of the content core, in the same tables.
    def check_content_core(meta)
      meta.fetch("counts").filter_map do |group, expected|
        model = GROUP_TO_MODEL[group]
        next if model.nil?

        actual = model.count
        result("#{group}: #{expected}+ expected", actual >= expected, "#{actual} present")
      end
    end

    def check_personas(users)
      users.map do |_label, attributes|
        email = attributes.fetch("email")
        user = User.find_by(email: email)
        ok = user.present? && user.valid_password?(Seeds::LoadSupport::PASSWORD)
        result("#{email} can sign in", ok, ok ? "ok" : "missing, or the seed password is wrong")
      end
    end

    SCENARIO_CHECKS = {
      "a registration campaign is still open" => -> { Registration::Campaign.open.exists? },
      "the legacy pre-roster lecture exists" =>
        -> { Course.exists?(title: "Demo Legacy Lecture") },
      "vignette questionnaires exist" => -> { Vignettes::Questionnaire.exists? },
      "the next-term banner has courses to show" =>
        -> { Course.exists?(["title LIKE ?", "Demo Next Term%"]) },
      "homework has been handed in" => -> { Submission.exists? },
      "the two stale-password accounts still need a change" => lambda {
        Scenarios::ScenarioTouchupsSupport::STALE_PASSWORD_ACCOUNTS.all? do |email|
          User.find_by(email: email)&.password_change_required?
        end
      }
    }.freeze

    def check_scenarios
      SCENARIO_CHECKS.map do |description, check|
        ok = check.call
        result(description, ok, ok ? "ok" : "missing")
      end
    end

    def result(check, passed, detail)
      { check: check, ok: passed, detail: detail }
    end

    def verify!(directory: DIRECTORY)
      meta = YAML.safe_load_file(directory.join("_meta.yml"))
      users = YAML.safe_load_file(directory.join("users.yml"))

      check_content_core(meta) + check_personas(users) + check_scenarios
    end
  end
end
