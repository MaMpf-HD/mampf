# This filter adds a lecture's imported media to the current search scope
module Search
  module Filters
    class ImportedMediaFilter < BaseFilter
      def call
        lecture_id = params[:lecture_id]
        project = params[:project]

        return scope unless lecture_id && project.present?

        lecture = Lecture.find_by(id: lecture_id)
        return scope unless lecture

        # Get the scope of imported media for the given project.
        imported_media_scope = lecture.imported_media
                                      .where(sort: project.camelize)
                                      .locally_visible

        # Combine the IDs from the current scope and the imported media.
        current_scope_ids = scope.pluck(:id)
        imported_media_ids = imported_media_scope.pluck(:id)
        all_ids = (current_scope_ids + imported_media_ids).uniq

        # Return a new scope based on the combined IDs. This loses any previous
        # ordering, but the final ordering is applied later by LectureMediaOrderer.
        Medium.where(id: all_ids)
      end
    end
  end
end
