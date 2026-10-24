module Rosters
  # One roster lookup per assignment per rendered response
  module UsersMovementCaching
    def users_movement_map_cache
      @users_movement_map_cache ||= {}
    end

    def left_lecture_user_ids_cache
      @left_lecture_user_ids_cache ||= {}
    end
  end
end
