module Registration
  class CampaignablePoro
    attr_accessor :id, :title, :term_year, :term_season, :course_short_title

    def initialize(id:, title:, term_year: nil, term_season: nil, course_short_title: nil)
      @id = id
      @title = title
      @term_year = term_year
      @term_season = term_season
      @course_short_title = course_short_title
    end
  end
end
