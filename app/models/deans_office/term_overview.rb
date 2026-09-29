module DeansOffice
  # Collects a term's lecture and group figures for the dean's office. Roster
  # counts are batched and only registration ids are loaded, so the page stays
  # at a fixed number of queries however many lectures the term holds.
  class TermOverview
    GROUP_ASSOCIATIONS = [:tutorials, :talks, :cohorts, :exams].freeze
    GROUP_TYPES = { "tutorial" => Tutorial, "talk" => Talk,
                    "cohort" => Cohort, "exam" => Exam }.freeze
    RUNNING_STATUSES = ["open", "closed", "processing"].freeze

    # Uses Talk#to_label so talk numbers read as on the seminar's own pages.
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
                           .sort_by { |lecture| lecture.course.title.downcase }
    end

    def sections
      seminars, others = lectures.partition(&:seminar?)
      { lectures: others, seminars: seminars }.reject { |_, list| list.empty? }
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

    # Returns the capacities' sum and whether some group has none; with such
    # a group the sum is only a lower bound.
    def seats(lecture)
      capacities = groups(lecture).map(&:capacity)
      [capacities.compact.sum, capacities.include?(nil)]
    end

    Access = Struct.new(:state, :campaign)

    # A campaign whose deadline has passed takes no more registrations, even
    # before the worker closes it, so it counts as allocating already.
    def access(group)
      campaign = item(group)&.registration_campaign
      if campaign && RUNNING_STATUSES.include?(campaign.status)
        Access.new(campaign.open_for_registrations? ? :open : :allocating, campaign)
      elsif campaign&.draft?
        Access.new(:not_open, campaign)
      elsif group.campaign_managed? && !campaign&.completed?
        Access.new(:no_campaign_yet)
      elsif group.config_allow_self_add?
        Access.new(:self_join)
      else
        Access.new(campaign&.completed? ? :completed : :staff_only)
      end
    end

    def accesses(lecture)
      groups(lecture).group_by { |group| access(group) }
    end

    # Matches GroupRowComponent#count, so the dean's office and the teacher
    # see the same figures. Nil without a running campaign.
    def registration_count(group)
      item = running_item(group)
      return unless item
      return item.confirmed_registrations_count if item.registration_campaign
                                                       .first_come_first_served?

      first_choice_counts.fetch(item.id, 0)
    end

    def first_choices?(group)
      item = running_item(group)
      item.present? && !item.registration_campaign.first_come_first_served?
    end

    # Nil without a running campaign, so that no registration at all reads
    # differently from nobody registered yet.
    def registered_people(lecture)
      ids = groups(lecture).filter_map { |group| running_item(group)&.id }
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

      def count_entries(scope, column, group_class)
        scope.where(column => all_groups.grep(group_class).map(&:id)).group(column).count
      end

      # Loads draft and completed campaigns too: access tells a group waiting
      # for its registration from one its teacher manages after it.
      def items_by_group
        @items_by_group ||= Registration::Item.where(registerable: all_groups)
                                              .includes(:registration_campaign)
                                              .index_by do |item|
          [item.registerable_type, item.registerable_id]
        end
      end

      # A group is an item of one campaign at most (unique index on the item).
      def item(group)
        items_by_group[[group.class.name, group.id]]
      end

      def running_item(group)
        found = item(group)
        found if found && RUNNING_STATUSES.include?(found.registration_campaign.status)
      end

      def running_registrations
        ids = all_groups.filter_map { |group| running_item(group)&.id }
        Registration::UserRegistration.where(registration_item_id: ids)
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
