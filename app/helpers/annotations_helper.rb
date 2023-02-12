module AnnotationsHelper
  def category_text_to_int(text)
    case text
    when 'Need help!'
      return Annotation.categories[:help]
    when 'Found a mistake'
      return Annotation.categories[:mistake]
    when 'Give a comment'
      return Annotation.categories[:comment]
    when 'Note'
      return Annotation.categories[:note]
    when 'Other'
      return Annotation.categories[:other]
    end
  end
  
  def category_token_to_text(token)
    case token
    when 'help'
      return 'Need help!'
    when 'mistake'
      return 'Found a mistake'
    when 'comment'
      return 'Give a comment'
    when 'note'
      return "Note"
    when 'other'
      return 'Other'
    end
  end
end
