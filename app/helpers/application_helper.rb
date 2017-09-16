module ApplicationHelper
  def concat_content_tag(*args, &blk)
   concat content_tag(*args, &blk)
 end
end
