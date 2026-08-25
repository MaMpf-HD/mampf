module Seeds
  # Fills the seed data with the everyday material a new developer needs to see
  # the app working: announcements, forum discussions, comments, annotations
  # and watchlists.
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

    COMMENTS = [
      "Ab Minute 12 ist der Ton etwas leise.",
      "Sehr schön erklärt, danke!",
      "Gibt es dazu noch ein weiteres Beispiel?"
    ].freeze

    def enrich!
      refresh_forum_names!
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
        @current_lectures ||= Lecture.where(term: Term.active).to_a
      end

      # The forum name carries the term, which the year shift has moved on.
      def refresh_forum_names!
        Lecture.where.not(forum_id: nil).find_each do |lecture|
          lecture.forum&.update!(name: lecture.forum_title)
        end
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

      # Annotations sit on a video timeline, so only media that carry one.
      def add_annotations!
        Medium.where.not(video_data: nil).limit(8).each do |medium|
          students.first(3).each do |student|
            next if Annotation.exists?(medium_id: medium.id, user_id: student.id)

            FactoryBot.create(:annotation, :with_text,
                              medium_id: medium.id, user_id: student.id)
          end
        end
      end

      def add_watchlists!
        media = Medium.limit(6).to_a
        students.each_with_index do |student, index|
          next if Watchlist.exists?(user: student)

          watchlist = Watchlist.create!(user: student,
                                        name: "Wiederholung #{index + 1}")
          media.sample(3).each_with_index do |medium, position|
            WatchlistEntry.create!(watchlist: watchlist, medium: medium,
                                   medium_position: position + 1)
          end
        end
      end
  end
end
