# Extend the behavior of Rails.env.production?
Rails.env.singleton_class.prepend(
  Module.new do
    def production?
      super || self == "production_vignette"
    end
  end
)
