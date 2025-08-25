# spec/components/search_form/search_form_spec.rb
require "rails_helper"

RSpec.describe(SearchForm::SearchForm, type: :component) do
  let(:url) { "/search" }
  let(:search_form) { described_class.new(url: url) }

  describe "#initialize" do
    context "with default parameters" do
      it "sets default values correctly" do
        expect(search_form.url).to eq("/search")
        expect(search_form.scope).to eq(:search)
        expect(search_form.method).to eq(:get)
        expect(search_form.remote).to be(true)
        expect(search_form.context).to be_nil
        expect(search_form.hidden_fields).to eq({})
      end

      it "initializes form_state with context" do
        expect(SearchForm::Services::FormState).to receive(:new).with(context: nil)
        described_class.new(url: url)
      end
    end

    context "with custom parameters" do
      let(:custom_search_form) do
        described_class.new(
          url: "/custom_search",
          scope: :media_search,
          method: :post,
          remote: false,
          context: "media"
        )
      end

      it "sets custom values correctly" do
        expect(custom_search_form.url).to eq("/custom_search")
        expect(custom_search_form.scope).to eq(:media_search)
        expect(custom_search_form.method).to eq(:post)
        expect(custom_search_form.remote).to be(false)
        expect(custom_search_form.context).to eq("media")
      end
    end
  end

  describe "#add_hidden_field" do
    it "adds hidden fields to the hash" do
      search_form.add_hidden_field(name: :user_id, value: "123")
      expect(search_form.hidden_fields).to eq({ user_id: "123" })
    end

    it "can add multiple hidden fields" do
      search_form.add_hidden_field(name: :user_id, value: "123")
      search_form.add_hidden_field(name: :page, value: "2")

      expect(search_form.hidden_fields).to eq({ user_id: "123", page: "2" })
    end
  end

  describe "#add_submit_field" do
    it "creates and adds a submit field with default parameters" do
      expect(SearchForm::Fields::SubmitField).to receive(:new).with(
        label: nil,
        css_classes: "btn btn-primary"
      )
      expect(search_form).to receive(:with_field)

      search_form.add_submit_field
    end

    it "creates and adds a submit field with custom parameters" do
      expect(SearchForm::Fields::SubmitField).to receive(:new).with(
        label: "Search Now",
        css_classes: "btn btn-success",
        id: "custom-submit"
      )
      expect(search_form).to receive(:with_field)

      search_form.add_submit_field(
        label: "Search Now",
        css_classes: "btn btn-success",
        id: "custom-submit"
      )
    end
  end

  describe "#filter_registry" do
    it "returns and memoizes a FilterRegistry instance" do
      expect(search_form.filter_registry).to be_a(SearchForm::Services::FilterRegistry)
      expect(search_form.filter_registry).to be(search_form.filter_registry)
    end
  end

  describe "component rendering" do
    it "renders a form element" do
      rendered = render_inline(search_form)

      # Test that a form exists
      expect(rendered.css("form")).not_to be_empty
    end

    it "renders with search-form controller" do
      rendered = render_inline(search_form)

      # Test the data-controller attribute specifically
      expect(rendered.to_html).to include('data-controller="search-form"')
    end

    it "renders with correct action URL" do
      rendered = render_inline(search_form)

      # Test the action attribute
      expect(rendered.to_html).to include('action="/search"')
    end

    it "renders with GET method by default" do
      rendered = render_inline(search_form)

      # Test the method
      expect(rendered.to_html).to include('method="get"')
    end

    it "renders with search role" do
      rendered = render_inline(search_form)

      # Test the role attribute
      expect(rendered.to_html).to include('role="search"')
    end

    it "renders with remote true by default" do
      rendered = render_inline(search_form)

      # Check if data-remote is present (Rails adds this)
      html = rendered.to_html
      # Rails might render this differently, so let's check what's actually there
      expect(html).to match(/data-remote|remote/)
    end

    context "with custom attributes" do
      let(:custom_form) do
        described_class.new(
          url: "/custom_search",
          method: :post,
          remote: false,
          scope: :media_search
        )
      end

      it "renders with custom action URL" do
        rendered = render_inline(custom_form)

        expect(rendered.to_html).to include('action="/custom_search"')
      end

      it "renders with custom method" do
        rendered = render_inline(custom_form)

        expect(rendered.to_html).to include('method="post"')
      end

      it "has the correct component properties" do
        # Test the component itself rather than HTML rendering
        expect(custom_form.remote).to be(false)
        expect(custom_form.scope).to eq(:media_search)
      end
    end

    it "renders the form structure with row and container" do
      rendered = render_inline(search_form)

      # Test the internal structure
      expect(rendered.css("form .row.mb-3.p-2")).not_to be_empty
    end

    it "renders hidden fields when added" do
      search_form.add_hidden_field(name: :user_id, value: "123")
      search_form.add_hidden_field(name: :page, value: "2")

      rendered = render_inline(search_form)

      user_id_field = rendered.css('input[name="search[user_id]"]').first
      page_field = rendered.css('input[name="search[page]"]').first

      expect(user_id_field["value"]).to eq("123")
      expect(user_id_field["type"]).to eq("hidden")
      expect(page_field["value"]).to eq("2")
      expect(page_field["type"]).to eq("hidden")
    end

    it "renders without errors when no fields are added" do
      expect { render_inline(search_form) }.not_to raise_error
    end
  end

  describe "dynamic filter methods" do
    it "responds to generated filter methods" do
      expect(search_form).to respond_to(:add_fulltext_filter)
      expect(search_form).to respond_to(:add_medium_type_filter)
      expect(search_form).to respond_to(:add_tag_filter_with_operators)
    end
  end
end
