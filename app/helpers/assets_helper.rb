module AssetsHelper
  def tags(asset)
    asset.tags.map(&:title).join(', ')
  end
end
