module StudentMessages
  # One group a message can go to, named by a key such as "tutorial:3" or
  # "campaign:2:rejected" and listed under a heading of the picker. Knows
  # who is in it; the catalog decides who may pick it, and hands over the
  # count it read for a whole section at once, so the picker does not ask
  # one query per group.
  class Audience
    attr_reader :key, :label, :heading, :users

    def initialize(key:, label:, heading:, users:, count: nil)
      @key = key
      @label = label
      @heading = heading
      @users = users
      @count = count
    end

    # Everybody in any of the audiences, once: one query with a subselect
    # per audience, however many were picked.
    def self.recipients(audiences)
      return User.none if audiences.empty?

      audiences.map { |audience| User.where(id: audience.users.select(:id)) }.reduce(:or)
    end

    def user_ids
      @user_ids ||= @users.distinct.pluck(:id)
    end

    def count
      @count || user_ids.size
    end

    def emails
      Audience.recipients([self]).pluck(:email)
    end
  end
end
