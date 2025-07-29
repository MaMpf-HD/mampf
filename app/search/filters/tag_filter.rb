module Filters
  class TagFilter < BaseFilter
    def call
      return scope if params[:all_tags] == "1" || params[:tag_ids].blank?

      tag_ids = params[:tag_ids].map(&:to_i)

      if params[:tag_operator] == "and"
        # Find the IDs of media within the current scope that have
        # all the specified tags.
        matching_media_ids = scope.joins(:tags)
                                  .where(tags: { id: tag_ids })
                                  .group("media.id")
                                  .having("COUNT(DISTINCT tags.id) = ?", tag_ids.count)
                                  .pluck(:id)

        # Return a new, non-grouped scope containing only the media that matched.
        scope.where(id: matching_media_ids)
      else
        # Standard OR search
        scope.joins(:tags).where(tags: { id: tag_ids }).distinct
      end
    end
  end
end
