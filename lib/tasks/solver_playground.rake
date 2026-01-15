namespace :solver do
  desc "Generate a tutorial campaign with specific capacities"
  task create_campaign: :environment do
    puts "Creating solver campaign..."

    lecture = Lecture.find_by(id: 1)
    teacher = User.find_by(email: "teacher@mampf.edu")

    unless lecture && teacher
      puts "Error: Required seed data missing."
      puts "Lecture ID 1: #{lecture ? "Found" : "Missing"}"
      puts "User 'teacher@mampf.edu': #{teacher ? "Found" : "Missing"}"
      puts "Please run 'just seed' first."
      exit 1
    end

    if lecture.teacher != teacher
      puts "Updating lecture teacher to #{teacher.name}"
      lecture.update!(teacher: teacher)
    end

    puts "Using lecture: #{lecture.title} (ID: #{lecture.id})"
    puts "Using teacher: #{teacher.name} (ID: #{teacher.id})"

    # Create Campaign
    # Check if one already exists for this lecture to avoid duplicates if run multiple times
    campaign = Registration::Campaign.find_by(campaignable: lecture,
                                              description: "Solver Test Campaign")

    if campaign
      puts "Campaign already exists: #{campaign.id}"
    else
      campaign = FactoryBot.create(:registration_campaign,
                                   campaignable: lecture,
                                   status: :draft, # Start as draft to add items
                                   allocation_mode: :preference_based,
                                   registration_deadline: 1.week.from_now,
                                   description: "Solver Test Campaign")
      puts "Created campaign: #{campaign.id}"
    end

    # Create Tutorials
    capacities = [20, 15, 10, 5]
    capacities.each_with_index do |cap, i|
      title = "Tutorial #{i + 1}"
      tutorial = Tutorial.find_by(lecture: lecture, title: title)

      if tutorial
        puts "Tutorial #{i + 1} already exists"
        tutorial.update!(capacity: cap)
      else
        tutorial = FactoryBot.create(:tutorial,
                                     lecture: lecture,
                                     title: title,
                                     capacity: cap)
        puts "Created Tutorial #{i + 1} with capacity #{cap}"
      end

      next if Registration::Item.exists?(registration_campaign: campaign, registerable: tutorial)

      FactoryBot.create(:registration_item,
                        registration_campaign: campaign,
                        registerable: tutorial)
      puts "Added Tutorial #{i + 1} to campaign"
    end

    # Open the campaign if it's still draft
    if campaign.draft?
      campaign.update!(status: :open)
      puts "Opened campaign"
    end
  end

  desc "Generate user registrations for the solver campaign"
  task create_registrations: :environment do
    campaign = Registration::Campaign.where(description: "Solver Test Campaign").last
    unless campaign
      puts "Campaign not found. Run solver:create_campaign first."
      exit
    end

    puts "Cleaning up old registrations..."
    campaign.user_registrations.destroy_all

    # Sort items by capacity: [5, 10, 15, 20]
    items = campaign.registration_items.includes(:registerable).to_a.sort_by do |i|
      i.registerable.capacity
    end

    small_room = items[0]   # Cap 5
    medium_room = items[1]  # Cap 10

    total_capacity = items.sum { |i| i.registerable.capacity }
    num_users = 55

    puts "Creating #{num_users} users (Total Cap #{total_capacity}). Scenario: Picky Eaters..."
    puts "Most users will ONLY pick the small/medium rooms, "
    puts "forcing the solver to assign them to large rooms against their will."
    puts "Since there are more users than spots, " \
         "#{num_users - total_capacity} users will remain unassigned."

    num_users.times do |i|
      email = "solver_user_#{i}@example.com"
      user = User.find_by(email: email)
      user ||= FactoryBot.create(:confirmed_user, email: email, name: "Solver User #{i}")

      # 90% of users are "Picky" - they only want the popular (small) rooms
      is_picky = rand < 0.9

      selected_items = if is_picky
        # They only select from the 15 popular spots
        # They do NOT include large rooms in their preferences
        [small_room, medium_room].shuffle.take(rand(1..2))
      else
        # The nice 10% who are flexible
        items.shuffle.take(3)
      end

      selected_items.each_with_index do |item, rank|
        FactoryBot.create(:registration_user_registration,
                          user: user,
                          registration_campaign: campaign,
                          registration_item: item,
                          preference_rank: rank + 1,
                          status: :pending)
      end
    end

    puts "Done."
  end

  desc "Generate a friendly campaign with ample capacity"
  task create_friendly_campaign: :environment do
    puts "Creating friendly solver campaign..."

    lecture = Lecture.find_by(id: 1)
    teacher = User.find_by(email: "teacher@mampf.edu")

    unless lecture && teacher
      puts "Error: Required seed data missing."
      exit 1
    end

    # Create Campaign
    campaign = Registration::Campaign.find_by(campaignable: lecture,
                                              description: "Friendly Solver Campaign")

    if campaign
      puts "Campaign already exists: #{campaign.id}"
    else
      campaign = FactoryBot.create(:registration_campaign,
                                   campaignable: lecture,
                                   status: :draft,
                                   allocation_mode: :preference_based,
                                   registration_deadline: 1.week.from_now,
                                   description: "Friendly Solver Campaign")
      puts "Created campaign: #{campaign.id}"
    end

    unless campaign.registration_policies.exists?(kind: :institutional_email)
      FactoryBot.create(:registration_policy,
                        registration_campaign: campaign,
                        kind: :institutional_email,
                        config: { "allowed_domains" => "example.com" },
                        phase: :both)
      puts "Added institutional email policy (example.com)"
    end

    # Create Friendly Tutorials
    # Total Cap: 80 (4 * 20)
    4.times do |i|
      title = "Friendly Tutorial #{i + 1}"
      tutorial = Tutorial.find_by(lecture: lecture, title: title)

      if tutorial
        puts "#{title} already exists"
      else
        tutorial = FactoryBot.create(:tutorial,
                                     lecture: lecture,
                                     title: title,
                                     capacity: 20)
        puts "Created #{title}"
      end

      next if Registration::Item.exists?(registration_campaign: campaign, registerable: tutorial)

      FactoryBot.create(:registration_item,
                        registration_campaign: campaign,
                        registerable: tutorial)
      puts "Added #{title} to campaign"
    end

    if campaign.draft?
      campaign.update!(status: :open)
      puts "Opened campaign"
    end
  end

  desc "Generate friendly registrations for the friendly campaign"
  task create_friendly_registrations: :environment do
    campaign = Registration::Campaign.where(description: "Friendly Solver Campaign").last
    unless campaign
      puts "Campaign not found. Run solver:create_friendly_campaign first."
      exit
    end

    puts "Cleaning up old registrations..."
    campaign.user_registrations.destroy_all

    items = campaign.registration_items.to_a
    num_users = 55

    puts "Creating registrations for #{num_users} users..."
    puts "Scenario: Friendly & Relaxed."
    puts "- Not everyone registers (approx 80% participation)"
    puts "- Users are flexible (select 3-4 options)"
    puts "- Ample capacity (80 spots for ~44 students)"

    registered_count = 0

    num_users.times do |i|
      email = "solver_user_#{i}@example.com"
      user = User.find_by(email: email)
      # Ensure user exists (should be created by previous task, but safe fallback)
      user ||= FactoryBot.create(:confirmed_user, email: email, name: "Solver User #{i}")

      # 20% of students don't register
      next if rand < 0.2

      registered_count += 1

      # Select 3 to 4 random items
      selected_items = items.shuffle.take(rand(3..4))

      selected_items.each_with_index do |item, rank|
        FactoryBot.create(:registration_user_registration,
                          user: user,
                          registration_campaign: campaign,
                          registration_item: item,
                          preference_rank: rank + 1,
                          status: :pending)
      end
    end

    puts "Done. Created registrations for #{registered_count} students."
  end

  desc "Generate a mixed FCFS campaign (tutorials + cohorts) with email policy"
  task create_mixed_fcfs_campaign: :environment do
    puts "Creating Mixed FCFS campaign..."

    lecture = Lecture.find_by(id: 1)
    unless lecture
      puts "Error: Lecture 1 not found."
      exit 1
    end

    # Create Campaign
    campaign = Registration::Campaign.find_by(campaignable: lecture,
                                              description: "Cohort FCFS Campaign")

    if campaign
      puts "Campaign already exists: #{campaign.id}"
    else
      campaign = FactoryBot.create(:registration_campaign,
                                   campaignable: lecture,
                                   status: :draft,
                                   allocation_mode: :first_come_first_served,
                                   registration_deadline: 1.week.from_now,
                                   description: "FCFS Campaign")
      puts "Created campaign: #{campaign.id}"
    end

    # Add Email Policy
    unless campaign.registration_policies.exists?(kind: :institutional_email)
      FactoryBot.create(:registration_policy,
                        registration_campaign: campaign,
                        kind: :institutional_email,
                        config: { "allowed_domains" => "example.com" },
                        phase: :both)
      puts "Added institutional email policy (example.com)"
    end

    # Create FCFS Tutorials (disjoint from other campaigns)
    # Tutorial IDs 5-7 (other campaigns use 1-4)
    [12, 10, 8].each_with_index do |cap, i|
      title = "FCFS Tutorial #{i + 5}"
      tutorial = Tutorial.find_by(lecture: lecture, title: title)

      if tutorial
        puts "#{title} already exists"
        tutorial.update!(capacity: cap)
      else
        tutorial = FactoryBot.create(:tutorial,
                                     lecture: lecture,
                                     title: title,
                                     capacity: cap)
        puts "Created #{title} with capacity #{cap}"
      end

      next if Registration::Item.exists?(registration_campaign: campaign, registerable: tutorial)

      FactoryBot.create(:registration_item,
                        registration_campaign: campaign,
                        registerable: tutorial)
      puts "Added #{title} to campaign"
    end

    # Create Repeaters Cohort (propagates to lecture)
    repeaters_title = "Repeaters"
    repeaters = Cohort.find_by(context_type: Lecture, context_id: lecture.id,
                               title: repeaters_title)

    if repeaters
      puts "#{repeaters_title} cohort already exists"
    else
      repeaters = FactoryBot.create(:cohort,
                                    context: lecture,
                                    title: repeaters_title,
                                    capacity: 15,
                                    propagate_to_lecture: true,
                                    purpose: :general)
      puts "Created #{repeaters_title} cohort (propagates to lecture)"
    end

    unless Registration::Item.exists?(registration_campaign: campaign, registerable: repeaters)
      FactoryBot.create(:registration_item,
                        registration_campaign: campaign,
                        registerable: repeaters)
      puts "Added #{repeaters_title} to campaign"
    end

    # Create Waitlist Cohort (does NOT propagate to lecture)
    waitlist_title = "Waitlist"
    waitlist = Cohort.find_by(context_type: Lecture, context_id: lecture.id, title: waitlist_title)

    if waitlist
      puts "#{waitlist_title} cohort already exists"
    else
      waitlist = FactoryBot.create(:cohort,
                                   context: lecture,
                                   title: waitlist_title,
                                   capacity: 20,
                                   propagate_to_lecture: false,
                                   purpose: :general)
      puts "Created #{waitlist_title} cohort (does NOT propagate to lecture)"
    end

    unless Registration::Item.exists?(registration_campaign: campaign, registerable: waitlist)
      FactoryBot.create(:registration_item,
                        registration_campaign: campaign,
                        registerable: waitlist)
      puts "Added #{waitlist_title} to campaign"
    end

    if campaign.draft?
      campaign.update!(status: :open)
      puts "Opened campaign"
    end
  end

  desc "Generate registrations for mixed FCFS campaign"
  task create_mixed_fcfs_registrations: :environment do
    campaign = Registration::Campaign.where(description: "FCFS Campaign").last
    unless campaign
      puts "Campaign not found. Run solver:create_fcfs_campaign first."
      exit
    end

    puts "Cleaning up old registrations..."
    campaign.user_registrations.destroy_all

    # Separate tutorials from cohorts
    tutorials = campaign.registration_items.includes(:registerable)
                        .where(registerable_type: "Tutorial").to_a
    repeaters_item = campaign.registration_items.find_by(
      registerable_type: "Cohort",
      registerable: Cohort.find_by(title: "Repeaters")
    )
    waitlist_item = campaign.registration_items.find_by(
      registerable_type: "Cohort",
      registerable: Cohort.find_by(title: "Waitlist")
    )

    tutorial_capacity = tutorials.sum { |i| i.registerable.capacity }
    repeaters_capacity = repeaters_item.registerable.capacity
    waitlist_capacity = waitlist_item.registerable.capacity
    total_capacity = tutorial_capacity + repeaters_capacity + waitlist_capacity

    puts "Campaign structure:"
    puts "- Tutorials: #{tutorials.count} (capacity #{tutorial_capacity})"
    puts "- Repeaters cohort: capacity #{repeaters_capacity} (propagates to lecture)"
    puts "- Waitlist cohort: capacity #{waitlist_capacity} (does NOT propagate)"
    puts "- Total capacity: #{total_capacity}"

    # Create enough registrations to fill tutorials completely
    # and partially fill cohorts
    target_repeaters = 5
    target_waitlist = 12
    num_users = tutorial_capacity + target_repeaters + target_waitlist
    # This means: tutorials full (30), repeaters partial (5/15), waitlist partial (12/20)

    puts "\nCreating registrations for #{num_users} users..."
    puts "Scenario: Tutorials full, repeaters partially filled, waitlist has more"

    registered_count = 0
    repeaters_count = 0
    waitlist_count = 0

    num_users.times do |i|
      email = "cohort_user_#{i}@example.com"
      user = User.find_by(email: email)
      user ||= FactoryBot.create(:confirmed_user, email: email, name: "Cohort User #{i}")

      # Try tutorials first
      item = tutorials.find do |t|
        t.confirmed_registrations_count < t.registerable.capacity
      end

      # If tutorials full, try repeaters (but limit to target)
      if !item && repeaters_count < target_repeaters
        item = repeaters_item
        repeaters_count += 1
      end

      # If repeaters at target, try waitlist
      if !item && waitlist_count < target_waitlist
        item = waitlist_item
        waitlist_count += 1
      end

      unless item
        puts "Campaign full! User #{i} cannot register."
        next
      end

      FactoryBot.create(:registration_user_registration,
                        user: user,
                        registration_campaign: campaign,
                        registration_item: item,
                        status: :confirmed)

      item.reload
      registered_count += 1
    end

    puts "\nDone. Created registrations for #{registered_count} students."
    puts "Final distribution:"
    tutorials.each do |t|
      puts "  #{t.registerable.title}: #{t.confirmed_registrations_count}/#{t.registerable.capacity}"
    end
    puts "  Repeaters: #{repeaters_item.confirmed_registrations_count}/#{repeaters_capacity}"
    puts "  Waitlist: #{waitlist_item.confirmed_registrations_count}/#{waitlist_capacity}"
  end

  desc "Generate a two-stage seminar campaign (Planning -> Allocation)"
  task create_two_stage_campaign: :environment do
    puts "Creating two-stage seminar campaign..."

    teacher = User.find_by(email: "teacher@mampf.edu")
    unless teacher
      puts "Error: Teacher 'teacher@mampf.edu' missing. Run 'just seed' first."
      exit 1
    end

    # 1. Create Seminar (Course + Lecture)
    course_title = "Campaign Test Seminar"
    course = Course.find_by(title: course_title)
    unless course
      course = FactoryBot.create(:course, title: course_title, short_title: "CTS")
      puts "Created Course: #{course.title}"
    end

    seminar = Lecture.find_by(course: course, teacher: teacher)
    unless seminar
      seminar = FactoryBot.create(:seminar,
                                  course: course,
                                  teacher: teacher,
                                  released: true,
                                  term: Term.active || FactoryBot.create(:term))
      puts "Created Seminar Lecture"
    end

    # Subscribe teacher to seminar
    unless teacher.favorite_lectures.exists?(seminar.id)
      teacher.lectures << seminar
      puts "Subscribed teacher to seminar"
    end

    # 2. Create Campaign 1 (Planning Survey via Planning Cohort)
    campaign1 = Registration::Campaign.find_by(campaignable: seminar,
                                               description: "Stage 1: Planning")
    if campaign1
      puts "Campaign 1 already exists"
    else
      campaign1 = FactoryBot.create(:registration_campaign,
                                    campaignable: seminar,
                                    status: :draft,
                                    allocation_mode: :first_come_first_served,
                                    description: "Stage 1: Planning",
                                    registration_deadline: 1.week.ago)

      # Create a planning cohort (purpose: planning, propagate_to_lecture: false)
      planning_cohort = FactoryBot.create(:cohort,
                                          context: seminar,
                                          title: "Interest Survey",
                                          purpose: :planning,
                                          propagate_to_lecture: false,
                                          capacity: nil)

      FactoryBot.create(:registration_item,
                        registration_campaign: campaign1,
                        registerable: planning_cohort)

      puts "Created Campaign 1 (Planning Survey with Planning Cohort)"
    end

    # Register 12 students to Campaign 1
    puts "Registering 12 students to Campaign 1..."
    students = []
    12.times do |i|
      email = "seminar_student_#{i}@mampf.edu"
      user = User.find_by(email: email)
      user ||= FactoryBot.create(:confirmed_user, email: email, name: "Seminar Student #{i}")
      students << user

      next if campaign1.user_registrations.exists?(user: user)

      # Register them to the planning cohort
      item = campaign1.registration_items.first
      FactoryBot.create(:registration_user_registration,
                        user: user,
                        registration_campaign: campaign1,
                        registration_item: item,
                        status: :confirmed)
    end

    # Close and finalize Campaign 1
    unless campaign1.completed?
      campaign1.update!(status: :closed)
      # campaign1.finalize!
    end
    puts "Campaign 1 is completed (planning cohort materialized, no roster propagation)."

    # 3. Create Campaign 2 (Preference-based)
    campaign2 = Registration::Campaign.find_by(campaignable: seminar,
                                               description: "Stage 2: Allocation")

    if campaign2
      puts "Recreating Campaign 2..."
      # rubocop:disable Rails/SkipsModelValidations
      campaign2.update_columns(status: :draft) # Force draft to allow destruction
      # rubocop:enable Rails/SkipsModelValidations
      campaign2.destroy!
    end

    campaign2 = FactoryBot.create(:registration_campaign,
                                  campaignable: seminar,
                                  status: :draft,
                                  allocation_mode: :preference_based,
                                  registration_deadline: 1.week.from_now,
                                  description: "Stage 2: Allocation")
    puts "Created Campaign 2 (Allocation)"

    # Add Prerequisite Policy
    Registration::Policy.create!(
      registration_campaign: campaign2,
      kind: :prerequisite_campaign,
      phase: :finalization,
      active: true,
      config: { "prerequisite_campaign_id" => campaign1.id }
    )
    puts "Added Prerequisite Policy (Must have registered in Stage 1)"

    # Create 12 Talks (Items)
    12.times do |_i|
      title = Faker::Book.title
      talk = FactoryBot.create(:talk,
                               lecture: seminar,
                               title: title,
                               capacity: 1) # Seminars usually have 1 student per talk

      FactoryBot.create(:registration_item,
                        registration_campaign: campaign2,
                        registerable: talk)
    end
    puts "Created 12 Talks (Items)"

    # Open Campaign 2
    campaign2.update!(status: :open)
    puts "Opened Campaign 2"

    # Register the 12 students with preferences
    puts "Registering students with preferences..."
    items = campaign2.registration_items.to_a

    # Popularity bias: First 3 items are popular.
    popular_items = items.first(3)
    items.drop(3)

    students.each do |student|
      # Each student picks 3 choices.
      choices = []

      # Helper to pick unique choice
      pick = ->(pool) { (pool - choices).sample }

      # Choice 1: 80% chance popular
      choices << if rand < 0.8
        pick.call(popular_items)
      else
        pick.call(items)
      end

      # Choice 2: 50% chance popular
      choices << if rand < 0.5
        pick.call(popular_items)
      else
        pick.call(items)
      end

      # Choice 3: Random
      choices << pick.call(items)

      # Fill nil choices if pool exhausted
      choices.compact!
      while choices.size < 3
        choices << pick.call(items)
        choices.compact!
        choices.uniq!
      end

      # Create registrations
      choices.each_with_index do |item, idx|
        FactoryBot.create(:registration_user_registration,
                          user: student,
                          registration_campaign: campaign2,
                          registration_item: item,
                          preference_rank: idx + 1,
                          status: :pending)
      end
    end
    puts "Done. 12 students registered with preferences."

    # Register 2 extra students who did NOT participate in Stage 1
    puts "Registering 2 extra students (not in Stage 1)..."
    2.times do |i|
      email = "external_student_#{i}@mampf.edu"
      user = User.find_by(email: email)
      user ||= FactoryBot.create(:confirmed_user, email: email, name: "External Student #{i}")

      # Pick 3 random items
      choices = items.sample(3)

      choices.each_with_index do |item, idx|
        FactoryBot.create(:registration_user_registration,
                          user: user,
                          registration_campaign: campaign2,
                          registration_item: item,
                          preference_rank: idx + 1,
                          status: :pending)
      end
    end
    puts "Done. 2 extra students registered."
  end
end
