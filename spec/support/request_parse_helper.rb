module RequestParsingHelper
  # Parse the request body as HTML and return the number of hits
  def parse_media_search(response)
    search_results = response.body
                             .match(/(?<=searchResults.innerHTML = ').*(?=';)/)[0]
                             .gsub('\n', "")
    # strip whitespaces in search_results
    search_results = search_results.gsub(/\s+/, " ")
    # fix " in search_results
    search_results = search_results.gsub(/\\\"/, '"') # rubocop:disable Style/RedundantRegexpArgument,Style/RedundantRegexpEscape
    # fix \/ in search_results
    search_results = search_results.gsub('\\/', "/")

    # parse search_results as html
    search_results = Nokogiri::HTML(search_results)

    # get text within first "col-12 col-lg-2" div
    num_hits_text = search_results.css("div.col-12.col-lg-2").first.text
    # get number in matches
    num_hits_text.match(/\d+/)[0].to_i
  end
end

RSpec.configure do |config|
  config.include RequestParsingHelper, type: :request
end
