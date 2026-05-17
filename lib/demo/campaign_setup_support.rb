module Demo
  module CampaignSetupSupport
    extend self

    PREFERENCE_CAMPAIGN_DESCRIPTION = "Solver Test Campaign".freeze
    MIXED_FCFS_CAMPAIGN_DESCRIPTION = "Cohort FCFS Campaign".freeze
    PLANNING_CAMPAIGN_DESCRIPTION = "Stage 1: Planning".freeze
    ALLOCATION_CAMPAIGN_DESCRIPTION = "Stage 2: Allocation".freeze
    NACHRUECKER_CAMPAIGN_DESCRIPTION = "Stage 3: Nachrücker (FCFS)".freeze
    TWO_STAGE_COURSE_TITLE = "Campaign Test Seminar".freeze

    def setup!
      Demo::SetupSupport.setup_flags!
      Demo::QuietLoggingSupport.with_quiet_logging do
        setup_preference_campaign!
        seed_preference_campaign_registrations!
        setup_mixed_fcfs_campaign!
        seed_mixed_fcfs_campaign_registrations!
        setup_two_stage_campaign!
      end
    end

    def setup_preference_campaign!
      ensure_non_production!

      output("Creating solver campaign...")

      lecture = lecture!
      output("Using lecture: #{lecture.title} (ID: #{lecture.id})")
      output("Using teacher: #{teacher!.name} (ID: #{teacher!.id})")

      campaign = Registration::Campaign.find_by(
        campaignable: lecture,
        description: PREFERENCE_CAMPAIGN_DESCRIPTION
      )

      if campaign
        output("Campaign already exists: #{campaign.id}")
      else
        campaign = FactoryBot.create(
          :registration_campaign,
          campaignable: lecture,
          status: :draft,
          allocation_mode: :preference_based,
          registration_deadline: 1.week.from_now,
          description: PREFERENCE_CAMPAIGN_DESCRIPTION
        )
        output("Created campaign: #{campaign.id}")
      end

      [20, 15, 10, 5].each_with_index do |capacity, index|
        title = "Tutorial #{index + 1}"
        tutorial = Tutorial.find_by(lecture: lecture, title: title)

        if tutorial
          output("Tutorial #{index + 1} already exists")
          tutorial.update!(capacity: capacity)
        else
          tutorial = FactoryBot.create(
            :tutorial,
            lecture: lecture,
            title: title,
            capacity: capacity
          )
          output("Created Tutorial #{index + 1} with capacity #{capacity}")
        end

        next if Registration::Item.exists?(
          registration_campaign: campaign,
          registerable: tutorial
        )

        FactoryBot.create(
          :registration_item,
          registration_campaign: campaign,
          registerable: tutorial
        )
        output("Added Tutorial #{index + 1} to campaign")
      end

      return unless campaign.draft?

      campaign.update!(status: :open)
      output("Opened campaign")
    end

    def seed_preference_campaign_registrations!
      ensure_non_production!

      campaign = Registration::Campaign.where(
        description: PREFERENCE_CAMPAIGN_DESCRIPTION
      ).last
      unless campaign
        output("Campaign not found. Run demo:campaigns first.")
        return
      end

      output("Cleaning up old registrations...")
      campaign.user_registrations.destroy_all

      items = campaign.registration_items.includes(:registerable).to_a.sort_by do |item|
        item.registerable.capacity
      end
      small_room = items[0]
      medium_room = items[1]

      total_capacity = items.sum { |item| item.registerable.capacity }
      num_users = 55

      output("Creating #{num_users} users (Total Cap #{total_capacity}). Scenario: Picky Eaters...")
      output("Most users will ONLY pick the small/medium rooms,")
      output("forcing the solver to assign them to large rooms against their will.")
      output(
        "Since there are more users than spots, " \
        "#{num_users - total_capacity} users will remain unassigned."
      )

      num_users.times do |index|
        email = "solver_user_#{index}@example.com"
        user = User.find_by(email: email)
        user ||= FactoryBot.create(
          :confirmed_user,
          email: email,
          name: "Solver User #{index}"
        )

        selected_items = if rand < 0.9
          [small_room, medium_room].shuffle.take(rand(1..2))
        else
          items.shuffle.take(3)
        end

        selected_items.each_with_index do |item, rank|
          FactoryBot.create(
            :registration_user_registration,
            user: user,
            registration_campaign: campaign,
            registration_item: item,
            preference_rank: rank + 1,
            status: :pending
          )
        end
      end

      output("Done.")
    end

    def setup_mixed_fcfs_campaign!
      ensure_non_production!

      output("Creating Mixed FCFS campaign...")

      lecture = lecture!
      campaign = Registration::Campaign.find_by(
        campaignable: lecture,
        description: MIXED_FCFS_CAMPAIGN_DESCRIPTION
      )

      if campaign
        output("Campaign already exists: #{campaign.id}")
      else
        campaign = FactoryBot.create(
          :registration_campaign,
          campaignable: lecture,
          status: :draft,
          allocation_mode: :first_come_first_served,
          registration_deadline: 1.week.from_now,
          description: MIXED_FCFS_CAMPAIGN_DESCRIPTION
        )
        output("Created campaign: #{campaign.id}")
      end

      unless campaign.registration_policies.exists?(kind: :institutional_email)
        FactoryBot.create(
          :registration_policy,
          registration_campaign: campaign,
          kind: :institutional_email,
          config: { "allowed_domains" => "example.com" },
          phase: :finalization
        )
        output("Added institutional email policy (example.com, finalization only)")
      end

      [12, 10, 8].each_with_index do |capacity, index|
        title = "FCFS Tutorial #{index + 5}"
        tutorial = Tutorial.find_by(lecture: lecture, title: title)

        if tutorial
          output("#{title} already exists")
          tutorial.update!(capacity: capacity)
        else
          tutorial = FactoryBot.create(
            :tutorial,
            lecture: lecture,
            title: title,
            capacity: capacity
          )
          output("Created #{title} with capacity #{capacity}")
        end

        next if Registration::Item.exists?(
          registration_campaign: campaign,
          registerable: tutorial
        )

        FactoryBot.create(
          :registration_item,
          registration_campaign: campaign,
          registerable: tutorial
        )
        output("Added #{title} to campaign")
      end

      repeaters = Cohort.find_by(
        context_type: Lecture,
        context_id: lecture.id,
        title: "Repeaters"
      )

      if repeaters
        output("Repeaters cohort already exists")
      else
        repeaters = FactoryBot.create(
          :cohort,
          context: lecture,
          title: "Repeaters",
          capacity: 15,
          propagate_to_lecture: true
        )
        output("Created Repeaters cohort (propagates to lecture)")
      end

      unless Registration::Item.exists?(
        registration_campaign: campaign,
        registerable: repeaters
      )
        FactoryBot.create(
          :registration_item,
          registration_campaign: campaign,
          registerable: repeaters
        )
        output("Added Repeaters to campaign")
      end

      waitlist = Cohort.find_by(
        context_type: Lecture,
        context_id: lecture.id,
        title: "Waitlist"
      )

      if waitlist
        output("Waitlist cohort already exists")
      else
        waitlist = FactoryBot.create(
          :cohort,
          context: lecture,
          title: "Waitlist",
          capacity: 20,
          propagate_to_lecture: false
        )
        output("Created Waitlist cohort (does NOT propagate to lecture)")
      end

      unless Registration::Item.exists?(
        registration_campaign: campaign,
        registerable: waitlist
      )
        FactoryBot.create(
          :registration_item,
          registration_campaign: campaign,
          registerable: waitlist
        )
        output("Added Waitlist to campaign")
      end

      return unless campaign.draft?

      campaign.update!(status: :open)
      output("Opened campaign")
    end

    def seed_mixed_fcfs_campaign_registrations!
      ensure_non_production!

      campaign = Registration::Campaign.where(
        description: MIXED_FCFS_CAMPAIGN_DESCRIPTION
      ).last
      unless campaign
        output("Campaign not found. Run demo:campaigns first.")
        return
      end

      output("Cleaning up old registrations...")
      campaign.user_registrations.destroy_all

      tutorials = campaign.registration_items.includes(:registerable)
                          .where(registerable_type: "Tutorial")
                          .to_a
      repeaters = Cohort.find_by(title: "Repeaters")
      waitlist = Cohort.find_by(title: "Waitlist")
      repeaters_item = campaign.registration_items.find_by(
        registerable_type: "Cohort",
        registerable: repeaters
      )
      waitlist_item = campaign.registration_items.find_by(
        registerable_type: "Cohort",
        registerable: waitlist
      )

      tutorial_capacity = tutorials.sum { |item| item.registerable.capacity }
      repeaters_capacity = repeaters_item.registerable.capacity
      waitlist_capacity = waitlist_item.registerable.capacity
      total_capacity = tutorial_capacity + repeaters_capacity + waitlist_capacity

      output("Campaign structure:")
      output("- Tutorials: #{tutorials.count} (capacity #{tutorial_capacity})")
      output("- Repeaters cohort: capacity #{repeaters_capacity} (propagates to lecture)")
      output("- Waitlist cohort: capacity #{waitlist_capacity} (does NOT propagate)")
      output("- Total capacity: #{total_capacity}")

      target_repeaters = 5
      target_waitlist = 12
      num_users = tutorial_capacity + target_repeaters + target_waitlist

      output("\nCreating registrations for #{num_users} users...")
      output("Scenario: Tutorials full, repeaters partially filled, waitlist has more")

      registered_count = 0
      repeaters_count = 0
      waitlist_count = 0
      violator_indices = [2, 7, 14, 19, 33].to_set

      num_users.times do |index|
        domain = violator_indices.include?(index) ? "external.org" : "example.com"
        email = "cohort_user_#{index}@#{domain}"
        user = User.find_by(email: email)
        user ||= FactoryBot.create(
          :confirmed_user,
          email: email,
          name: "Cohort User #{index}"
        )

        item = tutorials.find do |tutorial|
          tutorial.confirmed_registrations_count < tutorial.registerable.capacity
        end

        if !item && repeaters_count < target_repeaters
          item = repeaters_item
          repeaters_count += 1
        end

        if !item && waitlist_count < target_waitlist
          item = waitlist_item
          waitlist_count += 1
        end

        unless item
          output("Campaign full! User #{index} cannot register.")
          next
        end

        FactoryBot.create(
          :registration_user_registration,
          user: user,
          registration_campaign: campaign,
          registration_item: item,
          status: :confirmed
        )

        item.reload
        registered_count += 1
      end

      output("\nDone. Created registrations for #{registered_count} students.")
      output("Final distribution:")
      tutorials.each do |tutorial|
        output(
          " #{tutorial.registerable.title}: " \
          "#{tutorial.confirmed_registrations_count}/" \
          "#{tutorial.registerable.capacity}"
        )
      end
      output(" Repeaters: #{repeaters_item.confirmed_registrations_count}/#{repeaters_capacity}")
      output(" Waitlist: #{waitlist_item.confirmed_registrations_count}/#{waitlist_capacity}")
    end

    def setup_two_stage_campaign!
      ensure_non_production!

      output("Creating two-stage seminar campaign...")

      teacher = teacher!
      course = Course.find_by(title: TWO_STAGE_COURSE_TITLE)
      unless course
        course = FactoryBot.create(
          :course,
          title: TWO_STAGE_COURSE_TITLE,
          short_title: "CTS"
        )
        output("Created Course: #{course.title}")
      end

      seminar = Lecture.find_by(course: course, teacher: teacher)
      unless seminar
        seminar = FactoryBot.create(
          :seminar,
          course: course,
          teacher: teacher,
          released: true,
          term: Term.active || FactoryBot.create(:term)
        )
        output("Created Seminar Lecture")
      end

      unless teacher.favorite_lectures.exists?(seminar.id)
        teacher.lectures << seminar
        output("Subscribed teacher to seminar")
      end

      campaign1 = Registration::Campaign.find_by(
        campaignable: seminar,
        description: PLANNING_CAMPAIGN_DESCRIPTION
      )
      if campaign1
        output("Campaign 1 already exists")
      else
        campaign1 = FactoryBot.create(
          :registration_campaign,
          campaignable: seminar,
          status: :draft,
          allocation_mode: :first_come_first_served,
          description: PLANNING_CAMPAIGN_DESCRIPTION,
          registration_deadline: 1.week.from_now
        )

        planning_cohort = FactoryBot.create(
          :cohort,
          context: seminar,
          title: "Interest Survey",
          propagate_to_lecture: false,
          capacity: nil
        )

        FactoryBot.create(
          :registration_item,
          registration_campaign: campaign1,
          registerable: planning_cohort
        )

        output("Created Campaign 1 (Planning Survey with Planning Cohort)")
      end

      output("Registering 12 students to Campaign 1...")
      students = []
      12.times do |index|
        email = "seminar_student_#{index}@mampf.edu"
        user = User.find_by(email: email)
        user ||= FactoryBot.create(
          :confirmed_user,
          email: email,
          name: "Seminar Student #{index}"
        )
        students << user

        next if campaign1.user_registrations.exists?(user: user)

        FactoryBot.create(
          :registration_user_registration,
          user: user,
          registration_campaign: campaign1,
          registration_item: campaign1.registration_items.first,
          status: :confirmed
        )
      end

      campaign1.update!(status: :closed) unless campaign1.completed?
      output("Campaign 1 is completed (planning cohort materialized, no roster propagation).")

      campaign2 = Registration::Campaign.find_by(
        campaignable: seminar,
        description: ALLOCATION_CAMPAIGN_DESCRIPTION
      )
      if campaign2
        output("Recreating Campaign 2...")
        campaign2.update!(status: :draft)
        campaign2.destroy!
      end

      campaign2 = FactoryBot.create(
        :registration_campaign,
        campaignable: seminar,
        status: :draft,
        allocation_mode: :preference_based,
        registration_deadline: 1.week.from_now,
        description: ALLOCATION_CAMPAIGN_DESCRIPTION
      )
      output("Created Campaign 2 (Allocation)")

      Registration::Policy.create!(
        registration_campaign: campaign2,
        kind: :prerequisite_campaign,
        phase: :finalization,
        active: true,
        config: { "prerequisite_campaign_id" => campaign1.id }
      )
      output("Added Prerequisite Policy (Must have registered in Stage 1)")

      12.times do
        talk = FactoryBot.create(
          :talk,
          lecture: seminar,
          title: Faker::Book.title,
          capacity: 1
        )

        FactoryBot.create(
          :registration_item,
          registration_campaign: campaign2,
          registerable: talk
        )
      end
      output("Created 12 Talks (Items)")

      campaign2.update!(status: :open)
      output("Opened Campaign 2")

      output("Registering students with preferences...")
      items = campaign2.registration_items.to_a
      popular_items = items.first(3)

      students.each do |student|
        choices = []
        pick = ->(pool) { (pool - choices).sample }

        choices << (rand < 0.8 ? pick.call(popular_items) : pick.call(items))
        choices << (rand < 0.5 ? pick.call(popular_items) : pick.call(items))
        choices << pick.call(items)

        choices.compact!
        while choices.size < 3
          choices << pick.call(items)
          choices.compact!
          choices.uniq!
        end

        choices.each_with_index do |item, index|
          FactoryBot.create(
            :registration_user_registration,
            user: student,
            registration_campaign: campaign2,
            registration_item: item,
            preference_rank: index + 1,
            status: :pending
          )
        end
      end
      output("Done. 12 students registered with preferences.")

      output("Registering 2 extra students (not in Stage 1)...")
      2.times do |index|
        email = "external_student_#{index}@mampf.edu"
        user = User.find_by(email: email)
        user ||= FactoryBot.create(
          :confirmed_user,
          email: email,
          name: "External Student #{index}"
        )

        items.sample(3).each_with_index do |item, rank|
          FactoryBot.create(
            :registration_user_registration,
            user: user,
            registration_campaign: campaign2,
            registration_item: item,
            preference_rank: rank + 1,
            status: :pending
          )
        end
      end
      output("Done. 2 extra students registered.")

      output("Creating Campaign 3 (Nachrücker)...")
      campaign3 = Registration::Campaign.find_by(
        campaignable: seminar,
        description: NACHRUECKER_CAMPAIGN_DESCRIPTION
      )

      if campaign3
        output("Campaign 3 already exists")
      else
        campaign3 = FactoryBot.create(
          :registration_campaign,
          campaignable: seminar,
          status: :draft,
          allocation_mode: :first_come_first_served,
          registration_deadline: 1.week.from_now,
          description: NACHRUECKER_CAMPAIGN_DESCRIPTION
        )
        output("Created Campaign 3 (Nachrücker)")
      end

      nachruecker = Cohort.find_by(context: seminar, title: "Nachrücker")
      unless nachruecker
        nachruecker = FactoryBot.create(
          :cohort,
          context: seminar,
          title: "Nachrücker",
          capacity: 5
        )
        output("Created Cohort 'Nachrücker'")
      end

      unless Registration::Item.exists?(
        registration_campaign: campaign3,
        registerable: nachruecker
      )
        FactoryBot.create(
          :registration_item,
          registration_campaign: campaign3,
          registerable: nachruecker
        )
        output("Added Nachrücker to Campaign 3")
      end

      campaign3.update!(status: :open)
      output("Opened Campaign 3")

      output("Registering 5 students to Nachrücker...")
      item = campaign3.registration_items.first
      5.times do |index|
        email = "nachruecker_#{index}@mampf.edu"
        user = User.find_by(email: email)
        user ||= FactoryBot.create(
          :confirmed_user,
          email: email,
          name: "Nachrücker #{index}"
        )

        next if campaign3.user_registrations.exists?(user: user)

        FactoryBot.create(
          :registration_user_registration,
          user: user,
          registration_campaign: campaign3,
          registration_item: item,
          status: :confirmed
        )
      end
      output("Done. Nachrücker full.")
    end

    private

      def output(message)
        $stdout.puts(message)
      end

      def fail_setup!(message)
        raise(message)
      end

      def ensure_non_production!
        fail_setup!("Cannot run in production!") if Rails.env.production?
      end

      def lecture!
        lecture = Lecture.find_by(id: 1)
        fail_setup!("Lecture 1 not found. Run just seed first.") unless lecture

        teacher = teacher!
        lecture.update!(teacher: teacher) if lecture.teacher != teacher
        lecture
      end

      def teacher!
        teacher = User.find_by(email: "teacher@mampf.edu")
        fail_setup!("User teacher@mampf.edu not found. Run just seed first.") unless teacher

        teacher
      end
  end
end
