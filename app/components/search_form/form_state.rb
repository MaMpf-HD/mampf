# app/components/search_form/form_state.rb
module SearchForm
  class FormState
    attr_reader :form, :context, :scope_prefix

    def initialize(form:, context:)
      @form = form
      @context = context
      @scope_prefix = form&.object_name || "search"
    end

    def with_form(form)
      @form = form
      @scope_prefix = form&.object_name || "search"
      self
    end

    # Generate the base ID string that gets used for both element_id and label_for
    def base_id_for(*parts)
      ([context] + parts.map(&:to_s).reject(&:empty?)).join("_")
    end

    # Generate the full element ID (includes form scope)
    def element_id_for(*parts)
      [scope_prefix, base_id_for(*parts)].compact.join("_")
    end

    # Generate the label_for value (just the base, Rails adds scope automatically)
    def label_for(*parts)
      base_id_for(*parts)
    end
  end
end
