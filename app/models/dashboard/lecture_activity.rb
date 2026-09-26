module Dashboard
  # Unread forum topics and media comments across a set of lectures, gathered
  # once for the whole board rather than once per card. Also carries the other
  # per-card lookups (registration status, washi tape style) for the same
  # reason.
  class LectureActivity
    IGNORED_MEDIA_SORTS = ["RandomQuiz", "Question", "Remark"].freeze

    def initialize(user:, lectures:)
      @user = user
      @lectures = Array(lectures)
    end

    attr_reader :user, :lectures

    def unread_forum_topics(lecture)
      forum_topic_counts.fetch(lecture.id, 0)
    end

    def unread_comments(lecture)
      comment_counts.fetch(lecture.id, 0)
    end

    # See Lecture#registration_status_for.
    def registration_status(lecture)
      registration_statuses[lecture.id]
    end

    def card_style(lecture)
      card_styles[lecture.id]
    end

    private

      def registration_statuses
        @registration_statuses ||=
          Registration::StatusQuery.new(user, lectures.map(&:id)).statuses
      end

      def card_styles
        @card_styles ||= Dashboard::CardStyle.where(user: user, lecture: lectures)
                                             .index_by(&:lecture_id)
      end

      # One query for all forums, the same count Lecture#unread_forum_topics_count
      # asks for one.
      def forum_topic_counts
        @forum_topic_counts ||= begin
          by_forum = unread_topics_by_forum
          lectures.to_h do |lecture|
            [lecture.id, by_forum.fetch(lecture.forum_id, 0)]
          end
        end
      end

      def unread_topics_by_forum
        forum_ids = lectures.filter_map(&:forum_id)
        return {} if forum_ids.empty?

        topics = Thredded::TopicPolicy::Scope.new(user, Thredded::Topic.all).resolve
        Thredded::Messageboard.where(id: forum_ids)
                              .unread_topics_counts(user: user, topics_scope: topics)
      end

      # Comments somebody else wrote after this user last opened the thread (no
      # `Reader` row means never opened), counted per lecture in one query.
      def comment_counts
        @comment_counts ||= unread_comments_by_teachable
                            .each_with_object(Hash.new(0)) do |((type, id), count), result|
          lecture_id = type == "Lecture" ? id : lecture_ids_by_teachable.dig(type, id)
          result[lecture_id] += count if lecture_id
        end
      end

      def unread_comments_by_teachable
        reader = ActiveRecord::Base.sanitize_sql_array(
          ["LEFT JOIN readers ON readers.thread_id = commontator_threads.id " \
           "AND readers.user_id = ?", user.id]
        )
        Commontator::Comment
          .joins(:thread)
          .joins("INNER JOIN media ON media.id = commontator_threads.commontable_id")
          .joins(reader)
          .where(commontator_threads: { commontable_type: "Medium" })
          .where(media: { id: commentable_media.select(:id) })
          .where(deleted_at: nil)
          .where.not("commontator_comments.creator_type = ? AND " \
                     "commontator_comments.creator_id = ?",
                     user.class.base_class.name, user.id)
          .where("readers.updated_at IS NULL OR " \
                 "readers.updated_at < commontator_comments.created_at")
          .group("media.teachable_type", "media.teachable_id")
          .count
      end

      # Excludes course-level media, which can't be attributed to one lecture,
      # and media the user may not see, whose comments they cannot read.
      def commentable_media
        media = Medium.published.where.not(sort: IGNORED_MEDIA_SORTS)
                      .where.not(released: "locked")
        user.filter_visible_media(
          media.where(teachable: lectures)
               .or(media.where(teachable_type: "Lesson", teachable_id: lessons.select(:id)))
               .or(media.where(teachable_type: "Talk", teachable_id: talks.select(:id)))
        )
      end

      def lecture_ids_by_teachable
        @lecture_ids_by_teachable ||= {
          "Lesson" => lessons.pluck(:id, :lecture_id).to_h,
          "Talk" => talks.pluck(:id, :lecture_id).to_h
        }
      end

      def lessons
        Lesson.where(lecture: lectures)
      end

      def talks
        Talk.where(lecture: lectures)
      end
  end
end
