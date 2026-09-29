module DeansOffice
  # Gathers what the dean's office sees of one term: every lecture with its
  # groups, how many have registered for them and how full they are, in a
  # fixed number of queries however many lectures the term holds. Members are
  # counted, not loaded, since a term holds thousands of them.
  class TermOverview
    GROUP_ASSOCIATIONS = [:tutorials, :talks, :cohorts, :exams].freeze
    GROUP_TYPES = { "tutorial" => Tutorial, "talk" => Talk,
                    "cohort" => Cohort, "exam" => Exam }.freeze

    # Talks are listed by their number, as the seminar lists them.
    def self.group_title(group)
      group.is_a?(Talk) ? group.to_label : group.title
    end

    def self.group_type(group)
      GROUP_TYPES.key(group.class)
    end

    def initialize(term)
      @term = term
    end

    def lectures
      return [] unless @term

      @lectures ||= Lecture.where(term: @term)
                           .includes(:course, :term, :teacher, *GROUP_ASSOCIATIONS)
                           .sort_by { |lecture| lecture.title_no_term.downcase }
    end

    def groups(lecture)
      GROUP_ASSOCIATIONS.flat_map { |association| lecture.public_send(association).to_a }
    end

    def member_count(lecture)
      member_counts.fetch(lecture.id, 0)
    end

    def roster_count(group)
      roster_counts.fetch(group.class).fetch(group.id, 0)
    end

    # The seats the lecture's groups offer together, and whether one of them
    # has no limit, which makes the sum a lower bound.
    def seats(lecture)
      capacities = groups(lecture).map(&:capacity)
      [capacities.compact.sum, capacities.include?(nil)]
    end

    # The registrations of the group's running campaign, counted as its
    # campaign card counts them: confirmed ones first come, first served, the
    # first choices when preferences are allocated. Nil without such a campaign.
    def registration_count(group)
      item = running_items[[group.class.name, group.id]]
      return unless item
      return item.confirmed_registrations_count if item.registration_campaign
                                                       .first_come_first_served?

      first_choice_counts.fetch(item.id, 0)
    end

    def first_choices?(group)
      item = running_items[[group.class.name, group.id]]
      item.present? && !item.registration_campaign.first_come_first_served?
    end

    # The people who registered for any of the lecture's groups, each once.
    # Nil while none of its groups has a running campaign.
    def registered_people(lecture)
      ids = groups(lecture).filter_map { |group| running_items[[group.class.name, group.id]]&.id }
      return if ids.empty?

      registered_users_by_item.values_at(*ids).compact.reduce(Set.new, :|).size
    end

    private

      def all_groups
        @all_groups ||= lectures.flat_map { |lecture| groups(lecture) }
      end

      def member_counts
        @member_counts ||= LectureMembership.where(lecture: lectures).group(:lecture_id).count
      end

      def roster_counts
        @roster_counts ||= {
          Tutorial => count_entries(TutorialMembership, :tutorial_id, Tutorial),
          Talk => count_entries(SpeakerTalkJoin, :talk_id, Talk),
          Cohort => count_entries(CohortMembership, :cohort_id, Cohort),
          Exam => count_entries(ExamRosterEntry.active, :exam_id, Exam)
        }
      end

      def count_entries(entries, column, group_class)
        entries.where(column => all_groups.grep(group_class).map(&:id)).group(column).count
      end

      def running_items
        @running_items ||= Registration::Item.running.where(registerable: all_groups)
                                             .includes(:registration_campaign)
                                             .index_by do |item|
          [item.registerable_type, item.registerable_id]
        end
      end

      def running_registrations
        Registration::UserRegistration.where(registration_item_id: running_items.values.map(&:id))
      end

      def first_choice_counts
        @first_choice_counts ||= running_registrations.where(preference_rank: 1)
                                                      .group(:registration_item_id).count
      end

      def registered_users_by_item
        @registered_users_by_item ||= running_registrations.where.not(status: :rejected)
                                                           .pluck(:registration_item_id, :user_id)
                                                           .group_by(&:first)
                                                           .transform_values do |pairs|
          pairs.to_set(&:last)
        end
      end
  end
end
