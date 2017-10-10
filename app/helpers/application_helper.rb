module ApplicationHelper
  def concat_content_tag(*args, &blk)
   concat content_tag(*args, &blk)
  end

  # Returns the full title on a per-page basis.
  def full_title(page_title = '')
    base_title = 'MaMpf'
    if page_title.empty?
      base_title
    else
      base_title + ' | ' + page_title
    end
  end

  def split_list(list,n=4)
    list.in_groups_of((list.count/n.to_f).round)
  end

  def filter_tags_by_lectures(tags, filter_lectures)
    Tag.where(id: tags.select { |t| t.in_lectures?(filter_lectures) }.map(&:id))
  end

  def filter_lectures_by_lectures(lectures, filter_lectures)
    Lecture.where(id: lectures.pluck(:id) & filter_lectures.pluck(:id))
  end

  def filter_media_by_lectures(media, filter_lectures)
    Medium.where(id: media.select { |m| m.related_to_lectures?(filter_lectures) }.map(&:id))
  end
  # def active_module
  #   item_class = Array.new(5, '')
  #   if params[:module_id]
  #     item_class[params[:module_id].to_i] = ' active'
  #   end
  #   item_class
  # end

end
