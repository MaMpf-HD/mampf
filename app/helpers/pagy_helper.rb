module PagyHelper
  # Overrides the default pagy_bootstrap_nav to prevent it from rendering
  # when there is only one page.
  def pagy_bootstrap_nav(pagy, **vars)
    return if pagy.nil? || pagy.pages <= 1

    super
  end
end
