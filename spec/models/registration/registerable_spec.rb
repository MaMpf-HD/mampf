require "rails_helper"

RSpec.describe(Registration::Registerable) do
  it "ensures all including models have a capacity attribute" do
    # Eager load the application to ensure all models are loaded and discoverable
    Rails.application.eager_load!

    models = ApplicationRecord.descendants.select do |model|
      model.included_modules.include?(described_class)
    end

    models.each do |model|
      expect(model.new).to(respond_to(:capacity), "#{model} must have a capacity attribute")
    end
  end
end
