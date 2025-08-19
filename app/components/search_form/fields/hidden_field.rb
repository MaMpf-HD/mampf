# Hidden fields provide a way to include non-visible form parameters that are
# needed for the search but shouldn't appear in the UI. This component inherits
# directly from ViewComponent::Base rather than Field because it doesn't need
# UI-related features (labels, column classes, help text) and follows a different
# rendering pattern - being rendered directly in the form rather than in the
# field grid.
module SearchForm
  module Fields
    class HiddenField < ViewComponent::Base
      attr_reader :name, :value

      def initialize(name:, value:)
        super()
        @name = name
        @value = value
      end
    end
  end
end
