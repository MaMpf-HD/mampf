# Shows texts that users write with only the formatting each of them needs.
module UserTextHelper
  # What the comment preview allows (see tex_preview.coffee), plus links.
  COMMENT_TAGS = ["b", "em", "strong", "i", "br", "p", "code", "pre",
                  "a"].freeze

  # What the Trix editor writes for a talk description. Its attachment button
  # is removed there, so images are not part of it.
  TALK_DESCRIPTION_TAGS = ["div", "br", "strong", "em", "del", "a", "h1",
                           "blockquote", "pre", "ul", "ol", "li"].freeze

  # Keeps the given tags without their attributes. Only a link keeps its
  # address, as long as that is a web or a mail address. The text inside a
  # removed tag stays.
  class Scrubber < Rails::HTML::PermitScrubber
    LINK_ADDRESS = %r{\A(https?://|mailto:)}i

    def initialize(tags)
      super()
      self.tags = tags
      self.attributes = ["href"]
    end

    protected

      def scrub_attribute(node, attr_node)
        return super if node.name == "a" && attr_node.value.match?(LINK_ADDRESS)

        attr_node.remove
      end
  end

  # Splits the comment into paragraphs the way Commontator does.
  def format_comment_body(text)
    commontator_simple_format(
      sanitize(text, scrubber: Scrubber.new(COMMENT_TAGS))
    )
  end

  def format_talk_description(text)
    sanitize(text, scrubber: Scrubber.new(TALK_DESCRIPTION_TAGS))
  end
end
