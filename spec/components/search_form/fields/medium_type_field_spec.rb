require "rails_helper"

RSpec.describe(SearchForm::Fields::MediumTypeField, type: :component) do
  let(:form_state_double) { instance_double(SearchForm::Services::FormState) }
  # Use instance_doubles instead of factories to isolate the component test.
  # We only care about the result of `admin_or_editor?`.
  let(:user) { instance_double(User, admin_or_editor?: false) }
  let(:editor) { instance_double(User, admin_or_editor?: true) }
  let(:minimal_args) { { form_state: form_state_double, current_user: user } }

  subject(:field) { described_class.new(**minimal_args) }

  describe "#initialize" do
    it "assigns form_state, current_user, and default purpose" do
      expect(field.instance_variable_get(:@form_state)).to eq(form_state_double)
      expect(field.current_user).to eq(user)
      expect(field.purpose).to eq("media")
    end

    it "stores a custom purpose and additional options" do
      instance = described_class.new(**minimal_args, purpose: "quiz", required: true)
      expect(instance.purpose).to eq("quiz")
      expect(instance.options).to eq({ required: true })
    end
  end

  describe "field creation" do
    let(:multi_select_double) { instance_double(SearchForm::Fields::Primitives::MultiSelectField) }
    let(:checkbox_double) { instance_double(SearchForm::Fields::Primitives::CheckboxField) }

    before do
      allow(form_state_double).to receive(:form)
      allow(form_state_double).to receive(:with_form)
      allow(field).to receive(:create_multi_select_field).and_return(multi_select_double)
      allow(field).to receive(:create_all_checkbox).and_return(checkbox_double)
      allow(SearchForm::Fields::Utilities::CheckboxGroupWrapper).to receive(:new)

      # Stub all potential collection sources
      allow(Medium).to receive(:select_generic).and_return([["Generic", "generic"]])
      allow(Medium).to receive(:select_sorts).and_return([["All Sorts", "all_sorts"]])
      allow(Medium).to receive(:select_importables).and_return([["Importable", "importable"]])
      allow(Medium).to receive(:select_quizzables).and_return([["Quizzable", "quizzable"]])
    end

    context "with purpose 'media'" do
      context "for a regular user" do
        it "creates a disabled multi-select with generic sorts and an 'All' checkbox" do
          expect(field).to receive(:create_multi_select_field)
            .with(hash_including(collection: [["Generic", "generic"]], multiple: true,
                                 disabled: true))
          expect(field).to receive(:setup_checkbox_group)

          field.before_render
        end
      end

      context "for an editor" do
        subject(:editor_field) do
          described_class.new(form_state: form_state_double, current_user: editor)
        end
        before do
          allow(editor_field).to receive(:create_multi_select_field).and_return(multi_select_double)
          allow(editor_field).to receive(:create_all_checkbox).and_return(checkbox_double)
          allow(editor_field).to receive(:setup_checkbox_group)
        end

        it "creates a multi-select with all sorts" do
          expect(editor_field).to receive(:create_multi_select_field)
            .with(hash_including(collection: [["All Sorts", "all_sorts"]]))

          editor_field.before_render
        end
      end
    end

    context "with purpose 'import'" do
      subject(:import_field) { described_class.new(**minimal_args, purpose: "import") }
      before do
        allow(import_field).to receive(:create_multi_select_field).and_return(multi_select_double)
      end

      it "creates an enabled multi-select with importable sorts and no 'All' checkbox" do
        expect(import_field).to receive(:create_multi_select_field)
          .with(hash_including(collection: [["Importable", "importable"]], multiple: true,
                               disabled: false))
        expect(import_field).not_to receive(:setup_checkbox_group)

        import_field.before_render
      end
    end

    context "with purpose 'quiz'" do
      subject(:quiz_field) { described_class.new(**minimal_args, purpose: "quiz") }
      before do
        allow(quiz_field).to receive(:create_multi_select_field).and_return(multi_select_double)
      end

      it "creates a single-select for quizzables and pre-selects 'Question'" do
        expect(quiz_field).to receive(:create_multi_select_field)
          .with(hash_including(
                  collection: [["Quizzable", "quizzable"]],
                  selected: "Question",
                  multiple: false,
                  disabled: false,
                  input_name: "search[types][]"
                ))
        expect(quiz_field).not_to receive(:setup_checkbox_group)

        quiz_field.before_render
      end
    end
  end
end
