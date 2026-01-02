module PagyHelper
  # Wrapper for series_nav to prevent it from rendering when there is only
  # one page.
  def pagy_series_nav(pagy, style = :bootstrap, **vars)
    return if pagy.nil? || pagy.pages <= 1

    pagy.series_nav(style, **vars)
  end
end
