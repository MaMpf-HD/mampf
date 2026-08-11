module Registration
  module RosterStreamRefreshable
    private

      def refresh_roster_streams(lecture)
        return [] unless lecture

        group_type = view_context.roster_group_types(lecture)
        frame_id = view_context.roster_maintenance_frame_id(group_type)

        [
          turbo_stream.replace(
            frame_id,
            view_context.turbo_frame_tag(
              frame_id,
              src: view_context.lecture_roster_path(
                lecture, group_type: group_type
              ),
              loading: "lazy"
            )
          ),
          turbo_stream.replace(
            "roster_participants_panel",
            view_context.turbo_frame_tag(
              "roster_participants_panel",
              src: view_context.lecture_roster_participants_path(lecture),
              loading: "lazy"
            )
          )
        ]
      end
  end
end
