require 'fuzzystringmatch'

module SearchHelper

  def similar_tags(search_string)
    jarowinkler = FuzzyStringMatch::JaroWinkler.create(:pure)
    tags = Tag.where(id: Tag.all.select{ |t| jarowinkler.getDistance(t.title.downcase, search_string.downcase) > 0.9 }
                            .map(&:id))
  end
end
