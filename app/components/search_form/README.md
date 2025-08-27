# SearchForm Component System

This document provides a guide to using and customizing the `SearchForm` component system.

## 1. Overview

The `SearchForm` is a component-based system for building complex, reusable search forms. It is designed to provide a consistent structure while allowing for deep customization at multiple levels.

The core architectural components are:
- **`SearchForm`:** The main component that wraps the entire form. It is responsible for the `<form>` tag and managing the collection of fields.
- **`Services::FormState`:** A state object that is automatically injected into every field, providing access to the form builder and a shared context.
- **`Services::FilterRegistry`:** A service that dynamically generates `add_*_filter` methods on the `SearchForm` component for each registered filter.
- **`Filters`:** Specialized components in `app/components/search_form/filters/` that define the behavior for a specific search criterion (e.g., `CourseFilter`, `FulltextFilter`).
- **`Fields`:** The base UI components in `app/components/search_form/fields/` that the filters inherit from (e.g., `TextField`, `MultiSelectField`). They control the final HTML rendering.
- **Automatic ID Generation:** The framework automatically generates unique `id` attributes for every form field. To ensure uniqueness across multiple forms on the same page, it uses a `context`. If you do not provide a `context` when initializing the `SearchForm`, a random one will be generated. For predictable and debuggable IDs, it is highly recommended to provide an explicit context (e.g., `SearchForm.new(context: "media", ...)`).
- **Accessible by Default:** Building on the unique IDs, the framework automatically associates every `<label>` with its corresponding `<input>` using the `for` attribute. This provides a baseline of accessibility for free, without requiring any extra developer effort.

## 2. Basic Usage

To render a search form, instantiate the `SearchForm` component in a view and pass it the `url`. Inside the block, call the dynamically generated `add_*_filter` methods on the yielded component instance (`c`).

```erb
<%# app/views/search/_lecture_search_form.html.erb %>

<%= render(SearchForm::SearchForm.new(url: lecture_search_path)) do |c| %>
  <%# Add a filter for lecture type %>
  <% c.add_lecture_type_filter %>

  <%# Add a filter for teachers %>
  <% c.add_teacher_filter %>

  <%# Add a submit button %>
  <% c.add_submit_field %>
<% end %>
```

You can also provide options to the `SearchForm` component itself, such as a `context` for predictable IDs or a `container_class` to customize the main container that wraps all the fields.

```erb
<%# Example with custom options for the form itself %>
<%= render(SearchForm::SearchForm.new(
      url: media_search_path,
      context: "media",
      container_class: "d-flex flex-wrap gap-3"
    )) do |c| %>
  <%# ... filters ... %>
<% end %>
```

## 3. Customizing Filters

There are three levels at which you can customize the behavior and appearance of filters, each with a different scope of impact.

### Level 1: Customizing a Single Filter Instance (in the View)

This is the most common type of customization. When you only want to change a filter in one specific form, you pass options directly to its `add_*_filter` method.

**Mechanism:** Pass keyword arguments to the `add_*_filter` method in your `.html.erb` partial.

**Scope:** Affects only the single instance of the filter where the options are passed.

#### Common Customizations

The following list shows a sample of common options that can be overridden. For a complete list of available options for a specific filter (e.g., `button_class` for `SubmitField`), please refer to the API documentation in the corresponding component class file.

-   `:label` (String): Overrides the default label text.
-   `:help_text` (String): Overrides or adds help text.
-   `:container_class` (String): Replaces the default CSS classes on the wrapping `div`.
-   `:selected` (Object): Sets the pre-selected value for a select field.

#### Passthrough HTML Attributes

As documented in `Fields::Field`, any keyword argument that is not a recognized layout option is automatically passed through as an HTML attribute to the underlying `<input>` or `<select>` element. This is useful for setting attributes like `:placeholder` or `data-*` attributes.

**Example:**
In a specific search form, we want the full-text search to span the entire width of the form and have a more descriptive label and placeholder.

```erb
<%# In a specific search form where we want a full-width text search %>
<% c.add_fulltext_filter(
     label: "Keyword Search",
     placeholder: "Search by title, description, or content...",
     container_class: "col-12 mb-3 form-field-group"
   ) %>
```

### Level 2: Modifying a Filter Type (in the Filter Class)

If you want to change the default behavior for *every* instance of a specific filter (e.g., you want *all* `FulltextFilter`s to have a different label), you should modify the filter's class file.

**Mechanism:** Edit the corresponding file in `app/components/search_form/filters/`.

**Scope:** Affects all instances of that specific filter across the entire application.

**Example:**
Let's change the default label for the `FulltextFilter` everywhere it is used.

```ruby
# filepath: app/components/search_form/filters/fulltext_filter.rb

class FulltextFilter < Fields::TextField
  def initialize(**)
    super(
      name: :fulltext,
      # Change the default label here
      label: I18n.t("basics.tag"),
      help_text: I18n.t("basics.fulltext"),
      **
    )
  end
end
```

### Level 3: Modifying a Base Field Type (in the Field Class)

This is the most powerful and wide-reaching level of customization. If you want to change a fundamental aspect of an entire category of fields (e.g., change the styling of *all* `TextField` components), you modify the base field class.

**Mechanism:** Edit the corresponding file in `app/components/search_form/fields/`.

**Scope:** Affects all filter components that inherit from that base field. For example, changing `TextField` will affect `FulltextFilter`, `TagTitleFilter`, and any other filter that inherits from it.

**Example:**
We want to add a custom CSS class to every single text field rendered by the search form system.

