module Dashboard
  # What has happened in a set of lectures since the student last looked:
  # unread forum topics, and comments other people left under the lecture's
  # media.
  #
  # Built once for the whole board rather than once per card, because both
  # questions are answered from a handful of queries over all lectures at once
  # and asking them per card would multiply them by the number of cards.
  class LectureActivity
    # Media a student never comments under, so counting them would only ever
    # produce noise.
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

      # Thredded answers this one lecture at a time; there is no grouped count
      # to ask for, and a student's board holds a handful of lectures.
      def forum_topic_counts
        @forum_topic_counts ||= lectures.to_h do |lecture|
          [lecture.id, lecture.unread_forum_topics_count(user).to_i]
        end
      end

      # A medium counts when somebody else has commented on it after the last
      # time this user opened its thread. Never having opened it makes every
      # foreign comment new, which is what `Reader` missing means.
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

      # Restricted to what belongs to one lecture: media hanging off the course
      # are shared by all of its lectures and could not be attributed to any
      # single card.
      #
      # The student is subscribed to these lectures, so the only visibility
      # left to check is whether the medium is out at all, which is a scope
      # rather than a per-medium question.
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
