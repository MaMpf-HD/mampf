module RequestParsingHelper
  # Parse the request body as HTML and return the number of hits
  def parse_media_search(response)
    # rubocop:todo Naming/VariableName
    searchResults = response.body.match(/(?<=searchResults.innerHTML = ').*(?=';)/)[0].gsub('\n',
                                                                                            "")
    # rubocop:enable Naming/VariableName
    # strip whitespaces in searchResults
    searchResults = searchResults.gsub(/\s+/, " ") # rubocop:todo Naming/VariableName
    # fix " in searchResults
    searchResults = searchResults.gsub('\\\"', '"') # rubocop:todo Naming/VariableName
    # fix \/ in searchResults
    searchResults = searchResults.gsub('\\/', "/") # rubocop:todo Naming/VariableName

    # parse searchResults as html
    searchResults = Nokogiri::HTML(searchResults) # rubocop:todo Naming/VariableName

    # get text within first "col-12 col-lg-2" div
    treffer = searchResults.css("div.col-12.col-lg-2").first.text # rubocop:todo Naming/VariableName
    # get number in treffer
    treffer.match(/\d+/)[0].to_i
  end
end

RSpec.configure do |config|
  config.include RequestParsingHelper, type: :request
end
