Rails::Env.class_eval do
  def production?
    super || production_vignette?
  end
end
