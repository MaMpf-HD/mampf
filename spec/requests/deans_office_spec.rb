require "rails_helper"

RSpec.describe("Dean's office", type: :request) do
  let(:office) { create(:confirmed_user_en, deans_office: true) }
  let(:term) { create(:term, :active) }
  let(:lecture) { create(:lecture, term: term) }

  describe "who gets in" do
    it "lets the dean's office and admins in" do
      [office, create(:confirmed_user_en, admin: true)].each do |user|
        sign_in(user)
        get deans_office_path

        expect(response).to have_http_status(:ok)
      end
    end

    it "keeps teachers, students and the support out, whatever term or format is asked for" do
      support = create(:confirmed_user_en, support: true)
      [lecture.teacher, create(:confirmed_user_en), support].each do |user|
        sign_in(user)
        [deans_office_path, deans_office_path(term: term.dashboard_param),
         deans_office_path(format: :json)].each do |path|
          get path
          expect(response).not_to have_http_status(:ok)
          expect(response.body).not_to include(CGI.escapeHTML(lecture.course.title))
        end
      end
    end

    it "closes the page once the role is taken away" do
      sign_in(office)
      office.update!(deans_office: false)

      get deans_office_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "the term's courses" do
    before { sign_in(office) }

    def page
      Nokogiri::HTML(response.body)
    end

    def row(title)
      page.css("tbody[data-deans-office-target='course']")
          .find { |body| body.at_css("th[scope='row']")&.text&.include?(title) }
    end

    # The figures of a course's line, after its teaching team, without the
    # labels the phone layout shows.
    def cells(title)
      row(title).at_css("tr").css("td").drop(1).map do |td|
        td.dup.tap { |copy| copy.css(".deans-office-label").remove }.text.squish
      end
    end

    def open_campaign(lecture, groups, deadline: 1.week.from_now)
      campaign = create(:registration_campaign, :first_come_first_served, campaignable: lecture)
      groups.each do |group|
        create(:registration_item, registration_campaign: campaign, registerable: group)
      end
      campaign.update!(status: :open, registration_deadline: deadline)
      campaign
    end

    def register(campaign, group, people)
      item = campaign.registration_items.find_by(registerable: group)
      people.each do |person|
        create(:registration_user_registration, :confirmed, user: person,
                                                            registration_campaign: campaign,
                                                            registration_item: item)
      end
    end

    # What the dean's office pays for by its quotas: how many students, how
    # many tutorials; the limits teachers set are not its concern.
    it "gives each lecture its students, its groups and its registration" do
      tutorials = [10, 12, nil].map do |capacity|
        create(:tutorial, lecture: lecture, capacity: capacity)
      end
      campaign = open_campaign(lecture, tutorials, deadline: Time.zone.local(2030, 10, 11, 18))
      register(campaign, tutorials.first, create_list(:confirmed_user, 2))

      get deans_office_path(term: term.dashboard_param)

      deadline = I18n.l(campaign.registration_deadline, format: :short)
      expect(cells(lecture.course.title))
        .to eq(["2", "3 tutorials", "Registration open"])
      expect(row(lecture.course.title).text.squish)
        .to include("Registration open until #{deadline} · First come, first served")
    end

    # The rosters stay empty until the allocation; the table would read as
    # nobody coming while people register.
    it "counts a tutorial's registrations while they run, as not yet in the group list" do
      tutorial = create(:tutorial, lecture: lecture, title: "Tuesday group", capacity: 12,
                                   location: nil)
      campaign = open_campaign(lecture, [tutorial])
      register(campaign, tutorial, create_list(:confirmed_user, 2))

      get deans_office_path(term: term.dashboard_param)

      button = row(lecture.course.title).at_css("button[data-action='deans-office#toggle']")
      details = page.at_css("##{button["aria-controls"]}")
      expect(details.at_css("tbody tr:not(.deans-office-group-phase)").text.squish)
        .to eq("Tuesday group 2")
      expect(details.at_css("[title^='Registrations']")["title"])
        .to start_with("Registrations, not in the group list yet")
    end

    # One figure for everybody: people already in a group and people still
    # registering, each counted once.
    it "counts people in groups and people registering together, each once" do
      allocated, open = create_list(:tutorial, 2, lecture: lecture, skip_campaigns: false)
      member, both = create_list(:confirmed_user, 2)
      [member, both].each { |user| create(:tutorial_membership, tutorial: allocated, user: user) }
      allocated.update!(skip_campaigns: true)
      campaign = open_campaign(lecture, [open])
      register(campaign, open, [both, create(:confirmed_user)])

      get deans_office_path(term: term.dashboard_param)

      expect(cells(lecture.course.title).first).to eq("3")
    end

    # Every way into a course counts once; an exam's list and a rejected
    # registration do not count at all.
    it "counts lecture members, group members and registrants, each once, and nobody else" do
      a, b, c, d, rejected, examinee = create_list(:confirmed_user, 6)
      create(:lecture_membership, lecture: lecture, user: a)
      settled = create(:tutorial, lecture: lecture, skip_campaigns: true)
      [a, b].each { |user| create(:tutorial_membership, tutorial: settled, user: user) }
      cohort = create(:cohort, context: lecture, skip_campaigns: true)
      [b, c].each { |user| create(:cohort_membership, cohort: cohort, user: user) }
      open = create(:tutorial, lecture: lecture)
      campaign = open_campaign(lecture, [open])
      register(campaign, open, [c, d])
      create(:registration_user_registration, :rejected,
             user: rejected, registration_campaign: campaign,
             registration_item: campaign.registration_items.first)
      create(:exam_roster_entry, exam: create(:exam, lecture: lecture), user: examinee)

      get deans_office_path(term: term.dashboard_param)

      expect(cells(lecture.course.title).first).to eq("4")
    end

    # A registration a lecturer has prepared before adding any group is still
    # a registration, not a course without one.
    it "gives a course whose registration has no groups yet a line of its own" do
      create(:registration_campaign, campaignable: lecture)

      get deans_office_path(term: term.dashboard_param)

      expect(cells(lecture.course.title)).to eq(["0", "none", "Not started yet"])
      expect(row(lecture.course.title).at_css("button[data-action='deans-office#toggle']"))
        .to be_nil
      expect(page.at_css("details[data-deans-office-target='unregistered']")).to be_nil
    end

    # Two closed registrations would otherwise read alike in the details.
    it "names the deadline of a registration that has closed" do
      tutorial = create(:tutorial, lecture: lecture)
      campaign = open_campaign(lecture, [tutorial])
      campaign.update_column(:registration_deadline, 1.minute.ago) # rubocop:disable Rails/SkipsModelValidations

      get deans_office_path(term: term.dashboard_param)

      deadline = I18n.l(campaign.reload.registration_deadline, format: :short)
      expect(row(lecture.course.title).at_css("tr.deans-office-group-phase").text.squish)
        .to eq("Allocation to follow · First come, first served · Deadline was #{deadline}")
    end

    it "counts the people in the groups once the places are allocated" do
      tutorial = create(:tutorial, lecture: lecture, capacity: 20)
      campaign = open_campaign(lecture, [tutorial])
      # rubocop:disable Rails/SkipsModelValidations
      campaign.update_columns(status: Registration::Campaign.statuses[:completed])
      # rubocop:enable Rails/SkipsModelValidations
      3.times { create(:tutorial_membership, tutorial: tutorial) }

      get deans_office_path(term: term.dashboard_param)

      expect(cells(lecture.course.title))
        .to eq(["3", "1 tutorial", "Allocated"])
    end

    # A group such as "Teilnahme ohne Tutorium" is the teacher's choice, not a
    # tutorial; neither is an exam.
    it "names further groups apart from tutorials and leaves exams out" do
      cohort = create(:cohort, context: lecture, title: "Taking part without a tutorial",
                               capacity: 500, skip_campaigns: true,
                               self_materialization_mode: :add_only)
      2.times { create(:cohort_membership, cohort: cohort) }
      create(:exam_roster_entry, exam: create(:exam, lecture: lecture, capacity: 300))

      get deans_office_path(term: term.dashboard_param)

      expect(cells(lecture.course.title))
        .to eq(["2", "1 flexible group", "Sign-up open"])
      button = row(lecture.course.title).at_css("button[data-action='deans-office#toggle']")
      details = page.at_css("##{button["aria-controls"]}")
      expect(details.text.squish).to include("Groups")
      expect(details.text).not_to include("Exam")
      cohort_row = details.css("tr").find { |tr| tr.text.include?("Taking part") }
      expect(cohort_row.text.squish).to eq("Taking part without a tutorial 2")
    end

    # The worker closes a campaign only once a minute; students are turned
    # away at the deadline already.
    it "names each phase with its groups where the groups differ" do
      early, late = create_list(:tutorial, 2, lecture: lecture, capacity: 10)
      open_campaign(lecture, [late])
      closed = open_campaign(lecture, [early])
      closed.update_column(:registration_deadline, 1.minute.ago) # rubocop:disable Rails/SkipsModelValidations

      get deans_office_path(term: term.dashboard_param)

      expect(cells(lecture.course.title).last)
        .to eq("Allocation to follow (1 tutorial) Registration open (1 tutorial)")
    end

    # The name from the personal data where given, not an account name.
    it "lists the teaching team, the teacher first, each with an address to copy" do
      assistant = create(:confirmed_user, name: "student1", first_name: "Ada",
                                          last_name: "Lovelace")
      lecture.teacher.update!(first_name: nil, last_name: nil)
      lecture.editors << assistant
      create(:tutorial, lecture: lecture)

      get deans_office_path(term: term.dashboard_param)

      team = row(lecture.course.title).at_css("tr td").css("li")
      expect(team.map { |li| li.text.squish })
        .to eq(["#{lecture.teacher.name} (Teacher)", "Ada Lovelace"])
      expect(team.pluck("data-clipboard-text-value"))
        .to eq([lecture.teacher.email, assistant.email])
    end

    it "shows how many each group has, and its location if given, behind a button" do
      create(:tutorial, lecture: lecture, title: "Tuesday group", capacity: 12, location: "INF 205")
      create(:tutorial, lecture: lecture, title: "Friday group", capacity: nil, location: nil)

      get deans_office_path(term: term.dashboard_param)

      button = row(lecture.course.title).at_css("button[data-action='deans-office#toggle']")
      details = page.at_css("##{button["aria-controls"]}")
      expect(button["aria-expanded"]).to eq("false")
      expect(details["hidden"]).not_to be_nil
      rows = details.css("tbody tr:not(.deans-office-group-phase)").map { |tr| tr.text.squish }
      expect(rows).to eq(["Friday group 0", "Tuesday group 0 INF 205"])
      expect(details.at_css("[role='progressbar']").ancestors("[aria-hidden='true']"))
        .to be_present
    end

    # Other faculties pay for students of their subjects, so the office needs
    # each subject's total at a glance and the programs only on demand.
    it "counts a course's students by subject, programs folded under each" do
      math = create(:subject, name: "Mathematics")
      physics = create(:subject, name: "Physics")
      people = [create(:program, subject: math, name: "B.Sc. 100%", degree: :bsc100),
                create(:program, subject: math, name: "M.Sc.", degree: :msc),
                create(:program, subject: physics, name: "B.Sc. 100%", degree: :bsc100)]
               .map { |program| create(:confirmed_user, program: program) }
      people << create(:confirmed_user)
      people << create(:confirmed_user, personal_data_confirmed_at: nil)
      people.each { |person| create(:lecture_membership, lecture: lecture, user: person) }
      create(:tutorial, lecture: lecture)

      get deans_office_path(term: term.dashboard_param)

      button = row(lecture.course.title).at_css("button[data-action='deans-office#toggle']")
      table = page.at_css("##{button["aria-controls"]} table.deans-office-programs")
      subjects = table.css("tbody tr").map do |tr|
        [(tr.at_css("summary") || tr.at_css("th")).text.squish, tr.at_css("td").text]
      end
      expect(subjects).to eq([["Mathematics", "2"], ["Physics", "1"],
                              [I18n.t("roster.programs.other"), "1"],
                              [I18n.t("roster.programs.unanswered"), "1"]])
      expect(table.css("tbody tr").first.css("li").map { |li| li.text.squish })
        .to eq(["B.Sc. 100%: 1", "M.Sc.: 1"])
      expect(table.at_css("tfoot td").text).to eq("5")
    end

    # Rosters came to MaMpf after these terms, so an empty tutorial there says
    # nothing about who attended, and nothing is still to begin.
    it "marks a past term's course without registration or students as such" do
      past = create(:term, season: "SS", year: term.year - 1)
      old = create(:lecture, term: past, course: create(:course, title: "Old Algebra"))
      create_list(:tutorial, 2, lecture: old)
      create(:tutorial, lecture: lecture)

      # By id: the slug keeps two digits of the year, and factory years run past 2099.
      get deans_office_path(term: past.id)
      expect(cells("Old Algebra")).to eq(["–", "2 tutorials", "No registration in MaMpf"])
      expect(response.body).to include("who took part was not recorded")

      get deans_office_path(term: term.dashboard_param)
      expect(cells(lecture.course.title)).to eq(["0", "1 tutorial", "Not started yet"])
      expect(response.body).not_to include("who took part was not recorded")
    end

    it "lists courses without any registration by name only" do
      lecture
      other = create(:lecture, term: term)
      create(:tutorial, lecture: other)

      get deans_office_path(term: term.dashboard_param)

      list = page.at_css("details[data-deans-office-target='unregistered']")
      expect(list.at_css("summary").text.squish).to eq("1 lecture without registration in MaMpf")
      expect(list.text).to include(lecture.course.title)
      expect(row(lecture.course.title)).to be_nil
    end

    # A teacher may hand out places without any registration: such a group
    # counts as allocated once somebody is in it.
    it "counts a group outside any registration as allocated once it has people" do
      given = create_list(:tutorial, 2, lecture: lecture, skip_campaigns: true).last
      create(:tutorial_membership, tutorial: given)

      get deans_office_path(term: term.dashboard_param)

      expect(cells(lecture.course.title).last)
        .to eq("Allocated (1 tutorial) Not started yet (1 tutorial)")
      button = row(lecture.course.title).at_css("button[data-action='deans-office#toggle']")
      phases = page.css("##{button["aria-controls"]} tr.deans-office-group-phase")
      expect(phases.map { |tr| tr.text.squish }).to eq(["Allocated", "Not started yet"])
    end

    # Students who joined stay in a group once its sign-up closes.
    it "counts a group whose sign-up has closed as allocated if people joined" do
      joined = create(:cohort, context: lecture, title: "Joined", skip_campaigns: true,
                               self_materialization_mode: :add_only)
      create(:cohort_membership, cohort: joined)
      joined.update!(self_materialization_mode: :disabled)

      get deans_office_path(term: term.dashboard_param)

      expect(cells(lecture.course.title)).to eq(["1", "1 flexible group", "Allocated"])
    end

    # The dean's office does not know how MaMpf hands out places.
    it "explains the phases and the modes behind question marks" do
      tutorial = create(:tutorial, lecture: lecture)
      open_campaign(lecture, [tutorial])

      get deans_office_path(term: term.dashboard_param)

      helps = page.css("a[role='button'][aria-label^='Explanation']")
      state_help = helps.find { |help| help["aria-label"] == "Explanation: Registration" }
      phases = Nokogiri::HTML.fragment(state_help["data-bs-content"]).css("li strong")
      expect(phases.map(&:text)).to eq(["Registration open", "Allocation to follow",
                                        "Sign-up open", "Allocated", "Not started yet"])
      mode_help = helps.find { |help| help["aria-label"].include?("First come, first served") }
      expect(mode_help["data-bs-content"]).to include("has a place at once")
      students_help = helps.find { |help| help["aria-label"] == "Explanation: Students" }
      expect(students_help["data-bs-content"]).to include("each person once")
    end

    # A preference registration counts first wishes only, as the lecturer's
    # campaign card does; the line says so.
    it "counts a preference registration's first choices and names them so" do
      tutorial = create(:tutorial, lecture: lecture, title: "Tuesday group", location: nil)
      campaign = create(:registration_campaign, :preference_based, campaignable: lecture)
      item = create(:registration_item, registration_campaign: campaign, registerable: tutorial)
      campaign.update!(status: :open)
      [[1, :pending], [1, :rejected], [2, :pending]].each do |rank, status|
        create(:registration_user_registration, status, registration_campaign: campaign,
                                                        registration_item: item,
                                                        preference_rank: rank)
      end

      get deans_office_path(term: term.dashboard_param)

      button = row(lecture.course.title).at_css("button[data-action='deans-office#toggle']")
      details = page.at_css("##{button["aria-controls"]}")
      expect(details.at_css("tr.deans-office-group-phase").text.squish)
        .to include("By preference, first choices")
      expect(details.at_css("tbody tr:not(.deans-office-group-phase)").text.squish)
        .to eq("Tuesday group #{item.first_choice_count}")
      expect(item.first_choice_count).to eq(2)
      expect(details.at_css("[title^='First choices']")).to be_present
      expect(cells(lecture.course.title).first).to eq("2")
    end

    it "lists the lectures first and the seminars with their talks below" do
      seminar = create(:lecture, :is_seminar, term: term)
      first, second = create_list(:talk, 3, lecture: seminar)
      a, b = create_list(:confirmed_user, 2)
      [[first, a], [first, b], [second, b]].each do |talk, speaker|
        create(:speaker_talk_join, talk: talk, speaker: speaker)
      end
      create(:tutorial, lecture: lecture)

      get deans_office_path(term: term.dashboard_param)

      sections = page.css("section[data-deans-office-target='section']")
      expect(sections.map { |section| section.at_css("h2").text.strip })
        .to eq(["Lectures", "Seminars"])
      expect(sections.first.text).not_to include(seminar.course.title)
      expect(cells(seminar.course.title).first(2)).to eq(["2", "3 talks, 2 assigned"])
      # no groups to list but the talks; the speakers are counted by subject
      button = row(seminar.course.title).at_css("button[data-action='deans-office#toggle']")
      details = page.at_css("##{button["aria-controls"]}")
      expect(details.at_css("table.deans-office-groups")).to be_nil
      expect(details.at_css("table.deans-office-programs tfoot td").text).to eq("2")
    end

    it "orders by the state of the registration when asked to, soonest deadline first" do
      soon, later, unset = create_list(:lecture, 3, term: term).map do |course|
        [course, create(:tutorial, lecture: course)]
      end
      open_campaign(later.first, [later.last], deadline: 2.weeks.from_now)
      open_campaign(soon.first, [soon.last], deadline: 1.week.from_now)

      get deans_office_path(term: term.dashboard_param, order: "phase")

      table = page.at_css("table[aria-labelledby='deans-office-lectures']")
      headings = table.css("tr.deans-office-phase th").map { |th| th.text.strip }
      titles = table.css("tbody[data-deans-office-target='course'] th[scope='row'] button")
                    .map { |button| button.text.strip }
      expect(headings).to eq(["Registration open", "Not started yet"])
      expect(titles).to eq([soon, later, unset].map { |course, _| course.course.title })
      expect(page.at_css("a[aria-current='true']").text).to eq("by state of the registration")
      # each cell names the phase heading above it, which sits in a row group
      # of its own
      phase = table.at_css("tr.deans-office-phase th")["id"]
      cells = row(soon.first.course.title).at_css("tr").xpath("./td")
      expect(cells.pluck("headers")).to all(include(phase))
    end

    it "is in the navbar of admins too" do
      sign_in(create(:confirmed_user_en, admin: true))

      get deans_office_path

      expect(Nokogiri::HTML(response.body).css("nav a[href='#{deans_office_path}']")).to be_present
    end

    # The page promises a fixed number of queries per term; a figure read per
    # lecture or group would put one back for each of the 35 lectures.
    it "asks the database no more for six lectures than for two, in either order" do
      queries_for_lectures(1)

      [nil, "phase"].each do |order|
        expect(queries_for_lectures(6, order)).to eq(queries_for_lectures(2, order))
      end
    end

    it "shows another term's lectures when it is picked" do
      other = create(:lecture, term: create(:term))
      create(:tutorial, lecture: other)

      get deans_office_path(term: other.term.dashboard_param)

      expect(response.body).to include(CGI.escapeHTML(other.course.title))
    end
  end

  # The same mix of every kind of group and registration the page reads, at
  # each size.
  def queries_for_lectures(count, order = nil)
    term = create(:term)
    count.times do
      lecture = create(:lecture, term: term)
      lecture.editors << create(:confirmed_user, first_name: "Ada", last_name: "Lovelace")
      create(:lecture_membership, lecture: lecture,
                                  user: create(:confirmed_user,
                                               program: create(:program, degree: :bsc100)))
      preferred, direct, settled = create_list(:tutorial, 3, lecture: lecture, location: "SR 1")
      create(:tutorial_membership, tutorial: settled)
      cohort = create(:cohort, context: lecture)
      create(:cohort_membership, cohort: cohort)
      create(:exam, lecture: lecture)
      preference = create(:registration_campaign, :preference_based, campaignable: lecture)
      item = create(:registration_item, registration_campaign: preference, registerable: preferred)
      preference.update!(status: :open)
      create(:registration_user_registration, registration_campaign: preference,
                                              registration_item: item, preference_rank: 1)
      first_come = create(:registration_campaign, :first_come_first_served, campaignable: lecture)
      direct_item = create(:registration_item, registration_campaign: first_come,
                                               registerable: direct)
      first_come.update!(status: :open)
      create(:registration_user_registration, :confirmed, registration_campaign: first_come,
                                                          registration_item: direct_item)
      completed = create(:registration_campaign, campaignable: lecture)
      create(:registration_item, registration_campaign: completed, registerable: settled)
      completed.update_columns(status: Registration::Campaign.statuses[:completed]) # rubocop:disable Rails/SkipsModelValidations
      create(:registration_campaign, campaignable: create(:lecture, term: term))
      seminar = create(:lecture, :is_seminar, term: term)
      create(:speaker_talk_join, talk: create(:talk, lecture: seminar),
                                 speaker: create(:confirmed_user))
      create(:talk, lecture: seminar)
    end

    count_queries { get(deans_office_path(term: term.dashboard_param, order: order)) }
  end

  def count_queries(&)
    queries = 0
    counter = lambda { |*, payload|
      queries += 1 unless payload[:name].to_s.match?(/SCHEMA|TRANSACTION/)
    }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    queries
  end

  describe "the admin's switch" do
    let(:account) { create(:confirmed_user) }

    it "lets an admin give somebody the dean's office role" do
      sign_in(create(:confirmed_user, admin: true))

      patch support_user_path(account), params: { user: { deans_office: "1" } }

      expect(account.reload).to be_deans_office
    end

    it "does not let a teacher or the support give the dean's office role" do
      teacher = create(:confirmed_user)
      create(:lecture, teacher: teacher)
      [teacher, create(:confirmed_user, support: true)].each do |user|
        sign_in(user)

        patch support_user_path(account), params: { user: { name: "Ada", deans_office: "1" } }
        patch support_user_path(user), params: { user: { name: "Ada", deans_office: "1" } }
      end

      expect(User.where(deans_office: true)).to be_empty
    end
  end
end
