class Badge < ApplicationRecord
  has_many :user_badges
  has_many :users, through: :user_badges

  def self.check_comment_badge_for(user)
    return unless user.commontator_comments.count == 10

    badge = find_by(icon_key: "comments_icon")
    return unless badge

    user.user_badges.find_or_create_by(badge: badge) do |ub|
      ub.achieved_at = Time.current
    end
  end

  def self.check_annotation_badge_for(user)
    return unless user.own_annotations.where(visible_for_teacher: true).count == 10

    badge = find_by(icon_key: "annotations_icon")
    return unless badge

    user.user_badges.find_or_create_by(badge: badge) do |ub|
      ub.achieved_at = Time.current
    end
  end

  def self.check_threads_badge_for(user)
    return unless user.thredded_topics.count == 10

    badge = find_by(icon_key: "threads_icon")
    return unless badge

    user.user_badges.find_or_create_by(badge: badge) do |ub|
      ub.achieved_at = Time.current
    end
  end

  # TODO: add remaining badges

  def icon_path
    "badges/#{icon_key}.svg"
  end
end
