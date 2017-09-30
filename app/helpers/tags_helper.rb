module TagsHelper
  def split_tags(tags)
    tags.in_groups_of((tags.count/4.0).round)
  end
end
