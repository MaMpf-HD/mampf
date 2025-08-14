# Adds a lecture's imported media to the current search scope
module Search
  module Filters
    class ImportedMediaFilter < BaseFilter
      def call
        lecture_id = params[:id]
        project = params[:project]

        return scope unless lecture_id.present? && project.present?

        imported_media_ids_subquery = Import.where(teachable_id: lecture_id,
                                                   teachable_type: "Lecture")
                                            .joins(:medium)
                                            .where(media: { sort: project.camelize })
                                            .select(:medium_id)

        # Combine the original scope with the imported media scope using OR.
        # Using a subquery for the `id` list is robust and avoids potential
        # issues with complex joins from the has_many :through association.
        scope.or(Medium.where(id: imported_media_ids_subquery))
      end
    end
  end
end
