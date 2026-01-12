module Rosters
  class StreamService
    def initialize(lecture, view_context)
      @lecture = lecture
      @view_context = view_context
    end

    # Call this when the structure of the roster changes
    # (e.g. created group, deleted group, changed propagate_to_lecture)
    def roster_changed(group_type: :all, flash: nil)
      streams = []

      # 1. Refresh the Roster List (lazy load for performance)
      streams << refresh_roster_frame(group_type)

      # 2. Flash
      streams << render_flash(flash) if flash

      streams.compact
    end

    # Call this when a single item's attributes change, but it stays in the same bucket
    # (e.g. renamed tutorial, changed capacity)
    # If structural update is needed, falls back to roster_changed
    def item_updated(item, group_type: :all, flash: nil)
      # If the change affects grouping (e.g. propagation), we must refresh the list
      return roster_changed(group_type: group_type, flash: flash) if structural_change?(item)

      # Otherwise, just replace the card in place
      streams = []
      streams << @view_context.turbo_stream.replace(
        dom_id(item),
        partial: "roster/components/groups_tab/item_tile",
        locals: {
          item: item,
          component: component_for_item,
          group: group_params_for(item),
          group_type: group_type
        }
      )
      streams << render_flash(flash) if flash
      streams.compact
    end

    private

      def refresh_roster_frame(group_type)
        frame_id = "roster_groups"

        @view_context.turbo_stream.replace(
          frame_id,
          @view_context
          .turbo_frame_tag(frame_id,
                           src: @view_context.lecture_roster_path(@lecture,
                                                                  group_type: group_type),
                           loading: "lazy")
        )
      end

      # Mimics the behavior of Flash#include logic in partials, but adapted for service use.
      # Generally we prepend to #flash-messages.
      def render_flash(_flash)
        @view_context.turbo_stream.prepend("flash-messages", partial: "flash/message")
      end

      def dom_id(record)
        ActionView::RecordIdentifier.dom_id(record)
      end

      def structural_change?(item)
        item.is_a?(Cohort) && item.saved_change_to_propagate_to_lecture?
      end

      def component_for_item
        RosterOverviewComponent.new(lecture: @lecture)
      end

      def group_params_for(item)
        # Mocking the group hash expected by the partial for styling (e.g. .cohort class)
        { type: item.class.name.tableize.to_sym }
      end
  end
end
