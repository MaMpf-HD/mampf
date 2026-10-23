module DeansOffice
  # Collects course and group counts for the dean's office's tutorial
  # planning. Loads memberships and registrations per term, so the page does
  # not ask the database once per course.
  class TermOverview
    # Exams stay out: they do not bear on the tutorials the dean's office pays
    # for.
    GROUP_ASSOCIATIONS = [:tutorials, :talks, :cohorts].freeze
    RUNNING_STATUSES = ["open", "closed", "processing"].freeze

    # Prioritizes open main-group registrations when placing courses in phase
    # sections. This order is not a timeline: a registration can reopen.
    PHASES = { open: :open, allocating: :allocating, self_join: :self_join,
               completed: :assigned, not_open: :preparing }.freeze
    PHASE_ORDER = [:open, :allocating, :self_join, :assigned, :preparing, :untracked].freeze
    # Shows assigned groups first within a course, so existing membership
    # reads before provisional registration counts.
    LINE_ORDER = [:assigned, :self_join, :allocating, :open, :preparing, :untracked].freeze

    Access = Struct.new(:state, :campaign)

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

    def ordered(courses, by_phase: false)
      return courses unless by_phase

      courses.sort_by.with_index do |course, index|
        [PHASE_ORDER.index(phase(course)), deadline(course) || Time.zone.at(0), index]
      end
    end

    # Uses tutorials for a lecture's phase and talks for a seminar's.
    # Supplementary groups must not change the phase of those main groups.
    def main_groups(course)
      primary = course.seminar? ? course.talks.to_a : course.tutorials.to_a
      primary.presence || course.cohorts.to_a
    end

    # Whether the course gets a line of its own rather than only its name in
    # the list of courses without registration: a registration prepared
    # before any group counts too.
    def in_table?(course)
      main_groups(course).any? || bare_campaigns.key?(course.id)
    end

    def phases(course)
      found = main_groups(course).map { |group| group_phase(group) }.uniq
                                 .sort_by { |phase| PHASE_ORDER.index(phase) }
      found.presence || (bare_campaigns.key?(course.id) ? [:preparing] : [])
    end

    # Uses current membership for groups without a registration, because the
    # teacher may hand out places directly or students may have signed up.
    def group_phase(group)
      return :untracked if untracked?(group.lecture)

      state = access(group).state
      return PHASES[state] if PHASES.key?(state)

      roster_count(group).positive? ? :assigned : :preparing
    end

    def past_term?
      return @past_term if defined?(@past_term)

      active = Term.active
      @past_term = @term.present? && active.present? && @term.begin_date < active.begin_date
    end

    # Tells a course of a past term that never had a registration nor anybody
    # in it: rosters came to MaMpf later, so its students were not recorded,
    # and nothing is still to begin.
    def untracked?(course)
      past_term? && students(course).zero? && !bare_campaigns.key?(course.id) &&
        groups(course).none? { |group| item(group) }
    end

    # Leaves out the phase that only a past term has, where it cannot occur.
    def listed_phases
      past_term? ? PHASE_ORDER : PHASE_ORDER - [:untracked]
    end

    def groups_by_phase(course)
      groups(course).group_by { |group| group_phase(group) }
                    .sort_by { |phase, _| LINE_ORDER.index(phase) }
    end

    def phase(course)
      phases(course).first
    end

    def deadline(course)
      main_groups(course).map { |group| access(group) }
                         .select { |access| access.state == :open }
                         .map { |access| access.campaign.registration_deadline }.min
    end

    # Counts existing participants together with applicants, so settled groups
    # stay represented while another registration is open.
    def students(course)
      student_ids(course).size
    end

    def student_ids(course)
      @student_ids ||= {}
      @student_ids[course.id] ||= participants(course) | registered_people(course)
    end

    # Counts the students column by study program, from one read of every
    # student's program per term, as the page reads everything else.
    def program_distribution(course)
      pairs = student_ids(course).filter_map { |id| student_programs[id] }
      ProgramDistribution.from_pairs(pairs, programs: programs_by_id)
    end

    def talks_assigned(seminar)
      seminar.talks.count { |talk| roster_count(talk).positive? }
    end

    def teachers(course)
      [course.teacher, *course.editors.sort_by { |user| person_name(user).downcase }]
        .compact.uniq
    end

    def person_name(user)
      user.full_name || user.name.to_s
    end

    # Keeps draft and running registrations attached to detail sections, so
    # their mode can be explained; completed ones have nothing left to say.
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

    # Uses registration counts before finalization, because current
    # membership does not show the registration yet; counted as the
    # lecturer's campaign card counts them.
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

      def registered_people(course)
        registered_users(groups(course).filter_map { |group| item(group) }
                                       .select { |item| running?(item) })
      end

      def registered_users(items)
        registered_users_by_item.values_at(*items.map(&:id)).compact.reduce(Set.new, :|)
      end

      # Includes the lecture roster, because students can belong to a course
      # without joining a group.
      def participants(course)
        lists = [lecture_member_ids.fetch(course.id, Set.new)]
        groups(course).each do |group|
          lists << roster_ids.fetch(group.class).fetch(group.id, Set.new)
        end
        lists.reduce(Set.new, :|)
      end

      def student_programs
        @student_programs ||= begin
          ids = lectures.map { |lecture| student_ids(lecture) }.reduce(Set.new, :|)
          User.where(id: ids.to_a).pluck(:id, :program_id, :personal_data_confirmed_at)
              .to_h { |id, program_id, confirmed_at| [id, [program_id, confirmed_at.present?]] }
        end
      end

      def programs_by_id
        @programs_by_id ||= Program.includes(:translations, subject: :translations)
                                   .where(id: student_programs.values.filter_map(&:first).uniq)
                                   .index_by(&:id)
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
          Cohort => roster_sets(CohortMembership, :cohort_id, Cohort)
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

      # Registrations a lecturer has set up before adding any group; they are
      # found through no group, so they are asked for by lecture.
      def bare_campaigns
        @bare_campaigns ||= Registration::Campaign.where(campaignable: lectures)
                                                  .where.missing(:registration_items)
                                                  .index_by(&:campaignable_id)
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
