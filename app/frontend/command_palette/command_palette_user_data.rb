# The user's part of the command palette (/command_palette/me.json).
class CommandPaletteUserData
  # The lecture result itself opens the lecture's home page.
  LECTURE_PAGES = LecturePages::ALL.reject { |page| page.key == "home" }.freeze

  def initialize(user)
    @user = user
  end

  def as_json(*)
    { globals: globals, destinations: destinations, lectures: lecture_entries }
  end

  private

    def globals
      globals = CommandPaletteGlobals::ALL.select { |global| global.condition.call(@user) }
      globals.map do |global|
        prefix = "command_palette.globals.#{global.key}"
        { key: global.key, icon: global.icon, path: global.path.call(@user),
          method: "get", **translation("#{prefix}.label", "#{prefix}.keywords") }
      end
    end

    def destinations
      pages = LECTURE_PAGES.map do |page|
        { key: page.key, icon: page.icon,
          **translation(page.label_key, "command_palette.destinations.#{page.key}.keywords") }
      end
      pages + CommandPaletteDestinations::ALL.map do |destination|
        prefix = "command_palette.destinations.#{destination.key}"
        { key: destination.key, icon: destination.icon,
          **translation("#{prefix}.label", "#{prefix}.keywords") }
      end
    end

    # Lecture entries, ordered by favorites first, then by term and title.
    def lecture_entries
      openable = lectures.select { |lecture| openable?(lecture) }
      favorites, others = openable.partition { |lecture| favorite?(lecture) }
      sorted = favorites.sort_by { |lecture| [sort_title(lecture), -term_begin(lecture)] } +
               others.sort_by { |lecture| [-term_begin(lecture), sort_title(lecture)] }
      sorted.map do |lecture|
        CommandPaletteCatalog.entry(lecture, term_distances)
                             .merge(favorite: favorite?(lecture),
                                    participation: participation(lecture),
                                    destinations: destination_paths(lecture))
      end
    end

    # The lectures the user sees on their start page, in any term, and the
    # ones they pinned.
    def lectures
      @lectures ||= Lecture.preload_editors(
        board.lectures_of_any_term
             .or(Lecture.where(id: @user.favorite_lectures.select(:id)))
             .includes(:course, :term).to_a
      )
    end

    def board
      @board ||= Dashboard::Board.new(user: @user, term: nil)
    end

    def openable?(lecture)
      lecture.published? || staff?(lecture)
    end

    def term_distances
      @term_distances ||= CommandPaletteCatalog.term_distances
    end

    def favorite?(lecture)
      @favorite_ids ||= Set.new(@user.favorite_lectures.pluck(:id))
      @favorite_ids.include?(lecture.id)
    end

    def sort_title(lecture)
      lecture.course.short_title.to_s.to_sort_atoms
    end

    def term_begin(lecture)
      (lecture.term&.begin_date || Date.new(0)).jd
    end

    # needs no query as the editors of `lectures` are preloaded
    def staff?(lecture)
      @user.can_edit?(lecture)
    end

    def tutor?(lecture)
      @tutor_ids ||= Set.new(LectureTutors.lectures_of(@user).ids)
      @tutor_ids.include?(lecture.id)
    end

    def cohort_tutor?(lecture)
      @cohort_tutor_ids ||= Set.new(LectureTutors.cohort_lectures_of(@user).ids)
      @cohort_tutor_ids.include?(lecture.id)
    end

    def enrolled?(lecture)
      @enrolled_ids ||= Set.new(LectureAudience.lectures_of(@user, bookmarks: false).ids)
      @enrolled_ids.include?(lecture.id)
    end

    # ranking.ts boosts "staff", "tutor" and "enrolled" over "bookmarked"
    def participation(lecture)
      return "staff" if staff?(lecture)
      return "tutor" if tutor?(lecture) || cohort_tutor?(lecture)
      return "enrolled" if enrolled?(lecture)

      "bookmarked"
    end

    # The pages of the lecture's sidebar that the user can open.
    def destination_paths(lecture)
      paths = lecture_page_paths(lecture)
      return paths unless staff?(lecture)

      # staff has access to all destinations
      CommandPaletteDestinations::ALL.each do |destination|
        paths[destination.key] = destination.path.call(lecture) if destination.offered_for?(lecture)
      end
      paths
    end

    # Unlike the sidebar, this does not check whether a page has content
    # (Lecture#page_available?), as that costs queries for every lecture.
    def lecture_page_paths(lecture)
      accessible = lecture.content_accessible_by?(@user)
      pages = LecturePages.visible(lecture, @user, tutor: tutor?(lecture),
                                                   cohort_tutor: cohort_tutor?(lecture))
      pages.each_with_object({}) do |page, paths|
        next unless LECTURE_PAGES.include?(page)
        next if page.needs_access && !accessible

        path = page.path.call(lecture)
        paths[page.key] = path if path
      end
    end

    # Allow keywords to be passed in any locale, e.g. a user can search for
    # "Übungen" even if their locale is English.
    def translation(label_key, keywords_key)
      keywords = I18n.available_locales.flat_map do |locale|
        [plain_text(I18n.t(label_key, locale: locale)),
         *I18n.t(keywords_key, locale: locale, default: [])]
      end
      { label: plain_text(I18n.t(label_key)), keywords: keywords.uniq }
    end

    # Sidebar labels may contain HTML, e.g. "Organisa&shy;torisches".
    def plain_text(label)
      Nokogiri::HTML5.fragment(label).text.delete("\u00AD")
    end
end
