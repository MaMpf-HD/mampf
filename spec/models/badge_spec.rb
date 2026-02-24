require "rails_helper"
require "securerandom"

RSpec.describe(Badge, type: :model) do
  before :each do
    FactoryBot.create(:badge, :comments)
    FactoryBot.create(:badge, :annotations)
    FactoryBot.create(:badge, :threads)
  end

  it "has only valid factories" do
    expect(FactoryBot.build(:badge, :comments)).to be_valid
    expect(FactoryBot.build(:badge, :annotations)).to be_valid
    expect(FactoryBot.build(:badge, :threads)).to be_valid
  end

  it "does not award comment badge if conditions are not met" do
    user = FactoryBot.build(:confirmed_user)
    badge = Badge.where(icon_key: "comments_icon")
    Badge.check_comment_badge_for(user)

    expect(badge.in?(user.badges)).to be(false)
  end

  it "does not award annotation badge if conditions are not met" do
    user = FactoryBot.build(:confirmed_user)
    badge = Badge.where(icon_key: "annotations_icon")
    Badge.check_annotation_badge_for(user)

    expect(badge.in?(user.badges)).to be(false)
  end

  it "does not award thread badge if conditions are not met" do
    user = FactoryBot.build(:confirmed_user)
    badge = Badge.where(icon_key: "threads_icon")
    Badge.check_threads_badge_for(user)

    expect(badge.in?(user.badges)).to be(false)
  end

  it "awards comment badge at 10 comments" do
    user = FactoryBot.create(:confirmed_user)
    medium = FactoryBot.create(:lecture_medium)

    10.times do
      Commontator::Comment.create!(
        thread: medium.commontator_thread,
        creator: user,
        body: Faker::Lorem.sentence
      )
    end

    Badge.check_comment_badge_for(user)
    expect(user.badges.where(icon_key: "comments_icon")).to exist
  end

  it "awards annotation badge at 10 visible annotations" do
    user = FactoryBot.create(:confirmed_user)
    medium = FactoryBot.create(:lecture_medium)

    10.times do
      FactoryBot.create(
        :annotation,
        user_id: user.id,
        medium_id: medium.id,
        visible_for_teacher: true
      )
    end
    Badge.check_annotation_badge_for(user)

    expect(user.badges.where(icon_key: "annotations_icon")).to exist
  end

  it "does not award annotation badge from non visible annotations" do
    user = FactoryBot.create(:confirmed_user)
    medium = FactoryBot.create(:lecture_medium)

    10.times do
      FactoryBot.create(
        :annotation,
        user_id: user.id,
        medium_id: medium.id,
        visible_for_teacher: false
      )
    end
    Badge.check_annotation_badge_for(user)

    expect(user.badges.where(icon_key: "annotations_icon")).not_to exist
  end

  it "awards thread badge at 10 topics" do
    user = FactoryBot.create(:confirmed_user)
    mb = Thredded::Messageboard.create!(name: "Test", position: 1)
    10.times do |i|
      Thredded::Topic.create!(
        user_id: user.id,
        last_user_id: user.id,
        title: "Topic #{i} #{SecureRandom.hex(4)}",
        slug: "topic-#{user.id}-#{i}-#{SecureRandom.hex(4)}",
        messageboard_id: mb.id,
        hash_id: SecureRandom.hex(10),
        moderation_state: 0
      )
    end
    Badge.check_threads_badge_for(user)
    expect(user.badges.where(icon_key: "threads_icon")).to exist
  end
end