```ruby
# filepath: app/components/search_form/fields/text_field.rb

class TextField < Field
  # ...
  def default_field_classes
    # Add our custom class to the defaults
    ["form-control", "my-custom-text-field"]
  end
end
```
This change will now apply to every `add_fulltext_filter` and `add_tag_title_filter` call automatically.

## 4. Client-Side Interaction with Stimulus

Many of the advanced filters, particularly those inheriting from `MultiSelectField`, have dynamic client-side behavior. This is handled by the Stimulus controller in `app/frontend/js/controllers/search_form_controller.js`.

Understanding the contract between the Ruby components and this controller is essential for debugging or creating new filters with similar dynamic features.

### The DOM Traversal and Data Attribute Contract

The controller is designed to be robust and support multiple independent filters on the same page. It achieves this by using a two-part system to locate elements:

1.  **Scoping with DOM Traversal:** When an action is triggered (e.g., a checkbox is clicked), the controller first travels **up** the DOM tree to find the parent container with the class `.form-field-group`. This establishes the **scope**, ensuring that any subsequent actions are confined to the correct filter component.

2.  **Identifying with Data Attributes:** Once inside the correct scope, the controller travels **down** to find the element it needs to manipulate. It identifies the element by its **role**, which is defined by a `data-search-form-target` attribute (e.g., `[data-search-form-target="select"]`).

This two-step process ensures that actions are both precisely targeted and correctly scoped, preventing interference between different filter components on the same page.

### The "All" Checkbox Toggle

The most common pattern is the "All" checkbox that controls its associated `<select>` input.

-   **Default State:** The "All" checkbox is checked, and the `<select>` input is `disabled`.
-   **Interaction:** When the user unchecks the "All" box, the Stimulus controller enables the `<select>`, allowing for a specific selection.

This is achieved via the following `data` attributes on the checkbox, which are generated by the `DataAttributesBuilder` service:
-   `data-action="change->search-form#toggleFromCheckbox"`: Tells Stimulus to call the `toggleFromCheckbox` action on the `search-form` controller whenever the checkbox state changes.

### Toggling Radio Groups

Some filters, like `TeachableFilter` and `TagFilter`, extend this pattern to also show/hide and enable/disable an associated radio button group.

-   **Interaction:** When the "All" checkbox is checked, the radio group is hidden and its inputs are disabled. When it's unchecked, the radio group becomes visible and enabled.

This is achieved by overriding the `all_toggle_data_attributes` method in the filter class to add a second action and helper attributes:

-   `data-action="... change->search-form#toggleRadioGroup"`: Adds a call to the `toggleRadioGroup` action.
-   `data-toggle-radio-group="<name_of_radios>"`: Specifies the `name` attribute of the radio buttons to be toggled (e.g., `"teachable_inheritance"`).
-   `data-default-radio-value="<value>"`: Tells the controller which radio button to re-select when the group is re-enabled.

**Example from `TeachableFilter`:**
The `TeachableFilter` implements `all_toggle_data_attributes` to return this hash, creating the contract with the Stimulus controller:

```ruby
# app/components/search_form/filters/teachable_filter.rb
def all_toggle_data_attributes
  {
    search_form_target: "allToggle",
    action: "change->search-form#toggleFromCheckbox change->search-form#toggleRadioGroup",
    toggle_radio_group: "teachable_inheritance",
    default_radio_value: "1"
  }
end
```

### Other Custom Actions

The controller also supports other specific actions, such as `fillCourses` (used by the "Edited Courses" button in `CourseFilter`), which demonstrates how more complex, one-off interactions can be built using the same Stimulus patterns.

## 5. Creating a New Filter

To extend the search form with a new filter, follow these three steps.

### Step 1: Create the Filter Class

First, create a new class in `app/components/search_form/filters/`. This class should inherit from one of the base `Field` types (`TextField`, `SelectField`, `MultiSelectField`, etc.) depending on the kind of input you need.

In the `initialize` method, call `super` with the hard-coded options for your filter, such as its `:name` and `:label`. It's crucial to accept and pass `**options` to `super` to ensure that your new filter supports the runtime customizations described in Section 3.

**Example:** Let's create a simple text filter for searching by an teacher's name.

```ruby
# app/components/search_form/filters/author_filter.rb
module SearchForm
  module Filters
    class AuthorFilter < Fields::TextField
      def initialize(**options)
        super(
          name: :teacher_name,
          label: I18n.t("basics.teacher"),
          **options
        )
      end
    end
  end
end
```

### Step 2: Register the Filter

The system will not recognize your new filter until it is registered. Open the `FilterRegistry` service and add your new filter to the `FILTERS` hash.

The key should be the symbol you want to use for the method name (e.g., `:author`), and the value should be the class constant of the filter you just created.

```ruby
# app/components/search_form/services/filter_registry.rb
# ...
class FilterRegistry
  FILTERS = {
    # ... existing filters
    answer_count: Filters::AnswerCountFilter,
    author: Filters::AuthorFilter, # Add your new filter here
    course: Filters::CourseFilter,
    # ...
  }.freeze
  # ...
end
```

### Step 3: Use the New Filter in a View

Once registered, the `FilterRegistry` will automatically generate a corresponding `add_*_filter` method on the `SearchForm` component. You can now use it in any search form partial.

```erb
<%# In a search form partial %>
<%= render(SearchForm::SearchForm.new(url: some_search_path)) do |c| %>
  <%# ... other filters ... %>

  <%# Use the newly created filter %>
  <% c.add_author_filter(placeholder: "e.g., 'J.R.R. Tolkien'") %>

  <% c.add_submit_field %>
<% end %>
```

For more complex filters that require client-side interactions, you may also need to override methods like `all_toggle_data_attributes` to define a contract with the Stimulus controller, as described in Section 4.