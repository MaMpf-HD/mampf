module Scenarios
  module CampaignSetupSupport
    extend self

    PREFERENCE_CAMPAIGN_DESCRIPTION = "Solver Test Campaign".freeze
    MIXED_FCFS_CAMPAIGN_DESCRIPTION = "Cohort FCFS Campaign".freeze
    PLANNING_CAMPAIGN_DESCRIPTION = "Stage 1: Planning".freeze
    ALLOCATION_CAMPAIGN_DESCRIPTION = "Stage 2: Allocation".freeze
    NACHRUECKER_CAMPAIGN_DESCRIPTION = "Stage 3: Nachrücker (FCFS)".freeze
    TWO_STAGE_COURSE_TITLE = "Campaign Test Seminar".freeze
    PLAYGROUND_COURSE_TITLE = "Registration Playground".freeze

    def setup!
      ensure_non_production!
      Scenarios::QuietLoggingSupport.with_quiet_logging do
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

      campaign = FactoryBot.create(
        :registration_campaign,
        campaignable: lecture,
        status: :draft,
        allocation_mode: :preference_based,
        registration_deadline: 1.week.from_now,
        description: PREFERENCE_CAMPAIGN_DESCRIPTION
      )
      output("Created campaign: #{campaign.id}")

      [20, 15, 10, 5].each_with_index do |capacity, index|
        tutorial = FactoryBot.create(
          :tutorial,
          lecture: lecture,
          title: "Tutorial #{index + 1}",
          capacity: capacity
        )
        FactoryBot.create(
          :registration_item,
          registration_campaign: campaign,
          registerable: tutorial
        )
        output("Added Tutorial #{index + 1} to campaign")
      end

      campaign.update!(status: :open)
      output("Opened campaign")
    end

    def seed_preference_campaign_registrations!
      ensure_non_production!

      campaign = Registration::Campaign.find_by(
        campaignable: lecture!, description: PREFERENCE_CAMPAIGN_DESCRIPTION
      )
      unless campaign
        output("Campaign not found. Run just seed first.")
        return
      end

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
        user = FactoryBot.create(:confirmed_user, email: "solver_user_#{index}@example.com",
                                                  name: "Solver User #{index}")

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
      campaign = FactoryBot.create(
        :registration_campaign,
        campaignable: lecture,
        status: :draft,
        allocation_mode: :first_come_first_served,
        registration_deadline: 1.week.from_now,
        description: MIXED_FCFS_CAMPAIGN_DESCRIPTION
      )
      output("Created campaign: #{campaign.id}")

      FactoryBot.create(
        :registration_policy,
        registration_campaign: campaign,
        kind: :institutional_email,
        config: { "allowed_domains" => "example.com" },
        phase: :finalization
      )
      output("Added institutional email policy (example.com, finalization only)")

      [12, 10, 8].each_with_index do |capacity, index|
        title = "FCFS Tutorial #{index + 5}"
        tutorial = FactoryBot.create(:tutorial, lecture: lecture, title: title,
                                                capacity: capacity)
        FactoryBot.create(:registration_item, registration_campaign: campaign,
                                              registerable: tutorial)
        output("Added #{title} to campaign")
      end

      repeaters = FactoryBot.create(:cohort, context: lecture, title: "Repeaters",
                                             capacity: 15, propagate_to_lecture: true)
      FactoryBot.create(:registration_item, registration_campaign: campaign,
                                            registerable: repeaters)
      output("Added Repeaters to campaign (propagates to lecture)")

      waitlist = FactoryBot.create(:cohort, context: lecture, title: "Waitlist",
                                            capacity: 20, propagate_to_lecture: false)
      FactoryBot.create(:registration_item, registration_campaign: campaign,
                                            registerable: waitlist)
      output("Added Waitlist to campaign (does NOT propagate to lecture)")

      campaign.update!(status: :open)
      output("Opened campaign")
    end

    def seed_mixed_fcfs_campaign_registrations!
      ensure_non_production!

      campaign = Registration::Campaign.find_by(
        campaignable: lecture!, description: MIXED_FCFS_CAMPAIGN_DESCRIPTION
      )
      unless campaign
        output("Campaign not found. Run just seed first.")
        return
      end

      tutorials = campaign.registration_items.includes(:registerable)
                          .where(registerable_type: "Tutorial")
                          .to_a
      repeaters = Cohort.find_by(context: lecture!, title: "Repeaters")
      waitlist = Cohort.find_by(context: lecture!, title: "Waitlist")
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
        user = FactoryBot.create(:confirmed_user, email: "cohort_user_#{index}@#{domain}",
                                                  name: "Cohort User #{index}")

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
      course = FactoryBot.create(:course, title: TWO_STAGE_COURSE_TITLE, short_title: "CTS")
      output("Created Course: #{course.title}")

      seminar = FactoryBot.create(:seminar, course: course, teacher: teacher,
                                            released: true,
                                            term: Scenarios::TermSupport.next_term)
      output("Created Seminar Lecture")

      teacher.lectures << seminar
      output("Subscribed teacher to seminar")

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

      output("Registering 12 students to Campaign 1...")
      students = (0...12).map do |index|
        user = FactoryBot.create(:confirmed_user, email: "seminar_student_#{index}@mampf.edu",
                                                  name: "Seminar Student #{index}")
        FactoryBot.create(
          :registration_user_registration,
          user: user,
          registration_campaign: campaign1,
          registration_item: campaign1.registration_items.first,
          status: :confirmed
        )
        user
      end

      campaign1.update!(status: :closed) unless campaign1.completed?
      output("Campaign 1 is completed (planning cohort materialized, no roster propagation).")

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
        user = FactoryBot.create(:confirmed_user, email: "external_student_#{index}@mampf.edu",
                                                  name: "External Student #{index}")

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
      campaign3 = FactoryBot.create(
        :registration_campaign,
        campaignable: seminar,
        status: :draft,
        allocation_mode: :first_come_first_served,
        registration_deadline: 1.week.from_now,
        description: NACHRUECKER_CAMPAIGN_DESCRIPTION
      )
      output("Created Campaign 3 (Nachrücker)")

      nachruecker = FactoryBot.create(:cohort, context: seminar, title: "Nachrücker",
                                               capacity: 5)
      output("Created Cohort 'Nachrücker'")

      FactoryBot.create(:registration_item, registration_campaign: campaign3,
                                            registerable: nachruecker)
      output("Added Nachrücker to Campaign 3")

      campaign3.update!(status: :open)
      output("Opened Campaign 3")

      output("Registering 5 students to Nachrücker...")
      item = campaign3.registration_items.first
      5.times do |index|
        user = FactoryBot.create(:confirmed_user, email: "nachruecker_#{index}@mampf.edu",
                                                  name: "Nachrücker #{index}")

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

      # Everything here is a registration in progress, and one of those belongs
      # in the term that is still being planned -- not in the lecture the demo
      # opens on, which is meant to look like a term well under way.
      def lecture!
        Scenarios::TermSupport.find_or_create_lecture!(
          term: Scenarios::TermSupport.next_term, teacher: teacher!,
          course_title: PLAYGROUND_COURSE_TITLE, short_title: "RP"
        )
      end

      def teacher!
        teacher = User.find_by(email: "teacher@mampf.edu")
        fail_setup!("User teacher@mampf.edu not found. Run just seed first.") unless teacher

        teacher
      end
  end
end
