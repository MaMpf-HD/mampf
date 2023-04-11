module AnnotationsHelper
  def category_text_to_int(text)
    case text
    when 'I want to create a personal note.'
      return Annotation.categories[:note]
    when 'I have a problem with understanding the content.'
      return Annotation.categories[:content]
    when 'I found a mistake.'
      return Annotation.categories[:mistake]
    when 'I can\'t read everything in this part.'
      return Annotation.categories[:presentation]
    end
  end
  
  def category_token_to_text(token)
    case token
    when 'note'
      return 'I want to create a personal note.'
    when 'content'
      return 'I have a problem with understanding the content.'
    when 'mistake'
      return 'I found a mistake.'
    when 'presentation'
      return 'I can\'t read everything in this part.'
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
