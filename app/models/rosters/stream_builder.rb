module Rosters
  # Builds the appropriate Turbo Stream responses for various roster maintenance actions,
  # such as adding/removing users, moving users between groups, and updating the roster overview.
  # Centralizes the logic for determining which parts of the UI need to be updated in
  # response to different actions taken in the roster maintenance interface.
  class StreamBuilder
    GROUP_TYPE_KEYS = [:tutorials, :talks, :cohorts].freeze

    # rubocop:disable Metrics/ParameterLists
    def initialize(view_context:, turbo_stream:, lecture:, rosterable:, mparams:,
                   participants_state: {}, target: nil, roster_tab: nil,
                   refresh_campaigns_stream: nil)
      @view_context = view_context
      @turbo_stream = turbo_stream
      @lecture = lecture
      @rosterable = rosterable
      @mparams = mparams
      @participants_state = participants_state
      @target = target
      @roster_tab = roster_tab
      @refresh_campaigns_stream = refresh_campaigns_stream
    end
    # rubocop:enable Metrics/ParameterLists

    def streams(variant: nil, update_tiles: true)
      return move_panel_streams if variant == :move_panel

      if @mparams.unassigned?
        unassigned_streams
      elsif @mparams.panel?
        panel_streams(update_tiles: update_tiles)
      elsif @mparams.participants?
        participants_streams
      else
        roster_streams
      end
    end

    private

      def participants_streams
        @rosterable.reload
        streams = roster_streams

        streams << @turbo_stream.update(
          "roster_participants_panel",
          RosterParticipantsComponent.new(
            lecture: @lecture,
            group_type: @mparams.group_type,
            participants: participants,
            pagy: pagy,
            filter_mode: filter_mode,
            search_string: search_string,
            counts: component_counts
          )
        )

        streams
      end

      def unassigned_streams
        campaign = Registration::Campaign.find_by(id: @mparams.source_id)
        @rosterable.reload

        streams = []
        tile_replacements_for(@rosterable, streams)

        if campaign
          unassigned_users = campaign.unassigned_users(
            preload_registrations: true
          )

          streams << @turbo_stream.replace(
            "dissolved_campaign_#{campaign.id}",
            partial: "registration/campaigns/dissolved_footnote",
            locals: { campaign: campaign }
          )

          streams << @turbo_stream.replace(
            "tutorial-roster-side-panel",
            html: RosterSidePanelComponent.new(
              campaign: campaign,
              students: unassigned_users,
              is_unassigned: true
            ).render_in(@view_context)
          )
        end

        streams.compact
      end

      def panel_streams(update_tiles: true)
        @rosterable.reload

        streams = []
        tile_replacements_for(@rosterable, streams) if update_tiles

        if @rosterable.is_a?(Tutorial) || @rosterable.is_a?(Cohort) || @rosterable.is_a?(Talk)
          streams << @turbo_stream.replace(
            "tutorial-roster-side-panel",
            html: RosterSidePanelComponent.new(
              registerable: @rosterable,
              students: @rosterable.members.order(:name),
              read_only: @rosterable.locked?
            ).render_in(@view_context)
          )
        end

        streams.compact
      end

      def move_panel_streams
        @rosterable.reload
        @target.reload

        streams = []
        tile_replacements_for(@rosterable, streams)
        tile_replacements_for(@target, streams)

        streams << @turbo_stream.replace(
          "tutorial-roster-side-panel",
          html: RosterSidePanelComponent.new(
            registerable: @rosterable,
            students: @rosterable.members.order(:name),
            read_only: @rosterable.locked?
          ).render_in(@view_context)
        )

        streams.compact
      end

      def roster_streams
        lecture = Rosters::RosterableResolver.eager_load_lecture(@lecture.id) || @lecture
        group_type = normalize_group_type
        frame_id = resolve_frame_id(group_type, lecture)

        streams = [
          @turbo_stream.update(
            frame_id,
            partial: "registration/campaigns/index",
            locals: { lecture: lecture }
          )
        ]

        streams << @refresh_campaigns_stream.call(lecture) if @refresh_campaigns_stream

        streams
      end

      def tile_replacements_for(rosterable, streams)
        Registration::Item.where(registerable: rosterable).find_each do |item|
          streams << @turbo_stream.replace(
            @view_context.dom_id(item),
            html: GroupTileComponent.new(
              registerable: item.registerable,
              item: item
            ).render_in(@view_context)
          )
        end

        streams << @turbo_stream.replace(
          @view_context.dom_id(rosterable),
          html: GroupTileComponent.new(
            registerable: rosterable
          ).render_in(@view_context)
        )
      end

      def normalize_group_type
        fallback = if @rosterable.is_a?(Lecture)
          :all
        else
          @rosterable&.roster_group_type || :all
        end

        @mparams.normalized_group_type(fallback: fallback)
      end

      def resolve_frame_id(group_type, lecture)
        expected_frame_id = @view_context.roster_maintenance_frame_id(group_type)
        allowed_frame_ids = allowed_roster_frame_ids(lecture)

        if allowed_frame_ids.include?(expected_frame_id)
          expected_frame_id
        else
          allowed_frame_ids.first
        end
      end

      def allowed_roster_frame_ids(lecture)
        group_types = [
          :all,
          *GROUP_TYPE_KEYS,
          @view_context.roster_group_types(lecture)
        ].uniq

        frame_ids = group_types.map do |type|
          @view_context.roster_maintenance_frame_id(type)
        end
        raise("No valid roster frame IDs generated") if frame_ids.empty?

        frame_ids
      end

      def participants
        @participants_state[:participants]
      end

      def pagy
        @participants_state[:pagy]
      end

      def filter_mode
        @participants_state[:filter_mode]
      end

      def search_string
        @participants_state[:search_string]
      end

      def component_counts
        {
          total: @participants_state[:total_count],
          unassigned: @participants_state[:unassigned_count]
        }
      end
  end
end
