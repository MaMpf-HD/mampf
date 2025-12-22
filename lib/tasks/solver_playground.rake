namespace :solver do
  desc "Generate a tutorial campaign with specific capacities"
  task create_campaign: :environment do
    puts "Creating solver campaign..."

    lecture = Lecture.find_by(id: 1)
    unless lecture
      puts "Lecture with ID 1 not found. Please run 'just seed' first."
      return
    end

    teacher = User.find_by(email: "teacher@mampf.edu")
    unless teacher
      puts "User 'teacher@mampf.edu' not found. Please run 'just seed' first."
      return
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

    puts "Creating 55 users (Total Cap 50). Scenario: Picky Eaters..."
    puts "Most users will ONLY pick the small/medium rooms, "
    puts "forcing the solver to assign them to large rooms against their will."
    puts "Since there are more users than spots, 5 users will remain unassigned."

    55.times do |i|
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
end
