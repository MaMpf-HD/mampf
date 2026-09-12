module Dashboard
  # Unread forum topics and media comments across a set of lectures, gathered
  # once for the whole board rather than once per card.
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

    private

      def forum_topic_counts
        @forum_topic_counts ||= lectures.to_h do |lecture|
          [lecture.id, lecture.unread_forum_topics_count(user).to_i]
        end
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
        latest = medium.commontator_thread.comments
                       .reject { |comment| comment.creator == user }
                       .max_by(&:created_at)
        return false unless latest

        (read_at.fetch(medium.commontator_thread.id, nil) || Time.zone.at(0)) <
          latest.created_at
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
