require "rails_helper"

# Medium#visible_for_user? answers for one medium, User#filter_visible_media
# for a whole relation (lists, search, quizzes); for a student they have to
# agree in every case, or a medium shows up in one place and not the other.
RSpec.describe(Medium) do
  let(:student) { create(:confirmed_user) }

  let(:lecture_states) do
    { "open" => { released: "all", passphrase: nil },
      "locked, released to all" => { released: "all", passphrase: "open sesame" },
      "locked, released to users" => { released: "users", passphrase: "open sesame" } }
  end
  let(:releases) { [nil, "locked", "all", "users", "subscribers"] }
  let(:participation) { [false, true] }

  def medium_with_lecture(kind)
    case kind
    when :lecture then (medium = create(:lecture_medium)).then { [medium, medium.teachable] }
    when :lesson then (medium = create(:lesson_medium)).then { [medium, medium.teachable.lecture] }
    when :talk then (medium = create(:talk_medium)).then { [medium, medium.teachable.lecture] }
    when :course
      medium = create(:course_medium)
      [medium, create(:lecture, course: medium.teachable)]
    end
  end

  def take_part(lecture)
    campaign = create(:registration_campaign, :open, :with_items, campaignable: lecture)
    create(:registration_user_registration, :pending,
           user: student, registration_campaign: campaign,
           registration_item: campaign.registration_items.first)
  end

  it "agrees with User#filter_visible_media for every kind, lecture state and release" do
    mismatches = []
    [:lecture, :lesson, :talk, :course].each do |kind|
      lecture_states.each do |state, lecture_attributes|
        participation.each do |participant|
          releases.each do |release|
            medium, lecture = medium_with_lecture(kind)
            lecture.update!(lecture_attributes)
            medium.update!(released: release, released_at: Time.zone.now)
            take_part(lecture) if participant

            single = medium.visible_for_user?(student)
            bulk = student.filter_visible_media(Medium.where(id: medium.id)).exists?
            next if single == bulk

            mismatches << "#{kind}, #{state}, participant: #{participant}, " \
                          "#{release.inspect}: single #{single}, bulk #{bulk}"
          end
        end
      end
    end

    expect(mismatches).to be_empty
  end
end
