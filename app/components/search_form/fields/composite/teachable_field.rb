module SearchForm
  module Fields
    # Renders a grouped multi-select field for filtering by teachables (Courses
    # and their associated Lectures). This component uses composition to build
    # a multi-select field with checkbox and radio button groups for inheritance options.
    class TeachableField < ViewComponent::Base
      attr_accessor :form_state

      def initialize(form_state:, with_inheritance_radios: false, **options)
        super()
        @form_state = form_state
        @with_inheritance_radios = with_inheritance_radios
        @options = options
      end

      delegate :form, to: :form_state

      def with_form(form)
        form_state.with_form(form)
        self
      end

      # A configuration method to enable the rendering of the "with/without
      # inheritance" radio button group.
      #
      # @return [self] Returns the component instance to allow for method chaining.
      def with_inheritance_radios
        @with_inheritance_radios = true
        self
      end

      def before_render
        setup_fields
      end

      private

        def setup_fields
          setup_multi_select_field
          setup_checkbox_group
          setup_radio_group if @with_inheritance_radios
        end

        def setup_multi_select_field
          @multi_select_field = Fields::MultiSelectField.new(
            name: :teachable_ids,
            label: I18n.t("basics.associated_to"),
            help_text: I18n.t("search.filters.helpdesks.teachable_filter"),
            collection: grouped_teachable_list,
            form_state: form_state
          ).with_form(form)
        end

        def setup_checkbox_group
          setup_checkboxes
          @checkbox_group_wrapper = Fields::Utilities::CheckboxGroupWrapper.new(
            parent_field: @multi_select_field,
            checkboxes: [@all_checkbox]
          )
        end

        def setup_checkboxes
          stimulus_config = {
            toggle: true
          }

          # Add radio group toggle if inheritance radios are enabled
          if @with_inheritance_radios
            stimulus_config[:toggle_radio_group] = "teachable_inheritance"
            stimulus_config[:default_radio_value] = "1" # "with_inheritance" by default
          end

          @all_checkbox = Fields::CheckboxField.new(
            name: generate_all_toggle_name(:teachable_ids),
            label: I18n.t("basics.all"),
            checked: true,
            form_state: form_state,
            container_class: "form-check mb-2",
            stimulus: stimulus_config
          ).with_form(form)
        end

        def setup_radio_group
          setup_radio_buttons
          @radio_group_wrapper = Fields::Utilities::RadioGroupWrapper.new(
            name: :teachable_inheritance,
            parent_field: @multi_select_field,
            radio_buttons: [@with_inheritance_radio, @without_inheritance_radio]
          )
        end

        def setup_radio_buttons
          @with_inheritance_radio = Fields::RadioButtonField.new(
            name: :teachable_inheritance,
            value: "1",
            label: I18n.t("basics.with_inheritance"),
            checked: true,
            form_state: form_state,
            disabled: true,
            inline: true,
            container_class: "form-check form-check-inline",
            stimulus: { radio_toggle: true, controls_select: false }
          ).with_form(form)

          @without_inheritance_radio = Fields::RadioButtonField.new(
            name: :teachable_inheritance,
            value: "0",
            label: I18n.t("basics.without_inheritance"),
            checked: false,
            form_state: form_state,
            disabled: true,
            inline: true,
            container_class: "form-check form-check-inline",
            stimulus: { radio_toggle: true, controls_select: false }
          ).with_form(form)
        end

        def generate_all_toggle_name(name)
          base_name = name.to_s.delete_suffix("_ids").pluralize
          :"all_#{base_name}"
        end

        # This private method is responsible for building the grouped collection.
        # It queries for all courses and their lectures, formatting them into
        # grouped options, and sorting them alphabetically.
        def grouped_teachable_list
          course_label = I18n.t("basics.course")

          # Single query with proper eager loading
          courses_with_lectures = Course.includes(lectures: :term)
                                        .order(:title)

          courses_with_lectures.map do |course|
            lectures = [["#{course.short_title} #{course_label}", "Course-#{course.id}"]]

            course.lectures.natural_sort_by(&:short_title).each do |lecture|
              lectures << [lecture.short_title, "Lecture-#{lecture.id}"]
            end

            [course.title, lectures]
          end
        end
    end
  end
end
