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

  it "ensures all including models have correct exclusive_assignment" do
    Rails.application.eager_load!

    models = ApplicationRecord.descendants.select do |model|
      model.included_modules.include?(described_class)
    end

    models.each do |model|
      instance = model.new
      expect(instance).to respond_to(:exclusive_assignment?)
      if model == Cohort
        expect(instance.exclusive_assignment?).to eq(false)
      else
        expect(instance.exclusive_assignment?).to eq(true)
      end
    end
  end

  # The class method answers a different question from the instance method: not
  # "one registration per campaign" but "does allocating here displace a sibling
  # assignment". Only a tutorial displaces one, so only Tutorial says true.
  it "ensures only tutorials claim exclusivity across siblings" do
    Rails.application.eager_load!

    models = ApplicationRecord.descendants.select do |model|
      model.included_modules.include?(described_class)
    end

    models.each do |model|
      expect(model.displaces_sibling_assignment?).to eq(model == Tutorial),
                                                     "#{model}.displaces_sibling_assignment? " \
                                                     "is wrong"
    end
  end
end
