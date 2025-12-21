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

    items = campaign.registration_items.to_a

    puts "Creating 45 users and registrations..."

    45.times do |i|
      email = "solver_user_#{i}@example.com"
      user = User.find_by(email: email)
      user ||= FactoryBot.create(:confirmed_user, email: email, name: "Solver User #{i}")

      # Check if user already has registrations for this campaign
      if campaign.user_registrations.exists?(user: user)
        # puts "User #{i} already registered, skipping."
        next
      end

      # Random preferences
      # Shuffle items and pick 1 to 4 of them
      shuffled_items = items.shuffle
      num_preferences = rand(1..items.size)

      selected_items = shuffled_items.take(num_preferences)

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
