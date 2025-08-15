module PagyHelper
  # Override the default pagy_bootstrap_nav to prevent it from rendering
  # when there is only one page. This keeps the views cleaner.
  def pagy_bootstrap_nav(pagy, **vars)
    return if pagy.pages <= 1

    super
  end
end
