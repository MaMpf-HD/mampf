module StudentMessages
  # One group a message can go to, named by a key such as "tutorial:3" or
  # "campaign:2:rejected" and listed under a heading of the picker. Knows
  # who is in it; the catalog decides who may pick it, and hands over the
  # count it read for a whole section at once, so the picker does not ask
  # one query per group.
  class Audience
    attr_reader :key, :label, :heading

    def initialize(key:, label:, heading:, users:, count: nil)
      @key = key
      @label = label
      @heading = heading
      @users = users
      @count = count
    end

    def user_ids
      @user_ids ||= @users.distinct.pluck(:id)
    end

    def count
      @count || user_ids.size
    end

    def emails
      User.where(id: user_ids).pluck(:email)
    end
  end
end
