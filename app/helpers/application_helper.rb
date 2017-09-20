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
end
