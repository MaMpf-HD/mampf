require "rails_helper"

RSpec.describe(ParticipationComponent, type: :component) do
  around do |example|
    I18n.with_locale(:en) { example.run }
  end

  let(:course) { create(:course, title: "Linear Algebra") }
  let(:lecture) { create(:lecture, course: course) }
  let(:user) { create(:confirmed_user, email: "student@play") }

  describe "policy rejection messages" do
    it "renders finalization-specific email-policy rejections" do
      campaign = create(
        :registration_campaign,
        :first_come_first_served,
        :with_items,
        campaignable: lecture,
        description: "Email checked tutorial registration",
        items_count: 1
      )
      policy = create(
        :registration_policy,
        :institutional_email,
        :for_finalization,
        registration_campaign: campaign,
        config: { "allowed_domains" => ["example.com"] }
      )
      campaign.update!(status: :completed)
      create(
        :registration_user_registration,
        :policy_rejected,
        registration_campaign: campaign,
        registration_item: campaign.registration_items.first,
        user: user,
        rejection_policy: policy,
        rejection_reason_code: "institutional_email_mismatch"
      )

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Email checked tutorial registration")
      expect(rendered.text).to include("Rejected")
      expect(rendered.text).to include(
        "At the time this registration process was finalized"
      )
      expect(rendered.text).to include("required email domains example.com")
      expect(rendered.text).not_to include("Your current email domain is play")
      expect(rendered.css("a")).to be_empty
    end

    it "uses the stored rejection code after the student fixes the policy issue" do
      prerequisite_campaign = create(
        :registration_campaign,
        :completed,
        campaignable: lecture,
        description: "Priority registration",
        items_count: 1
      )
      campaign = create(
        :registration_campaign,
        :first_come_first_served,
        :with_items,
        campaignable: lecture,
        description: "Follow-up tutorial registration",
        items_count: 1
      )
      policy = create(
        :registration_policy,
        :prerequisite_campaign,
        :for_finalization,
        registration_campaign: campaign,
        config: { "prerequisite_campaign_id" => prerequisite_campaign.id }
      )
      campaign.update!(status: :completed)
      create(
        :registration_user_registration,
        :policy_rejected,
        registration_campaign: campaign,
        registration_item: campaign.registration_items.first,
        user: user,
        rejection_policy: policy,
        rejection_reason_code: "prerequisite_not_met",
        rejection_reason_label: "Prerequisite was missing."
      )
      create(
        :registration_user_registration,
        :confirmed,
        registration_campaign: prerequisite_campaign,
        registration_item: prerequisite_campaign.registration_items.first,
        user: user
      )

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include(
        "At the time this registration process was finalized, you did not have a " \
        "confirmed registration in"
      )
      expect(rendered.text).to include("Priority registration")
      expect(rendered.text).not_to include("Your registration was rejected.")
    end

    it "renders the prerequisite campaign label for prerequisite-policy rejections" do
      prerequisite_campaign = create(
        :registration_campaign,
        :completed,
        campaignable: lecture,
        description: "Priority registration",
        items_count: 1
      )
      campaign = create(
        :registration_campaign,
        :first_come_first_served,
        :with_items,
        campaignable: lecture,
        description: "Follow-up tutorial registration",
        items_count: 1
      )
      policy = create(
        :registration_policy,
        :prerequisite_campaign,
        :for_finalization,
        registration_campaign: campaign,
        config: { "prerequisite_campaign_id" => prerequisite_campaign.id }
      )
      campaign.update!(status: :completed)
      create(
        :registration_user_registration,
        :policy_rejected,
        registration_campaign: campaign,
        registration_item: campaign.registration_items.first,
        user: user,
        rejection_policy: policy,
        rejection_reason_code: "prerequisite_not_met"
      )

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include(
        "At the time this registration process was finalized, you did not have a " \
        "confirmed registration in"
      )
      expect(rendered.text).to include("Priority registration")
    end

    it "uses the stored policy id when multiple policies share a rejection code" do
      wrong_prerequisite_campaign = create(
        :registration_campaign,
        :completed,
        campaignable: lecture,
        description: "Wrong prerequisite registration",
        items_count: 1
      )
      correct_prerequisite_campaign = create(
        :registration_campaign,
        :completed,
        campaignable: lecture,
        description: "Correct prerequisite registration",
        items_count: 1
      )
      campaign = create(
        :registration_campaign,
        :first_come_first_served,
        :with_items,
        campaignable: lecture,
        description: "Follow-up tutorial registration",
        items_count: 1
      )
      create(
        :registration_policy,
        :prerequisite_campaign,
        :for_finalization,
        registration_campaign: campaign,
        config: { "prerequisite_campaign_id" => wrong_prerequisite_campaign.id }
      )
      correct_policy = create(
        :registration_policy,
        :prerequisite_campaign,
        :for_finalization,
        registration_campaign: campaign,
        config: { "prerequisite_campaign_id" => correct_prerequisite_campaign.id }
      )
      campaign.update!(status: :completed)
      create(
        :registration_user_registration,
        :policy_rejected,
        registration_campaign: campaign,
        registration_item: campaign.registration_items.first,
        user: user,
        rejection_policy: correct_policy,
        rejection_reason_code: "prerequisite_not_met"
      )

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Correct prerequisite registration")
      expect(rendered.text).not_to include("Wrong prerequisite registration")
    end
  end

  describe "standings before the allocation" do
    it "leaves the preferences of a campaign still open to its own row" do
      campaign = create(:registration_campaign, :preference_based, :open,
                        campaignable: lecture, items_count: 1)
      create(:registration_user_registration,
             registration_campaign: campaign,
             registration_item: campaign.registration_items.first,
             user: user, preference_rank: 1)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to be_blank
    end

    it "shows saved preferences as waiting for the allocation" do
      campaign = create(:registration_campaign, :preference_based, :closed,
                        campaignable: lecture, items_count: 2)
      first, second = campaign.registration_items.order(:id).to_a
      create(:registration_user_registration, registration_campaign: campaign,
                                              registration_item: second, user: user,
                                              preference_rank: 1)
      create(:registration_user_registration, registration_campaign: campaign,
                                              registration_item: first, user: user,
                                              preference_rank: 2)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Waiting for allocation")
      expect(rendered.text.squish)
        .to include("1st #{second.title} · 2nd #{first.title}")
    end

    it "keeps every ranked choice while the allocation awaits finalization" do
      campaign = create(:registration_campaign, :preference_based, :processing,
                        campaignable: lecture, items_count: 2)
      first, second = campaign.registration_items.order(:id).to_a
      create(:registration_user_registration, :confirmed, registration_campaign: campaign,
                                                          registration_item: first,
                                                          user: user, preference_rank: 1)
      create(:registration_user_registration, registration_campaign: campaign,
                                              registration_item: second, user: user,
                                              preference_rank: 2)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Waiting for allocation")
      expect(rendered.text.squish).to include("1st #{first.title} · 2nd #{second.title}")
    end

    it "keeps the allocation pending for a place assigned outside the choices" do
      campaign = create(:registration_campaign, :preference_based, :processing,
                        campaignable: lecture, items_count: 1)
      create(:registration_user_registration, :confirmed,
             registration_campaign: campaign,
             registration_item: campaign.registration_items.first,
             user: user, preference_rank: nil)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Waiting for allocation")
    end

    it "says that a first come, first served place is checked again" do
      campaign = create(:registration_campaign, :first_come_first_served, :closed,
                        campaignable: lecture, items_count: 1)
      item = campaign.registration_items.first
      create(:registration_user_registration, :confirmed,
             registration_campaign: campaign, registration_item: item, user: user)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include(item.registerable.title)
      expect(rendered.text).to include("Registered")
      expect(rendered.text)
        .to include("The requirements are checked again when the process is finalized.")
    end
  end

  describe "outcomes" do
    it "shows a capacity rejection with the preferences that could not be met" do
      campaign = create(:registration_campaign, :preference_based, :with_items,
                        campaignable: lecture, items_count: 1,
                        description: "Tutorial allocation")
      campaign.update!(status: :completed)
      item = campaign.registration_items.first
      create(:registration_user_registration, :capacity_rejected,
             registration_campaign: campaign, registration_item: item,
             user: user, preference_rank: 1)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Tutorial allocation")
      expect(rendered.text).to include("No place")
      expect(rendered.text).to include("Your preferences: 1st #{item.title}")
    end

    it "shows the tutorial a student was assigned to" do
      tutorial = create(:tutorial, lecture: lecture, title: "Tutorial 4")
      create(:tutorial_membership, tutorial: tutorial, user: user)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Tutorial 4")
      expect(rendered.text).to include("Assigned")
    end

    it "says when a student was taken off an exam list" do
      exam = create(:exam, lecture: lecture)
      create(:exam_roster_entry, exam: exam, user: user, excluded_at: Time.current)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Removed from the exam list")
    end

    it "renders nothing without any standing" do
      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to be_blank
    end
  end

  describe "published results" do
    let(:exam) { create(:exam, lecture: lecture, title: "Final Exam") }
    let(:assessment) { exam.assessment }
    let!(:first_task) do
      create(:assessment_task, assessment: assessment, max_points: 10, position: 1,
                               description: nil)
    end
    let!(:second_task) do
      create(:assessment_task, assessment: assessment, max_points: 20, position: 2,
                               description: "Proof")
    end
    let(:participation) do
      create(:assessment_participation, assessment: assessment, user: user)
    end

    before do
      create(:exam_roster_entry, exam: exam, user: user)
      create(:assessment_task_point, assessment_participation: participation,
                                     task: first_task, points: 7.5)
      create(:assessment_task_point, assessment_participation: participation,
                                     task: second_task, points: 12)
      participation.update!(status: :reviewed, points_total: 19.5, grade_numeric: 2.3)
    end

    def render_row
      render_inline(described_class.new(lecture: lecture, user: user))
        .css("[data-testid=participation-row]").find { |row| row.text.include?("Final Exam") }
    end

    it "shows nothing of the result before it is published" do
      row = render_row

      expect(row.text).to include("On the exam list")
      expect(row.text).not_to include("2.3")
      expect(row.css("details")).to be_empty
    end

    it "shows the grade, the points and the points per problem once published" do
      assessment.update!(results_published_at: Time.current)

      row = render_row

      expect(row.text.squish).to include("Grade 2.3")
      expect(row.text.squish).to include("19.5 of 30 points")
      problems = row.css("details dt").map { |term| term.text.squish }
      expect(problems).to eq(["Problem 1", "Proof"])
      expect(row.css("details dd").map { |value| value.text.squish }).to eq(["7.5 / 10", "12 / 20"])
    end

    it "says so for a student who did not take part" do
      participation.update!(status: :absent, grade_numeric: 5.0)
      assessment.update!(results_published_at: Time.current)

      row = render_row

      expect(row.text.squish).to include("Did not take part")
      expect(row.text.squish).to include("Grade 5.0")
      expect(row.css("details")).to be_empty
    end

    it "says so for a student who was exempted" do
      participation.update!(status: :exempt, grade_numeric: nil)
      assessment.update!(results_published_at: Time.current)

      expect(render_row.text.squish).to include("Exempt")
    end

    it "shows a speaker the talk's grade but never the lecturer's note" do
      seminar = create(:lecture, sort: "seminar")
      talk = create(:talk, lecture: seminar, title: "Sylow theorems")
      create(:speaker_talk_join, talk: talk, speaker: user)
      create(:assessment_participation, assessment: talk.assessment, user: user,
                                        status: :reviewed, grade_numeric: 1.7,
                                        note: "Rushed the last proof")
      talk.assessment.update!(results_published_at: Time.current)

      rendered = render_inline(described_class.new(lecture: seminar, user: user))

      expect(rendered.text.squish).to include("Grade 1.7")
      expect(rendered.text).not_to include("Rushed the last proof")
    end
  end
end
