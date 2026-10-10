# Configures the support's search for users. Returns no configuration until a
# fulltext of two characters or a program is given, so the support looks up
# particular people.
module Search
  module Configurators
    class UserSearchConfigurator < BaseSearchConfigurator
      def call
        return if search_params[:fulltext].blank? && program_ids.blank?
        return if search_params[:fulltext].to_s.strip.length == 1

        Configuration.new(filters: [Filters::ProgramFilter, Filters::UserFulltextFilter],
                          params: search_params, sorter_class: Sorters::UserSearchSorter)
      end

      private

        def program_ids
          return [] if search_params[:all_programs] == "1"

          Array(search_params[:program_ids]).compact_blank
        end
    end
  end
end
