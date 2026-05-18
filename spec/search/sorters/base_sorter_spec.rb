require "rails_helper"

# A dummy sorter for testing the BaseSorter's class-level sort method.
# Defined at the top level to avoid linter warnings (Lint/ConstantDefinitionInBlock).
class DummySorter < Search::Sorters::BaseSorter
  def sort
    scope.order(created_at: :asc)
  end
end

RSpec.describe(Search::Sorters::BaseSorter) do
  let(:scope) { double("ActiveRecord::Relation") }
  let(:model_class) { double("Class") }
  let(:search_params) { { some_param: "value" } }

  describe "#initialize" do
    subject(:sorter) do
      described_class.new(scope: scope, model_class: model_class, search_params: search_params)
    end

    it "assigns the scope" do
      expect(sorter.scope).to eq(scope)
    end

    it "assigns the model_class" do
      expect(sorter.model_class).to eq(model_class)
    end

    it "assigns the search_params with indifferent access" do
      expect(sorter.search_params).to be_a(ActiveSupport::HashWithIndifferentAccess)
      expect(sorter.search_params[:some_param]).to eq("value")
    end
  end

  describe "#sort" do
    subject(:sorter) do
      described_class.new(scope: scope, model_class: model_class, search_params: search_params)
    end

    it "raises a NotImplementedError" do
      expect { sorter.sort }.to raise_error(NotImplementedError)
    end
  end

  # This block tests the class method's logic, including the `reverse` functionality.
  # It uses a real scope and a dummy subclass to verify the end-to-end behavior.
  describe ".sort" do
    let!(:medium1) { create(:valid_medium, created_at: 1.day.ago) }
    let!(:medium2) { create(:valid_medium, created_at: Time.current) }
    let(:scope) { Medium.all }
    let(:model_class) { Medium }

    subject(:sorted_scope) do
      DummySorter.sort(scope: scope, model_class: model_class, search_params: search_params)
    end

    context "without the reverse parameter" do
      let(:search_params) { {} }

      it "returns the scope ordered by the subclass's logic" do
        expect(sorted_scope.to_a).to eq([medium1, medium2])
      end
    end

    context "with reverse: true" do
      let(:search_params) { { reverse: true } }

      it "reverses the order of the scope" do
        expect(sorted_scope.to_a).to eq([medium2, medium1])
      end
    end

    context "with reverse: 'true'" do
      let(:search_params) { { reverse: "true" } }

      it "reverses the order of the scope" do
        expect(sorted_scope.to_a).to eq([medium2, medium1])
      end
    end

    context "with reverse: false" do
      let(:search_params) { { reverse: false } }

      it "does not reverse the order of the scope" do
        expect(sorted_scope.to_a).to eq([medium1, medium2])
      end
    end
  end
end
