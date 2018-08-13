require 'fuzzystringmatch'

module SearchHelper

  def plural_n(tags, filtered_tags)
    (tags.count - filtered_tags.count) > 1 ? 'n' : ''
  end
end
