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

    def any?(lecture)
      unread_forum_topics(lecture).positive? || unread_comments(lecture).positive?
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

      # Counts when someone else commented after this user's last read (missing
      # `Reader` means never read, so every foreign comment counts as new).
      def comment_counts
        @comment_counts ||= commentable_media.each_with_object({}) do |medium, counts|
          lecture_id = lecture_id_of(medium)
          next unless lecture_id

          next unless unread_comment?(medium)

          counts[lecture_id] = counts.fetch(lecture_id, 0) + 1
        end
      end

      def unread_comment?(medium)
        # compared by id so as not to load every comment's creator
        latest = medium.commontator_thread.comments
                       .reject { |comment| own_comment?(comment) }
                       .max_by(&:created_at)
        return false unless latest

        (read_at.fetch(medium.commontator_thread.id, nil) || Time.zone.at(0)) <
          latest.created_at
      end

      def own_comment?(comment)
        comment.creator_type == user.class.base_class.name &&
          comment.creator_id == user.id
      end

      # Excludes course-level media, which can't be attributed to one lecture.
      def commentable_media
        @commentable_media ||=
          Medium.published
                .where.not(sort: IGNORED_MEDIA_SORTS)
                .where.not(released: "locked")
                .where(teachable: teachables)
                .includes(:teachable, commontator_thread: :comments)
                .select { |medium| medium.commontator_thread&.comments&.any? }
      end

      def teachables
        lectures + Lesson.where(lecture: lectures).to_a +
          Talk.where(lecture: lectures).to_a
      end

      def lecture_id_of(medium)
        case medium.teachable
        when Lecture then medium.teachable.id
        else medium.teachable.lecture_id
        end
      end

      def read_at
        @read_at ||= Reader.where(user: user,
                                  thread: commentable_media
                                            .map(&:commontator_thread))
                           .pluck(:thread_id, :updated_at).to_h
      end
  end
end
