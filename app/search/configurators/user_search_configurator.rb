# Configures the support's search for people. Nobody is listed until a name,
# address or number is typed or a program is picked: the support looks for
# someone in particular, not through everyone.
module Search
  module Configurators
    class UserSearchConfigurator < BaseSearchConfigurator
      def call
        return if search_params[:fulltext].blank? && program_ids.blank?

        Configuration.new(filters: [Filters::ProgramFilter, Filters::FulltextFilter],
                          params: search_params)
      end

      private

        def program_ids
          return [] if search_params[:all_programs] == "1"

          Array(search_params[:program_ids]).compact_blank
        end
    end
  end
end
