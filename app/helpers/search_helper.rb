# Search Helper
require 'fuzzystringmatch'

# if more than one matching tag was omitted letter,
# add letter 'n' to 'wurde'
module SearchHelper
  def plural_n(tags, filtered_tags)
    (tags.count - filtered_tags.count) > 1 ? 'n' : ''
  end
end
