module AssetsHelper
  def tags(medium)
    medium.tags.map(&:title).join(', ')
  end
end
