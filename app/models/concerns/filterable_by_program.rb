module FilterableByProgram
  extend ActiveSupport::Concern

  included do
    # This scope is required by the filter logic.
    # Any model including this concern must have a :divisions association.
    scope :by_programs, lambda { |program_ids|
      return all if program_ids.blank?

      joins(:divisions).where(divisions: { program_id: program_ids }).distinct
    }
  end

  class_methods do
    private

      # This is the actual filter implementation.
      def apply_program_filter(scope, params)
        return scope if params[:all_programs] == "1"

        scope.by_programs(params[:program_ids])
      end
  end
end
