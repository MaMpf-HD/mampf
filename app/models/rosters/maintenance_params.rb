module Rosters
  # Encapsulates and normalizes the various parameters that can be sent from the
  # roster maintenance UI, providing a single source of truth for interpreting
  # these parameters in the controller and related classes.
  class MaintenanceParams
    SOURCE_TYPES = ["panel", "unassigned", "participants"].freeze

    attr_reader :group_type, :source, :source_id, :source_type, :target_id,
                :target_type, :user_id, :email, :mode, :search,
                :roster_tab

    def initialize(params, lecture: nil)
      @group_type_given = params.key?(:group_type)
      permitted = params.permit(
        :group_type, :source, :source_id, :source_type, :target_id,
        :target_type, :user_id, :email, :type, :mode,
        :search, :tab, :id,
        group_type: []
      )

      @group_type = normalize_group_type(permitted)
      @source = normalize_source(permitted[:source])
      @source_type = validate_type(permitted[:source_type])
      @source_id = validate_source_id(permitted[:source_id], lecture)
      @target_id = permitted[:target_id]
      @target_type = validate_type(permitted[:target_type])
      @user_id = permitted[:user_id]
      @email = permitted[:email]
      @mode = permitted[:mode]
      @search = permitted[:search]
      @roster_tab = permitted[:tab]&.to_sym
    end

    def group_type_given?
      @group_type_given
    end

    def normalized_group_type(fallback: :all)
      return group_type if group_type_given?
      return group_type if group_type.is_a?(Array)

      fallback
    end

    def panel?
      source == "panel"
    end

    def unassigned?
      source == "unassigned" && source_id.present?
    end

    def participants?
      source == "participants"
    end

    private

      def normalize_group_type(permitted)
        raw = permitted[:group_type]

        if raw.is_a?(Array)
          raw.map(&:to_sym)
        else
          raw&.to_sym || :all
        end
      end

      def normalize_source(raw)
        raw if SOURCE_TYPES.include?(raw)
      end

      def validate_source_id(raw, lecture)
        return nil if raw.blank?
        return raw unless lecture
        return raw if @source == "panel"

        exists = lecture.registration_campaigns.exists?(id: raw)
        exists ? raw : nil
      end

      def validate_type(raw)
        return nil if raw.blank?

        Rosters::Rosterable::TYPES.include?(raw) ? raw : nil
      end
  end
end
