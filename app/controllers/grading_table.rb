# Restricts grading responses to tables the user may see. The lecture's table
# holds every group's rows and counts, so the grading_scope_type a request
# names cannot decide on its own which table it gets.
module GradingTable
  private

    def grading_table(tutorial, lecture)
      whole_lecture = current_user.can_enter_points_in?(lecture)
      if tutorial && (params[:grading_scope_type] == "tutorial" || !whole_lecture)
        return tutorial if whole_lecture || current_user.can_enter_points_in?(tutorial)
      elsif whole_lecture
        return lecture
      end

      raise(CanCan::AccessDenied)
    end
end
