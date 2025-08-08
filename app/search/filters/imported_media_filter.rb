# This filter adds a lecture's imported media to the current search scope
module Search
  module Filters
    class ImportedMediaFilter < BaseFilter
      def call
        project = params[:project]
        lecture_id = params[:lecture_id]

        lecture = Lecture.find_by(id: lecture_id)
        return scope unless lecture && project.present?

        # Pluck the IDs from the imported media scope to resolve the
        # structurally incompatible join from the has_many :through association.
        imported_media_ids = lecture.imported_media
                                    .where(sort: project.camelize)
                                    .pluck(:id)

        # If there are no imported media to add, return the original scope.
        return scope if imported_media_ids.empty?

        # Build a new, compatible scope from the IDs. This scope has no joins
        # and can be safely combined with the original scope.
        compatible_imported_scope = Medium.where(id: imported_media_ids)

        # Combine the original scope with the compatible imported media scope.
        scope.or(compatible_imported_scope)
      end
    end
  end
end
