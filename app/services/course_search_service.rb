class CourseSearchService
  attr_reader :params, :scope

  def initialize(params, scope = Course.all)
    @params = params.to_h.with_indifferent_access
    @scope = scope
  end

  def call
    apply_filters
    @scope
  end

  private

    def apply_filters
      @scope = apply_editor_filter
      @scope = apply_program_filter
      @scope = apply_term_independence_filter
      @scope = apply_fulltext_filter
    end

    def apply_editor_filter
      return scope if params[:all_editors] == "1"

      scope.by_editors(params[:editor_ids])
    end

    def apply_program_filter
      return scope if params[:all_programs] == "1"

      scope.by_programs(params[:program_ids])
    end

    def apply_term_independence_filter
      return scope unless params[:term_independent] == "1"

      scope.term_independent_only
    end

    def apply_fulltext_filter
      return scope if params[:fulltext].blank?

      scope.search_by_title(params[:fulltext])
    end
end
