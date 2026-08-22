module Demo
  # A spread of vignettes for one lecture, covering the states a teacher and a
  # student can run into: draft, published and withdrawn; editable and locked;
  # data collection off, on with answers, and on without any. One code answers
  # in two vignettes, which is the link the study is actually after.
  #
  # Vignettes carry no author column: they belong to their lecture, and the
  # lecture's teacher is who may edit them.
  module VignettesSupport
    extend self

    DEFAULT_LECTURE_ID = 1
    TITLE_PREFIX = "Demo:".freeze

    # One entry per demo run through a vignette, so the three codes give
    # visibly different answers in the export.
    TEXT_ANSWERS = [
      "Das stimmt nur, wenn der Raum endlich erzeugt ist.",
      "Ich würde erst nach der Dimension fragen.",
      "Sie hat recht, aber die Begründung fehlt ihr."
    ].freeze
    NUMBER_ANSWERS = ["2", "3", "2"].freeze
    LIKERT_ANSWERS = ["agree", "strongly_agree", "disagree"].freeze

    CLOSING_TEXT = <<~HTML.freeze
      <div>Danke, dass Du Dir die Zeit genommen hast. Wenn Du magst, sprich
      uns in der Übung an — wir erzählen gern, was aus den Antworten wird.</div>
    HTML

    CONSENT_TEXT = <<~HTML.freeze
      <div>Wir speichern Deine Antworten und die Zeit, die Du auf den Folien
      verbringst, unter der Kennung, die Du gleich bekommst. Antworten unter
      derselben Kennung werden über Vignetten hinweg verbunden. Ausgewertet
      werden sie nur von der Arbeitsgruppe Mathematikdidaktik.</div>
    HTML

    def setup!(lecture_id: DEFAULT_LECTURE_ID)
      ensure_non_production!
      lecture = lecture!(lecture_id)

      Demo::QuietLoggingSupport.with_quiet_logging do
        wipe_previous!(lecture)
        lecture.update!(vignettes: true)
        build_all!(lecture)
        report(lecture)
      end
    end

    private

      # rubocop:disable Rails/Exit
      def ensure_non_production!
        abort("Cannot run in production!") if Rails.env.production?
      end
      # rubocop:enable Rails/Exit

      def lecture!(lecture_id)
        lecture = Lecture.find_by(id: lecture_id)
        raise("No lecture with id #{lecture_id}. Run just seed first.") unless lecture
        raise("Lecture #{lecture_id} has no teacher.") unless lecture.teacher

        lecture
      end

      # Rebuilt from scratch every run, so the states stay the ones described
      # here however much was clicked around in between.
      def wipe_previous!(lecture)
        lecture.vignettes_questionnaires
               .where("title LIKE ?", "#{TITLE_PREFIX}%")
               .destroy_all
        # Codenames outlive the vignettes they answered, so the orphans of the
        # previous run would pile up. Nothing else in MaMpf keeps a codename
        # without answers around.
        Vignettes::Codename.where.missing(:user_answers).destroy_all
      end

      def build_all!(lecture)
        empty_draft!(lecture)
        full_draft!(lecture)
        published_without_collection!(lecture)
        shared = published_with_answers!(lecture)
        collecting_without_answers!(lecture)
        withdrawn_but_locked!(lecture, shared)
      end

      ##########################################################################
      # The scenarios
      ##########################################################################

      def empty_draft!(lecture)
        questionnaire!(lecture, "Entwurf ohne Folien")
      end

      def full_draft!(lecture)
        questionnaire = questionnaire!(lecture, "Entwurf mit allen Fragetypen")
        info = info_slide!(questionnaire, "Was ist ein Erzeugendensystem?", "eye")

        text_slide!(questionnaire, 1, info_slides: [info])
        number_slide!(questionnaire, 2, info_slides: [info])
        choice_slide!(questionnaire, 3)
        likert_slide!(questionnaire, 4)
        questionnaire
      end

      def published_without_collection!(lecture)
        questionnaire = questionnaire!(lecture, "Veröffentlicht ohne Datenerhebung",
                                       closing: false)
        text_slide!(questionnaire, 1)
        choice_slide!(questionnaire, 2)
        publish!(questionnaire)
      end

      # The full study case: three codes have worked through it, so the CSV
      # export has something to show. Returns the code that also answers the
      # withdrawn vignette.
      def published_with_answers!(lecture)
        questionnaire = questionnaire!(lecture, "Veröffentlicht mit Datenerhebung",
                                       collecting: true)
        info = info_slide!(questionnaire, "Hinweis zur Notation", "dotplot")
        text_slide!(questionnaire, 1, info_slides: [info])
        number_slide!(questionnaire, 2)
        likert_slide!(questionnaire, 3)
        publish!(questionnaire)

        shared = Vignettes::Codename.generate!
        [shared, Vignettes::Codename.generate!, Vignettes::Codename.generate!]
          .each_with_index { |code, index| run_through!(questionnaire, code, index) }
        shared
      end

      def collecting_without_answers!(lecture)
        questionnaire = questionnaire!(lecture, "Erhebung an, noch keine Antworten",
                                       collecting: true)
        text_slide!(questionnaire, 1)
        likert_slide!(questionnaire, 2)
        publish!(questionnaire)
      end

      # Withdrawn from the students, but still locked: publishing is what locks
      # a vignette, and unpublishing does not undo that.
      def withdrawn_but_locked!(lecture, shared_code)
        questionnaire = questionnaire!(lecture, "Zurückgezogen und gesperrt",
                                       collecting: true)
        text_slide!(questionnaire, 1)
        choice_slide!(questionnaire, 2)
        publish!(questionnaire)
        run_through!(questionnaire, shared_code, 0)
        questionnaire.update!(published: false)
        questionnaire
      end

      ##########################################################################
      # Building blocks
      ##########################################################################

      # closing_text is left off one scenario on purpose, so the plain
      # thank-you fallback is visible somewhere too.
      def questionnaire!(lecture, title, collecting: false, closing: true)
        Vignettes::Questionnaire.create!(
          lecture: lecture,
          title: "#{TITLE_PREFIX} #{title}",
          published: false,
          editable: true,
          data_collection: collecting,
          consent_text: collecting ? CONSENT_TEXT : nil,
          closing_text: closing ? CLOSING_TEXT : nil
        )
      end

      def publish!(questionnaire)
        questionnaire.update!(published: true, editable: false)
        questionnaire
      end

      def info_slide!(questionnaire, title, icon_type)
        Vignettes::InfoSlide.create!(questionnaire: questionnaire, title: title,
                                     icon_type: icon_type,
                                     content: "<div>Zusatzmaterial zur Aufgabe.</div>")
      end

      def slide!(questionnaire, position, title, prompt, info_slides)
        slide = Vignettes::Slide.create!(questionnaire: questionnaire,
                                         title: title,
                                         position: position,
                                         content: "<div>#{prompt}</div>")
        slide.info_slides = info_slides
        slide
      end

      def text_slide!(questionnaire, position, info_slides: [])
        slide = slide!(questionnaire, position, "Begründung",
                       "Eine Studentin behauptet, je zwei Basen eines " \
                       "Vektorraums seien gleich lang.", info_slides)
        Vignettes::TextQuestion.create!(slide: slide,
                                        question_text: "Wie würdest Du darauf antworten?")
        slide
      end

      def number_slide!(questionnaire, position, info_slides: [])
        slide = slide!(questionnaire, position, "Dimension",
                       "Betrachte den Lösungsraum eines homogenen Systems mit " \
                       "drei unabhängigen Gleichungen in fünf Unbekannten.", info_slides)
        Vignettes::NumberQuestion.create!(slide: slide,
                                          question_text: "Welche Dimension hat er?",
                                          only_integer: true,
                                          min_number: 0, max_number: 5)
        slide
      end

      def choice_slide!(questionnaire, position, info_slides: [])
        slide = slide!(questionnaire, position, "Fehlersuche",
                       "Ein Beweis zeigt die lineare Unabhängigkeit dreier " \
                       "Vektoren und schließt daraus auf eine Basis.", info_slides)
        question = Vignettes::MultipleChoiceQuestion.create!(
          slide: slide, question_text: "Was fehlt dem Beweis?"
        )
        ["Die Dimension des Raums", "Ein Erzeugendensystem",
         "Nichts, der Beweis ist vollständig"].each do |text|
          Vignettes::Option.create!(question: question, text: text)
        end
        slide
      end

      def likert_slide!(questionnaire, position, info_slides: [])
        slide = slide!(questionnaire, position, "Einschätzung",
                       "Denk an die Aufgabe, die Du gerade bearbeitet hast.", info_slides)
        Vignettes::LikertScaleQuestion.create!(
          slide: slide, language: "de",
          question_text: "Diese Aufgabe passt zu dem, was ich in der Vorlesung gelernt habe."
        )
        slide
      end

      ##########################################################################
      # Answers under a code
      ##########################################################################

      def run_through!(questionnaire, codename, index)
        run = Vignettes::UserAnswer.create!(codename: codename,
                                            questionnaire: questionnaire)
        questionnaire.slides.order(:position).each do |slide|
          answer!(run, slide, index)
        end
      end

      def answer!(run, slide, index)
        question = slide.question
        answer = build_answer(run, slide, question, index)
        answer.save!
        statistic!(answer, slide, index)
      end

      def build_answer(run, slide, question, index)
        attributes = { user_answer: run, slide: slide, question: question }
        case question
        when Vignettes::TextQuestion
          Vignettes::TextAnswer.new(**attributes, text: TEXT_ANSWERS[index])
        when Vignettes::NumberQuestion
          Vignettes::NumberAnswer.new(**attributes, text: NUMBER_ANSWERS[index])
        when Vignettes::MultipleChoiceQuestion
          Vignettes::MultipleChoiceAnswer.new(**attributes,
                                              options: [question.options[index]].compact)
        else
          Vignettes::LikertScaleAnswer.new(**attributes,
                                           likert_scale_value: LIKERT_ANSWERS[index])
        end
      end

      def statistic!(answer, slide, index)
        seconds = 20 + (index * 7) + (slide.position * 3)
        info_seconds = slide.info_slides.to_h { |info| [info.id, 4 + index] }

        Vignettes::SlideStatistic.create!(
          answer: answer,
          time_on_slide: seconds,
          total_time_on_slide: seconds + info_seconds.values.sum,
          time_on_info_slides: info_seconds.to_json,
          info_slides_access_count: slide.info_slides.to_h { |info| [info.id, 1] }.to_json,
          info_slides_first_access_time: slide.info_slides.to_h { |info| [info.id, 6] }.to_json
        )
      end

      def report(lecture)
        output("Lecture ##{lecture.id} (#{lecture.course.title}), " \
               "teacher #{lecture.teacher.name}, vignettes switched on.")
        lecture.vignettes_questionnaires
               .where("title LIKE ?", "#{TITLE_PREFIX}%")
               .order(:id).each { |questionnaire| output("  #{describe(questionnaire)}") }
        output("Overview: /lectures/#{lecture.id}/questionnaires")
      end

      def describe(questionnaire)
        state = [
          questionnaire.published ? "published" : "not published",
          questionnaire.editable ? "editable" : "locked",
          questionnaire.data_collection? ? "collecting" : "no collection",
          "#{questionnaire.slides.count} slides",
          "#{questionnaire.user_answers.count} runs".sub(/\A1 runs\z/, "1 run")
        ].join(", ")
        "##{questionnaire.id} #{questionnaire.title} — #{state}"
      end

      def output(message)
        $stdout.puts(message)
      end
  end
end
