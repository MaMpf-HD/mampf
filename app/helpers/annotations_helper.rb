module AnnotationsHelper
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
