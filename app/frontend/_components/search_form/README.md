# SearchForm Component System

A ViewComponent-based system for building search interfaces with automatic form state management and field composition.

## Architecture Overview

The system is built around composition using three main layers:

- **SearchForm**: Main component with declarative API via `add_*_field` methods
- **FieldRegistry**: Generates field methods dynamically from a centralized list
- **FormState**: Manages form builder injection and unique ID generation

## Field Structure

```sh
fields/
├── primitives/         # Basic HTML inputs
├── mixins/             # Shared functionality  
├── services/           # CSS and HTML building
├── utilities/          # Field grouping wrappers
└── *.rb                # Composite field components
```

**Primitives**: `TextField`, `SelectField`, `MultiSelectField`, `CheckboxField`, `RadioButtonField`, `SubmitField`

**Composite Fields**: `CourseField`, `TagField`, `TeacherField`, `MediumTypeField`, etc.

## Usage

```erb
<%= render(SearchForm::SearchForm.new(url: search_path)) do |c| %>
  <% c.add_fulltext_field %>
  <% c.add_course_field %>
  <% c.add_tag_field %>
<% end %>
```

## Available Field Methods

The `FieldRegistry` automatically generates `add_*_field` methods for all registered field types. Each method follows the pattern:

```ruby
form.add_{field_name}_field(**options)
```

**Examples:**
- `add_fulltext_field` - Text input for search queries
- `add_course_field` - Course multi-select with "All" toggle
- `add_tag_field` - Tag selection with OR/AND operators
- `add_medium_type_field(current_user: user, purpose: "media")` - Context-aware selection

For the complete list of available fields, see `FieldRegistry::FIELDS` in the codebase.

## Creating Fields

### Simple Composite Fields

```ruby
class MyField < ViewComponent::Base
  include Mixins::CompositeFieldMixin

  def initialize(form_state:, **options)
    super()
    @form_state = form_state
    @options = options
  end

  private

    def setup_fields
      @select_field = create_select_field(
        name: :my_filter,
        label: "My Filter",
        collection: MyModel.pluck(:name, :id)
      )
    end
end
```

### Multi-Select with Toggle

```ruby
class MyMultiField < ViewComponent::Base
  include Mixins::CompositeFieldMixin

  def initialize(form_state:, **options)
    super()
    @form_state = form_state
    @options = options
  end

  private

    def setup_fields
      @multi_select_field = create_multi_select_field(
        name: :item_ids,
        label: "Items", 
        collection: Item.pluck(:name, :id)
      )

      @all_checkbox = create_all_checkbox(for_field_name: :item_ids)

      @checkbox_group_wrapper = Fields::Utilities::CheckboxGroupWrapper.new(
        parent_field: @multi_select_field,
        checkboxes: [@all_checkbox]
      )
    end
end
```

## Available Factory Methods

The `CompositeFieldMixin` provides these field creation helpers:

- `create_text_field(name:, label:, **options)`
- `create_select_field(name:, label:, collection:, **options)`  
- `create_multi_select_field(name:, label:, collection:, **options)`
- `create_checkbox_field(name:, label:, **options)`
- `create_radio_button_field(name:, value:, label:, **options)`
- `create_all_checkbox(for_field_name:, **options)`

See `CompositeFieldMixin` for detailed documentation and examples for each method.

## Field Registration

Add new fields to `FieldRegistry::FIELDS`:

```ruby
FIELDS = [
  :answer_count, :course, :editor, # existing fields
  :my_custom_field                 # new field
].freeze
```

This automatically creates `add_my_custom_field(**options)` method.

## Form Configuration

```ruby
SearchForm.new(
  url: search_path,
  scope: :search,      # parameter namespace
  method: :get,        # HTTP method  
  remote: true,        # AJAX submission
  context: "media"     # unique context for IDs
)
```

## Field Options

Common options for all fields:

- `help_text` - Help text displayed below field
- `container_class` - CSS classes for wrapper div
- `disabled` - Whether field is disabled
- `data` - Hash of data attributes

Select-specific options:
- `collection` - Array of [text, value] pairs
- `selected` - Pre-selected value(s)
- `prompt` - Prompt text or boolean

## Stimulus Integration

Fields can include Stimulus data attributes:

```ruby
create_multi_select_field(
  name: :tags,
  data: { ajax: true, model: "tag" }
)

create_all_checkbox(
  for_field_name: :tags,
  stimulus: { 
    toggle: true,
    toggle_radio_group: "tag_operator",
    default_radio_value: "or"
  }
)
```

## Templates

Each field has a corresponding `.html.erb` template that renders its components. Composite fields typically render multiple primitives, while primitive fields render a single input element.

The system automatically handles form builder injection, ID generation, and accessibility attributes.