module StudentMessages
  # One group a message can go to, named by a key such as "tutorial:3" or
  # "campaign:2:rejected" and listed under a heading of the picker. Knows
  # who is in it; the catalog decides who may pick it.
  class Audience
    attr_reader :key, :label, :heading

    def initialize(key:, label:, heading:, users:)
      @key = key
      @label = label
      @heading = heading
      @users = users
    end

    def user_ids
      @user_ids ||= @users.distinct.pluck(:id)
    end

    def count
      user_ids.size
    end

    def emails
      User.where(id: user_ids).pluck(:email)
    end
  end
end
