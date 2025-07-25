module Search
  class EditorFilter < BaseFilter
    def call
      return scope if params[:all_editors] == "1" || params[:editor_ids].blank?

      scope.joins(:editors)
           .where(users: { id: params[:editor_ids] })
           .distinct
    end
  end
end
