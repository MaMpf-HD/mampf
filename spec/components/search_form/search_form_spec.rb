require "rails_helper"

RSpec.describe(SearchForm::SearchForm, type: :component) do
  let(:url) { "/search" }

  describe "#initialize" do
    context "when no context is provided" do
      subject(:search_form) { described_class.new(url: url) }

      # Stub SecureRandom to test the fallback mechanism
      before do
        allow(SecureRandom).to receive(:hex).with(4).and_return("random_hex")
      end

      it "generates a random context" do
        expect(search_form.context).to eq("random_hex")
      end

      it "initializes FormState with the generated context" do
        # We need to control the instantiation to check the arguments
        expect(SearchForm::Services::FormState).to receive(:new).with(context: "random_hex")
        described_class.new(url: url)
      end

      it "sets other default values correctly" do
        expect(search_form.url).to eq("/search")
        expect(search_form.scope).to eq(:search)
        expect(search_form.method).to eq(:get)
        expect(search_form.remote).to be(true)
        expect(search_form.hidden_fields).to eq({})
      end

      it "sets the default container class" do
        expect(search_form.container_class).to eq("row mb-3 p-2")
      end
    end

    context "when a context is provided" do
      let(:custom_options) do
        {
          url: url,
          scope: :media_search,
          method: :post,
          remote: false,
          context: "media",
          container_class: "custom-class"
        }
      end
      subject(:custom_search_form) { described_class.new(**custom_options) }

      it "uses the provided context" do
        expect(custom_search_form.context).to eq("media")
      end

      it "initializes FormState with the provided context" do
        expect(SearchForm::Services::FormState).to receive(:new).with(context: "media")
        described_class.new(**custom_options)
      end

      it "sets other custom values correctly" do
        expect(custom_search_form.url).to eq(url)
        expect(custom_search_form.scope).to eq(:media_search)
        expect(custom_search_form.method).to eq(:post)
        expect(custom_search_form.remote).to be(false)
      end

      it "sets the custom container class" do
        expect(custom_search_form.container_class).to eq("custom-class")
      end
    end
  end

  # All other tests remain the same
  describe "#add_hidden_field" do
    subject(:search_form) { described_class.new(url: url, context: "test") }
    it "adds a hidden field to the hash" do
      search_form.add_hidden_field(name: :user_id, value: "123")
      expect(search_form.hidden_fields).to eq({ user_id: "123" })
    end
  end

  describe "#add_submit_field" do
    subject(:search_form) { described_class.new(url: url, context: "test") }
    it "creates and adds a submit field" do
      expect(SearchForm::Fields::SubmitField).to receive(:new)
      expect(search_form).to receive(:with_field)
      search_form.add_submit_field
    end
  end

  describe "#filter_registry" do
    subject(:search_form) { described_class.new(url: url, context: "test") }
    it "returns and memoizes a FilterRegistry instance" do
      expect(search_form.filter_registry).to be_a(SearchForm::Services::FilterRegistry)
      expect(search_form.filter_registry).to be(search_form.filter_registry)
    end
  end

  describe "component rendering" do
    subject(:search_form) { described_class.new(url: url, context: "test") }
    it "renders a form with correct default attributes" do
      rendered = render_inline(search_form)
      expect(rendered.to_html).to include('role="search"')
      expect(rendered.to_html).to include('action="/search"')
    end

    it "renders hidden fields when added" do
      search_form.add_hidden_field(name: :user_id, value: "123")
      rendered = render_inline(search_form)
      user_id_field = rendered.css('input[name="search[user_id]"]').first
      expect(user_id_field["value"]).to eq("123")
    end
  end

  describe "field injection via renders_many" do
    subject(:search_form) { described_class.new(url: url, context: "test") }
    let(:mock_field) { instance_double(SearchForm::Fields::Field, "MockField") }
    let(:form_state_instance) { search_form.instance_variable_get(:@form_state) }

    before do
      allow(mock_field).to receive(:with_content)
      allow(mock_field).to receive(:respond_to?).and_return(false)
      allow(mock_field).to receive(:respond_to?).with(:with_content).and_return(true)
    end

    context "when a field supports form_state injection" do
      before do
        allow(mock_field).to receive(:respond_to?).with(:form_state=).and_return(true)
        allow(mock_field).to receive(:respond_to?).with(:form_state).and_return(true)
      end

      it "injects the form_state if it is nil" do
        allow(mock_field).to receive(:form_state).and_return(nil)
        expect(mock_field).to receive(:form_state=).with(form_state_instance)

        # Calling with_field triggers the renders_many lambda
        search_form.with_field(mock_field)
      end

      it "does NOT inject the form_state if it is already set" do
        allow(mock_field).to receive(:form_state).and_return("already_set")
        expect(mock_field).not_to receive(:form_state=)

        search_form.with_field(mock_field)
      end
    end

    context "when a field does not support form_state injection" do
      before do
        allow(mock_field).to receive(:respond_to?).with(:form_state=).and_return(false)
      end

      it "does not attempt to inject the form_state" do
        expect(mock_field).not_to receive(:form_state=)

        search_form.with_field(mock_field)
      end
    end
  end
end
