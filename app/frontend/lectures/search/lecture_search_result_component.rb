# Renders one lecture of the lecture search (dashboard search, /search/index)
# with what the student can still do about it: register, bookmark it, or see
# how the registration stands. The PageIds of the whole result page answer
# these, so a card does not ask the database per lecture.
class LectureSearchResultComponent < ViewComponent::Base
  # ID sets/statuses for one page of lecture search results, computed once
  # per request by LecturesController#search rather than once per card.
  PageIds = Struct.new(:bookmarked_lecture_ids,
                       :registration_status_by_lecture_id,
                       :rosterized_lecture_ids,
                       :self_enrollable_lecture_ids, keyword_init: true)

  MARKED_STATUSES = [:confirmed, :pending, :rejected].freeze

  with_collection_parameter :lecture

  def initialize(lecture:, ids:, user:, show_term: true)
    super()
    @lecture = lecture
    @ids = ids
    @user = user
    @show_term = show_term
  end

  attr_reader :lecture

  # The registration shown by a marker on the right edge. It is nil for a
  # plain self-enrolled roster seat with no registration of its own, and for
  # :open (no application from this user yet - that case only shows the
  # "+ register" shortcut, not the marker).
  def marker_status
    registration_status if registration_status.in?(MARKED_STATUSES)
  end

  def registered?
    marker_status.present? || rosterized?
  end

  # Consults self_enrollable_lecture_ids only once being registered has been
  # ruled out, because that set ignores whether the user is a member.
  def registration_possible?
    !registered? &&
      (registration_status == :open ||
       @ids.self_enrollable_lecture_ids&.include?(lecture.id))
  end

  # Once there is a registration on record - pending, confirmed or
  # rejected - the lecture already sits in "You are registered for these";
  # bookmarking it too would be redundant. Only a lecture with no
  # application at all (or one still open, not yet applied to) can be
  # bookmarked.
  # A lecture behind a passphrase cannot be bookmarked from here (see
  # Lecture#bookmarkable_by?), so it gets no toggle unless it already is.
  def bookmarkable?
    marker_status.nil? && !rosterized? &&
      (bookmarked? || !lecture.restricted? || lecture.bookmarkable_by?(@user))
  end

  def bookmarked?
    @ids.bookmarked_lecture_ids&.include?(lecture.id) || false
  end

  def show_term?
    @show_term && lecture.term.present?
  end

  def wrapper_attributes
    classes = ["lecture-search-result-wrap",
               ("is-bookmarked" if bookmarkable? && bookmarked?)]
    return { class: classes } unless bookmarkable?

    { class: classes,
      data: { controller: "bookmark",
              bookmark_url_value: dashboard_bookmark_path(lecture),
              bookmark_bookmarked_value: bookmarked?,
              bookmark_lecture_id_value: lecture.id } }
  end

  # Keeps the plain "registered" wording for a self-enrolled group membership
  # with no formal application of its own; the other three statuses get the
  # same icon and label as the dashboard.
  def registered_label
    return t("lecture.search.registered_status") unless marker_status

    helpers.registration_status_label(marker_status)
  end

  def registered_icon
    return "bi-check-circle-fill text-success" unless marker_status

    helpers.registration_status_icon(marker_status)
  end

  def image_url
    return "/no_course_information.png" unless lecture.course.normalized_image_file

    image_course_path(lecture.course, variant: "normalized")
  end

  private

    def registration_status
      @ids.registration_status_by_lecture_id&.[](lecture.id)
    end

    def rosterized?
      @ids.rosterized_lecture_ids&.include?(lecture.id)
    end
end
