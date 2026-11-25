# All published lectures for the command palette. The list is the same for
# every user (editors get their unpublished ones via CommandPaletteUserData).
module CommandPaletteCatalog
  ROUTES = Rails.application.routes.url_helpers

  module_function

  def entries
    Rails.cache.fetch(["command_palette/catalog", version]) do
      distances = term_distances
      Lecture.published.includes(:course, :term)
             .map { |lecture| entry(lecture, distances) }
    end
  end

  # The fields by which the palette finds and shows a lecture.
  def entry(lecture, term_distances)
    { id: lecture.id,
      path: ROUTES.lecture_path(lecture),
      title: lecture.course.title,
      short: lecture.course.short_title,
      term: lecture.term&.to_label_short,
      term_distance: term_distances[lecture.term_id] }
  end

  # Maps each term's id to how far it lies from Term.active in
  # Term.chronological, in either direction; ranking.ts lowers a lecture's
  # weight by it.
  def term_distances
    ids = Term.chronological.ids
    active = ids.index(Term.active&.id)
    return {} if active.nil?

    ids.each_with_index.to_h { |id, position| [id, (position - active).abs] }
  end

  def version
    [Lecture, Course, Term].map { |model| model.maximum(:updated_at)&.to_i } +
      [Lecture.count, Term.active&.id]
  end
end
