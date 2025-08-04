# Filters a scope of media by associated tags, supporting both "AND" and "OR" logic.
#
# This filter is skipped if the 'all_tags' parameter is set to '1' or if
# no specific tag IDs are provided.
#
# It supports two modes based on the `tag_operator` parameter:
# - 'and': Filters for records that are associated with *all* of the
#   specified tags.
# - 'or' (default): Filters for records that are associated with *any* of the
#   specified tags.
module Filters
  class TagFilter < BaseFilter
    def call
      return scope if skip_filter?(all_param: :all_tags, ids_param: :tag_ids)

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
