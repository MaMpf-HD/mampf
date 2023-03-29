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
    color_map = {
       1 => '#DB2828',
       2 => '#F2711C',
       3 => '#FBBD08',
       4 => '#B5CC18',
       5 => '#21BA45',
       6 => '#00B5AD',
       7 => '#2185D0',
       8 => '#6435C9',
       9 => '#A333C8',
      10 => '#E03997',
      11 => '#d05d41',
      12 => '#924129',
      13 => '#444444',
      14 => '#999999',
      15 => '#eeeeee'
    }
    color_map[int] || '#000000'
  end
  
end
