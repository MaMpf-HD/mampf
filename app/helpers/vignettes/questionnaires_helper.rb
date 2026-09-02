module Vignettes
  module QuestionnairesHelper
    def format_question_text(text)
      return "" if text.blank?

      text = text.to_s.dup
      text.gsub!(/\*\*(.*?)\*\*/, '<strong>\1</strong>') # Bold
      text.gsub!(/\*([^*]+)\*/, '<em>\1</em>') # Italic

      sanitize(
        simple_format(text, {}, sanitize: false),
        tags: ["p", "br", "strong", "em"],
        attributes: []
      )
    end
  end
end
