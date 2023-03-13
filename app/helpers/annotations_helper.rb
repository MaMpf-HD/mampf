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
  
  def annotation_color(int)
    case int
    when 1
      return '#DB2828'
    when 2
      return '#F2711C'
    when 3
      return '#FBBD08'
    when 4
      return '#B5CC18'
    when 5
      return '#21BA45'
    when 6
      return '#00B5AD'
    when 7
      return '#2185D0'
    when 8
      return '#6435C9'
    when 9
      return '#A333C8'
    when 10
      return '#E03997'
    when 11
      return '#d05d41'
    when 12
      return '#924129'
    when 13
      return '#444444'
    when 14
      return '#999999'
    when 15
      return '#eeeeee'
    end
  end
  
end
