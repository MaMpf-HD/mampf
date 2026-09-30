module DeansOffice
  # Collects a term's figures for the dean's office, which pays for the
  # tutorials by fixed quotas: per lecture how many students, how many groups,
  # and how far the registration has got; per seminar the same for its talks.
  # Everything is loaded per term, so the page stays at a fixed number of
  # queries however many courses the term holds.
  class TermOverview
    GROUP_ASSOCIATIONS = [:tutorials, :talks, :cohorts, :exams].freeze
    GROUP_TYPES = { "tutorial" => Tutorial, "talk" => Talk,
                    "cohort" => Cohort, "exam" => Exam }.freeze
    RUNNING_STATUSES = ["open", "closed", "processing"].freeze

    # The dean's office sees five phases, in the order a term runs through
    # them: whether people got their places by an allocation or from the
    # teacher is the teacher's business. Groups students join themselves are a
    # phase of their own while they are open: their figure is people, not
    # registrations. A course is in the first phase any of its groups is in.
    PHASES = { open: :open, allocating: :allocating, self_join: :self_join,
               completed: :assigned, not_open: :preparing }.freeze
    PHASE_ORDER = [:open, :allocating, :self_join, :assigned, :preparing].freeze
    # A course's line names what is settled first.
    LINE_ORDER = [:assigned, :self_join, :allocating, :open, :preparing].freeze

    Access = Struct.new(:state, :campaign)

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
                           .includes(:course, :term, :teacher, :editors, *GROUP_ASSOCIATIONS)
                           .sort_by { |lecture| lecture.course.title.downcase }
    end

    # Lectures first: the tutorials the dean's office pays for are theirs.
    def sections
      seminars, others = lectures.partition(&:seminar?)
      { lectures: others, seminars: seminars }.reject { |_, list| list.empty? }
    end

    # Orders courses by title, or by the phase of their registration with the
    # soonest deadline first among the open ones.
    def ordered(courses, by_phase: false)
      return courses unless by_phase

      courses.sort_by.with_index do |course, index|
        [PHASE_ORDER.index(phase(course)), deadline(course) || Time.zone.at(0), index]
      end
    end

    # A course's registration is about its tutorials, or a seminar's talks;
    # without those, about its other groups. Exams never decide it: they do
    # not bear on the places the dean's office pays for.
    def main_groups(course)
      primary = course.seminar? ? course.talks.to_a : course.tutorials.to_a
      primary.presence || course.cohorts.to_a
    end

    def registered?(course)
      main_groups(course).any?
    end

    # The phases the course's groups are in, in the order of PHASE_ORDER.
    def phases(course)
      main_groups(course).map { |group| group_phase(group) }.uniq
                         .sort_by { |phase| PHASE_ORDER.index(phase) }
    end

    # A group outside any registration counts as allocated once the teacher
    # has put somebody in it; until then nothing has happened to it yet.
    def group_phase(group)
      state = access(group).state
      return PHASES[state] if PHASES.key?(state)

      roster_count(group).positive? ? :assigned : :preparing
    end

    # Every group of the course but its exams, by phase, in LINE_ORDER.
    def groups_by_phase(course)
      (course.tutorials + course.talks + course.cohorts)
        .group_by { |group| group_phase(group) }
        .sort_by { |phase, _| LINE_ORDER.index(phase) }
    end

    def phase(course)
      phases(course).first
    end

    # The deadline of the course's open registration closing soonest.
    def deadline(course)
      main_groups(course).map { |group| access(group) }
                         .select { |access| access.state == :open }
                         .map { |access| access.campaign.registration_deadline }.min
    end

    # Everybody in the course or one of its groups and everybody registered
    # in a registration still running, each person once; exams left out.
    def students(course)
      (participants(course) | registered_people(course)).size
    end

    def talks_assigned(seminar)
      seminar.talks.count { |talk| roster_count(talk).positive? }
    end

    def teachers(course)
      [course.teacher, *course.editors.sort_by { |user| person_name(user).downcase }]
        .compact.uniq
    end

    # The name from the personal data where given, else the display name.
    def person_name(user)
      user.full_name || user.name.to_s
    end

    # The registration a group is handed out by while it is running or being
    # prepared; nil once it is completed or where there is none.
    def campaign(group)
      found = item(group)&.registration_campaign
      found unless found.nil? || found.completed?
    end

    def groups(course)
      GROUP_ASSOCIATIONS.flat_map { |association| course.public_send(association).to_a }
    end

    def roster_count(group)
      roster_ids.fetch(group.class).fetch(group.id, Set.new).size
    end

    # How many people a group has. While its registration runs, its
    # registrations, as the lecturer's campaign card counts them: those
    # confirmed, or where places go by preference, the first choices.
    def group_count(group)
      found = item(group)
      return roster_count(group) unless found && running?(found)
      return found.confirmed_registrations_count if found.registration_campaign
                                                         .first_come_first_served?

      first_choice_counts.fetch(found.id, 0)
    end

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

    private

      def running?(item)
        RUNNING_STATUSES.include?(item.registration_campaign.status)
      end

      # People registered for any of the course's groups but its exams, each
      # once; rejected registrations left out.
      def registered_people(course)
        registered_users((course.tutorials + course.talks + course.cohorts)
                           .filter_map { |group| item(group) }
                           .select { |item| running?(item) })
      end

      def registered_users(items)
        registered_users_by_item.values_at(*items.map(&:id)).compact.reduce(Set.new, :|)
      end

      # The lecture's own list and every list of its groups but the exams',
      # each person once.
      def participants(course)
        lists = [lecture_member_ids.fetch(course.id, Set.new)]
        (course.tutorials + course.talks + course.cohorts).each do |group|
          lists << roster_ids.fetch(group.class).fetch(group.id, Set.new)
        end
        lists.reduce(Set.new, :|)
      end

      def all_groups
        @all_groups ||= lectures.flat_map { |lecture| groups(lecture) }
      end

      def lecture_member_ids
        @lecture_member_ids ||= id_sets(LectureMembership.where(lecture: lectures), :lecture_id)
      end

      def roster_ids
        @roster_ids ||= {
          Tutorial => roster_sets(TutorialMembership, :tutorial_id, Tutorial),
          Talk => roster_sets(SpeakerTalkJoin, :talk_id, Talk, user: :speaker_id),
          Cohort => roster_sets(CohortMembership, :cohort_id, Cohort),
          Exam => roster_sets(ExamRosterEntry.active, :exam_id, Exam)
        }
      end

      def roster_sets(scope, column, group_class, user: :user_id)
        id_sets(scope.where(column => all_groups.grep(group_class).map(&:id)), column,
                user: user)
      end

      def id_sets(scope, column, user: :user_id)
        scope.pluck(column, user).group_by(&:first)
             .transform_values { |pairs| pairs.to_set(&:last) }
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

      def running_registrations
        ids = items_by_group.values.select { |found| running?(found) }.map(&:id)
        Registration::UserRegistration.where(registration_item_id: ids)
      end

      def first_choice_counts
        @first_choice_counts ||= running_registrations.where(preference_rank: 1)
                                                      .where.not(status: :rejected)
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
