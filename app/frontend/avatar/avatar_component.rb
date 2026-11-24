# Round avatar badge for user-related UI elements.
class AvatarComponent < ViewComponent::Base
  def initialize(user:)
    super()
    @user = user
  end

  def call
    tag.span(initials, class: "user-avatar", "aria-hidden": "true")
  end

  private

    # User initials, e.g. "John Doe" => "JD", "John" => "J", "John van Doe" => "JD"
    # Words not starting with a letter (e.g. emojis, brackets) are ignored.
    def initials
      words = initials_source.to_s.scan(/\p{L}[^[:space:]]*/)
      return "?" if words.empty?

      [words.first, words.last].first(words.size)
                               .map { |word| word.grapheme_clusters.first }
                               .join.upcase
    end

    def initials_source
      @user.full_name || @user.name.presence || @user.email.to_s.split("@").first
    end
end
