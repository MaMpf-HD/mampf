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
  
  def color(int)
  	case int
  	when 1
  	  return '#ff0000'
  	when 2
  	  return '#ff8800'
  	when 3
  	  return '#ffff00'
  	when 4
  	  return '#00ff00'
  	when 5
  	  return '#00ffff'
  	when 6
  	  return '#0000ff'
  	when 7
  	  return '#dd00ff'
  	when 8
  	  return '#ff99ff'
  	when 9
  	  return '#aa5500'
  	when 10
  	  return '#993300'
  	when 11
  	  return '#ffffff'
  	when 12
  	  return '#888888'
  	when 13
  	  return '#000000'
  	end
  end
end
