require "rails_helper"

RSpec.describe(SearchForm::Fields::Services::CssManager, type: :component) do
  # The field that the manager serves.
  let(:field) { instance_double(SearchForm::Fields::Field, "field") }

  # The manager instance under test.
  subject(:manager) { described_class.new(field) }

  describe "#extract_field_classes" do
    context "when the field has default classes" do
      before do
        allow(field).to receive(:default_field_classes).and_return(["default-class"])
      end

      it "returns only the default classes when no user class is provided" do
        options = {}
        expect(manager.extract_field_classes(options)).to eq("default-class")
      end

      it "combines default and user-provided classes" do
        options = { class: "user-class" }
        expect(manager.extract_field_classes(options)).to eq("default-class user-class")
      end
    end

    context "when the field has no default classes" do
      before do
        allow(field).to receive(:default_field_classes).and_return([])
      end

      it "returns an empty string when no classes are provided" do
        options = {}
        expect(manager.extract_field_classes(options)).to eq("")
      end

      it "returns only the user-provided class" do
        options = { class: "user-class" }
        expect(manager.extract_field_classes(options)).to eq("user-class")
      end
    end

    context "when the user-provided class is nil" do
      it "returns only the default classes" do
        allow(field).to receive(:default_field_classes).and_return(["default-class"])
        options = { class: nil }
        expect(manager.extract_field_classes(options)).to eq("default-class")
      end
    end
  end

  describe "#field_css_classes" do
    before do
      # This method relies on both `field_class` and `options` from the field.
      allow(field).to receive(:field_class).and_return(field_class_value)
      allow(field).to receive(:options).and_return(options_value)
      allow(field).to receive(:default_field_classes).and_return(default_classes_value)
    end

    let(:field_class_value) { "base-class" }
    let(:options_value) { { class: "user-class" } }
    let(:default_classes_value) { ["default-class"] }

    it "combines field_class, default_classes, and user-provided classes" do
      expect(manager.field_css_classes).to eq("base-class default-class user-class")
    end

    context "when field_class is nil" do
      let(:field_class_value) { nil }

      it "combines only default and user-provided classes" do
        expect(manager.field_css_classes).to eq("default-class user-class")
      end
    end

    context "when there are no additional classes" do
      let(:options_value) { {} }
      let(:default_classes_value) { [] }

      it "returns only the base field_class" do
        expect(manager.field_css_classes).to eq("base-class")
      end
    end

    context "when all sources are empty or nil" do
      let(:field_class_value) { "" }
      let(:options_value) { {} }
      let(:default_classes_value) { [] }

      it "returns an empty string" do
        expect(manager.field_css_classes).to eq("")
      end
    end
  end
end
