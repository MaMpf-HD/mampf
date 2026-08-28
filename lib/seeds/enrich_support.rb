module Seeds
  # Fills the seed data with the everyday material a new developer needs to see
  # the app working: welcome texts on the lecture pages, announcements, forum
  # discussions, comments, annotations and watchlists.
  module EnrichSupport
    extend self

    ADMIN_ANNOUNCEMENTS = [
      "Am Freitag ist MaMpf zwischen 8 und 10 Uhr wegen Wartungsarbeiten " \
      "nicht erreichbar.",
      "Die Anmeldung für die Veranstaltungen des kommenden Semesters ist " \
      "freigeschaltet."
    ].freeze

    LECTURE_ANNOUNCEMENTS = [
      "Die Vorlesung am Donnerstag entfällt.",
      "Das nächste Übungsblatt liegt ab heute bereit.",
      "Der Hörsaal für die Übung hat sich geändert."
    ].freeze

    TOPICS = [
      ["Frage zu Blatt 3, Aufgabe 2", [
        "Ich komme bei Teil b) nicht weiter. Hat jemand einen Tipp?",
        "Schau Dir Satz 4.2 an, damit lässt sich der Term abschätzen.",
        "Danke, damit hat es geklappt."
      ]],
      ["Lerngruppe für die Klausur", [
        "Wir treffen uns donnerstags um 16 Uhr in der Mathematikbibliothek.",
        "Kann man da noch dazukommen?",
        "Klar, kommt einfach vorbei."
      ]]
    ].freeze

    # MaMpf is taught in both languages, and a lecture that says it is English
    # should not greet its students in German.
    HOME_INTROS = {
      "de" => [
        "<div>Willkommen bei <strong>%<title>s</strong>!</div>" \
        "<div>Auf dieser Seite findest Du alles zur Veranstaltung: das Skript, " \
        "die Videos zu den einzelnen Sitzungen und die Übungsblätter. Die " \
        "Aufzeichnung steht in der Regel am Abend nach der Vorlesung bereit, " \
        "die Kapitelmarken kommen am Tag darauf dazu.</div>" \
        "<div>Die Übungsblätter erscheinen mittwochs und werden bis zum " \
        "Freitag der Folgewoche abgegeben — in Zweiergruppen, direkt hier über " \
        "MaMpf. Deine Tutorin oder Dein Tutor lädt die Korrektur an derselben " \
        "Stelle wieder hoch.</div>",

        "<div>Diese Seite ist die Anlaufstelle für <strong>%<title>s</strong>.</div>" \
        "<div>Fragen zwischendurch stellst Du am besten im Forum — dort " \
        "antworten auch die Tutorinnen und Tutoren. Wichtige Hinweise " \
        "erscheinen als Ankündigung ganz oben; wenn Du die Veranstaltung " \
        "abonniert hast, bekommst Du sie außerdem als Benachrichtigung.</div>" \
        "<div>Das Skript wächst mit der Vorlesung mit. Wo etwas unklar bleibt, " \
        "hilft oft die verlinkte Wiederholung aus dem vorigen Semester.</div>",

        "<div><strong>%<title>s</strong></div>" \
        "<div>Der Ablauf ist der übliche: zwei Vorlesungen und eine Übung pro " \
        "Woche, dazu ein Übungsblatt, von dem die Hälfte der Punkte zur " \
        "Klausurzulassung reicht.</div>" \
        "<div>Alles, was Du dafür brauchst, steht hier: das Skript unter " \
        "„Manuskript“, die Aufzeichnungen unter „Lektionen“ und die Blätter " \
        "unter „Übungen“. Die Sprechstunde findet dienstags um 14 Uhr statt.</div>"
      ],
      "en" => [
        "<div>Welcome to <strong>%<title>s</strong>!</div>" \
        "<div>This page holds everything the course comes with: the notes, the " \
        "recording of every session and the exercise sheets. A recording is " \
        "usually up the evening after the lecture, its chapter marks the day " \
        "after that.</div>" \
        "<div>Sheets appear on Wednesdays and are handed in by the Friday of " \
        "the week after — in pairs, here on MaMpf. Your tutor uploads the " \
        "correction in the same place.</div>",

        "<div>This is where <strong>%<title>s</strong> starts.</div>" \
        "<div>Ask what comes up in the forum; the tutors read it too. Anything " \
        "that matters is announced at the top of this page, and reaches you as " \
        "a notification once you have subscribed to the course.</div>" \
        "<div>The notes grow with the lecture. Where something stays unclear, " \
        "the linked revision from last term often helps.</div>",

        "<div><strong>%<title>s</strong></div>" \
        "<div>The week runs as usual: two lectures, one exercise class, and a " \
        "sheet of which half the points admit you to the exam.</div>" \
        "<div>Everything you need for that is here: the notes under " \
        "\u201CManuscript\u201D, the recordings under \u201CLessons\u201D and the sheets " \
        "under \u201CExercises\u201D. Office hours are on Tuesdays at 2 pm.</div>"
      ]
    }.freeze

    # The page a student sees before deciding to register, so it says what the
    # registration is for rather than describing a term already under way.
    REGISTRATION_INTROS = {
      "de" =>
        "<div><strong>%<title>s</strong> im kommenden Semester</div>" \
        "<div>Die Veranstaltung beginnt in der ersten Vorlesungswoche. Für die " \
        "Übungsgruppen läuft die Anmeldung bereits: Du gibst Deine Wunschzeiten " \
        "in der Reihenfolge an, in der sie Dir passen, und bekommst nach dem " \
        "Ende der Anmeldefrist eine Gruppe zugeteilt.</div>" \
        "<div>Ein Platz in der Veranstaltung hängt nicht daran — das Abonnement " \
        "hier ist keine verbindliche Anmeldung.</div>",
      "en" =>
        "<div><strong>%<title>s</strong> next term</div>" \
        "<div>The course starts in the first week of term. Registration for the " \
        "exercise groups is already running: you name the slots that suit you, " \
        "in the order they suit you, and are given a group once the deadline " \
        "has passed.</div>" \
        "<div>Your place in the course does not hang on it — subscribing here " \
        "is not a binding registration.</div>"
    }.freeze

    # What people jot down while watching: students ask, the teacher notes what
    # to change next time round.
    STUDENT_NOTES = [
      ["Hier nochmal ansehen, der Schritt ging schnell.", :note, nil],
      ["Warum darf man die Summe an dieser Stelle vertauschen?", :content, :argument],
      ["Das ist genau die Aufgabe von Blatt 3.", :content, :strategy],
      ["Definition sitzt jetzt.", :note, :definition],
      ["Ab hier ist die Tafel schlecht zu lesen.", :presentation, nil],
      ["Ich glaube, im Index ist ein Dreher.", :mistake, nil]
    ].freeze

    TEACHER_NOTES = [
      ["Voraussetzung fehlt, beim nächsten Mal ergänzen.", :mistake, nil],
      ["Hier langsamer machen, das geht zu schnell.", :presentation, nil],
      ["Beispiel für die Übung übernehmen.", :content, :strategy]
    ].freeze

    # Spread over the sample video, which runs about 42 seconds.
    ANNOTATION_SECONDS = [4.5, 11.0, 18.5, 25.0, 31.5, 37.0].freeze

    WATCHLIST_NAMES = ["Wiederholung", "Vor der Klausur", "Nochmal ansehen"].freeze
    TEACHER_WATCHLIST_NAME = "Für die Sprechstunde".freeze

    COMMENTS = [
      "Ab Minute 12 ist der Ton etwas leise.",
      "Sehr schön erklärt, danke!",
      "Gibt es dazu noch ein weiteres Beispiel?"
    ].freeze

    def enrich!
      refresh_forum_names!
      add_home_intros!
      add_announcements!
      add_discussions!
      add_media_comments!
      add_annotations!
      add_watchlists!
    end

    private

      def students
        @students ||= User.where(email: (1..5).map { |i| "student#{i}@mampf.edu" })
                          .to_a.presence || User.where(admin: false).limit(5).to_a
      end

      def admin
        @admin ||= User.find_by(email: "admin@mampf.edu") || User.find_by(admin: true)
      end

      def current_lectures
        @current_lectures ||= Lecture.where(term: Demo::TermSupport.active_term).to_a
      end

      # The pages a visitor actually opens: the term that is running and the one
      # that can already be registered for.
      def showcase_lectures
        @showcase_lectures ||=
          current_lectures + Lecture.where(term: Demo::TermSupport.next_term).to_a
      end

      # The forum name carries the term, which the year shift has moved on.
      def refresh_forum_names!
        Lecture.where.not(forum_id: nil).find_each do |lecture|
          lecture.forum&.update!(name: lecture.forum_title)
        end
      end

      # The home page is where a lecture starts for a student, and an empty one
      # says nothing about what the page is for.
      # The build owns these texts: a dump is rebuilt from the one before it, so
      # an intro written by an earlier build has to be replaced, not kept.
      def add_home_intros!
        showcase_lectures.each_with_index do |lecture, index|
          text = format(intro_template(lecture, index), title: lecture.course.title)
          # rubocop:disable Rails/SkipsModelValidations
          lecture.update_columns(home_intro: text)
          # rubocop:enable Rails/SkipsModelValidations
        end
        attach_program!
      end

      def intro_template(lecture, index)
        locale = intro_locale(lecture)
        return REGISTRATION_INTROS[locale] if lecture.registration_campaigns.open.any?

        HOME_INTROS[locale][index % HOME_INTROS[locale].size]
      end

      def intro_locale(lecture)
        locale = lecture.locale_with_inheritance.to_s
        HOME_INTROS.key?(locale) ? locale : "de"
      end

      # The home page offers a welcome text and a program; without one of them
      # the page keeps telling its teacher that it is empty.
      def attach_program!
        lecture = Lecture.find_by(id: 1)
        return if lecture.nil? || lecture.home_attachment.present?

        source = Medium.where.not(manuscript_data: nil).first
        return if source.nil?

        lecture.home_attachment = source.manuscript.download
        lecture.save!
      end

      # Announcements stay, but off the landing page, where they greet every
      # visitor before anything else.
      def add_announcements!
        # rubocop:disable Rails/SkipsModelValidations
        Announcement.update_all(on_main_page: false)
        # rubocop:enable Rails/SkipsModelValidations

        ADMIN_ANNOUNCEMENTS.each do |text|
          announce!(Announcement.create!(announcer: admin, details: text,
                                         on_main_page: false))
        end

        current_lectures.each_with_index do |lecture, index|
          text = LECTURE_ANNOUNCEMENTS[index % LECTURE_ANNOUNCEMENTS.size]
          announce!(Announcement.create!(announcer: lecture.teacher,
                                         lecture: lecture, details: text,
                                         on_main_page: false))
        end
      end

      def announce!(announcement)
        recipients = announcement.lecture&.users || User.all
        recipients.find_each do |user|
          Notification.create!(recipient: user, notifiable: announcement,
                               action: "create")
        end
      end

      def add_discussions!
        current_lectures.each do |lecture|
          board = forum_for(lecture)
          TOPICS.each { |title, posts| discuss!(board, lecture, title, posts) }
        end
      end

      def forum_for(lecture)
        return lecture.forum if lecture.forum

        board = Thredded::Messageboard.create!(name: lecture.forum_title)
        lecture.update!(forum_id: board.id)
        board
      end

      def discuss!(board, lecture, title, posts)
        return if Thredded::Topic.exists?(messageboard: board, title: title)

        topic = Thredded::Topic.create!(messageboard: board, title: title,
                                        user: students.first,
                                        last_user: students.first)
        speakers = [students.first, students.second, lecture.teacher].compact
        posts.each_with_index do |content, index|
          Thredded::Post.create!(postable: topic, messageboard: board,
                                 user: speakers[index % speakers.size],
                                 content: content)
        end
      end

      def add_media_comments!
        Medium.limit(10).each do |medium|
          thread = medium.commontator_thread
          next if thread.comments.any?

          COMMENTS.each_with_index do |body, index|
            Commontator::Comment.create!(thread: thread, body: body,
                                         creator: students[index % students.size])
          end
        end
      end

      # Annotations sit on a video timeline, so only media that carry one. Every
      # video gets a few, and the teacher keeps notes on their own lecture.
      def add_annotations!
        annotatable_media.each_with_index do |medium, medium_index|
          students.each_with_index do |student, student_index|
            annotate!(medium, student, STUDENT_NOTES, medium_index + student_index,
                      shared: student_index.even?)
          end

          teacher = medium_teacher(medium)
          annotate!(medium, teacher, TEACHER_NOTES, medium_index) if teacher
        end
      end

      def annotatable_media
        @annotatable_media ||= Medium.where.not(video_data: nil).to_a
      end

      def medium_teacher(medium)
        lecture = medium.teachable.try(:lecture) || medium.teachable
        lecture.try(:teacher)
      end

      # Two per person and video, at spots that do not sit on top of each other.
      def annotate!(medium, user, notes, offset, shared: false)
        existing = Annotation.where(medium_id: medium.id, user_id: user.id).count
        return if existing >= 2

        (2 - existing).times do |run|
          comment, category, subcategory = notes[(offset + run) % notes.size]
          seconds = ANNOTATION_SECONDS[(offset + (run * 3)) % ANNOTATION_SECONDS.size]
          Annotation.create!(medium_id: medium.id, user_id: user.id,
                             comment: comment, category: category,
                             subcategory: subcategory, visible_for_teacher: shared,
                             color: Annotation.colors[(offset % 8) + 1],
                             timestamp: TimeStamp.new(total_seconds: seconds))
        end
      end

      # Students collect what they want to see again; the teacher collects what
      # they keep pointing people at.
      def add_watchlists!
        drop_improper_entries!
        students.each_with_index do |student, index|
          WATCHLIST_NAMES.first(2).each_with_index do |name, run|
            fill_watchlist!(student, "#{name} #{index + 1}", offset: index + run)
          end
        end

        fill_watchlist!(teacher, TEACHER_WATCHLIST_NAME, offset: 2, size: 5) if teacher
      end

      def teacher
        return @teacher if defined?(@teacher)

        @teacher = User.find_by(email: "teacher@mampf.edu")
      end

      # An earlier edition collected a random quiz, which belongs to no lecture
      # and takes the watchlist page down with it.
      def drop_improper_entries!
        WatchlistEntry.joins(:medium).where(media: { sort: "RandomQuiz" }).destroy_all
      end

      def fill_watchlist!(user, name, offset:, size: 3)
        return if Watchlist.exists?(user: user, name: name)

        watchlist = Watchlist.create!(user: user, name: name)
        media = annotatable_media.rotate(offset).first(size)
        media.each_with_index do |medium, position|
          WatchlistEntry.create!(watchlist: watchlist, medium: medium,
                                 medium_position: position + 1)
        end
      end
  end
end
