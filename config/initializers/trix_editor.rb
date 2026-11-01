# `f.trix_editor` binds a Trix editor to a plain text column: a hidden input
# carries the value and the <trix-editor> element edits it. It lives here and
# not in the trix-rails gem because that gem's `Trix` module collides with
# action_text-trix, which Rails depends on. Rich-text attributes use Action
# Text's `rich_textarea` instead.
module ActionView
  module Helpers
    module Tags
      # Renders the hidden input and the editor element that points at it.
      class TrixEditor < Base
        def render
          options = @options.stringify_keys
          add_default_name_and_id(options)
          input = options.delete("input") ||
                  @template_object.dom_id(object, [options["id"], :trix_input].compact.join("_"))
          value = options.delete("value") { value_before_type_cast }
          name = options.delete("name")
          css_class = ["formatted_content", "trix-content",
                       *Array.wrap(options.delete("class"))].join(" ")
          attributes = { "class" => css_class, "input" => input }.merge(options)

          @template_object.hidden_field_tag(name, value, id: input) +
            @template_object.content_tag("trix-editor", "", attributes)
        end
      end
    end

    class FormBuilder
      def trix_editor(method, options = {})
        Tags::TrixEditor.new(@object_name, method, @template, objectify_options(options)).render
      end
    end
  end
end
