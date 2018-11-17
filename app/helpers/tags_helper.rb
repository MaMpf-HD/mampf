module TagsHelper
  def tag_link(tag, inspection)
    inspection ? inspect_tag_path(tag) : edit_tag_path(tag)
  end
end
