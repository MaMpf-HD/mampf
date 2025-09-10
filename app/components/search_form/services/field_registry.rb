module SearchForm
  module Services
    class FieldRegistry
      FIELDS = [
        :answer_count, :course, :editor, :fulltext, :lecture_scope, :lecture_type,
        :medium_access, :medium_type, :per_page, :program, :tag, :teachable,
        :teacher, :term, :term_independence
      ].freeze

      def initialize(search_form)
        @search_form = search_form
      end

      def self.generate_methods_for(klass)
        FIELDS.each do |field_name|
          klass.define_method("add_#{field_name}_field") do |**options|
            field_class = "SearchForm::Fields::#{field_name.to_s.camelize}Field".constantize
            field = field_class.new(form_state: @form_state, **options)
            with_field(field)
            field
          end
        end
      end
    end
  end
end
