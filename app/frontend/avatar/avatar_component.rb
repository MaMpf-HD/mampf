# Round avatar badge for user-related UI elements.
class AvatarComponent < ViewComponent::Base
  def initialize(user:)
    super()
    @user = user
  end

  def call
    tag.span(initials, class: "avatar", "aria-hidden": "true")
  end

  private

    # User initials, e.g. "John Doe" => "JD", "John" => "J", "John van Doe" => "JD"
    def initials
      words = (@user.full_name || @user.name_or_email).to_s.split
      return "?" if words.empty?

      [words.first, words.last].first(words.size).pluck(0).join.upcase
    end
end
