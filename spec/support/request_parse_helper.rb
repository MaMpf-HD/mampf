module RequestParsingHelper
  
  # Parse the request body as HTML and return the number of hits
  def parse_media_search(response)
    searchResults = response.body.match(/(?<=searchResults.innerHTML = ').*(?=';)/)[0].gsub('\n', "")
    # strip whitespaces in searchResults
    searchResults = searchResults.gsub(/\s+/, " ")
    # fix " in searchResults
    searchResults = searchResults.gsub(/\\\"/, '"')
    # fix \/ in searchResults
    searchResults = searchResults.gsub('\\/', "/")
    
    # parse searchResults as html
    searchResults = Nokogiri::HTML(searchResults)
  
    # get text within first "col-12 col-lg-2" div
    treffer = searchResults.css("div.col-12.col-lg-2").first.text
    # get number in treffer
    treffer = treffer.match(/\d+/)[0].to_i
    treffer 
  end

end

RSpec.configure do |config|
config.include RequestParsingHelper, type: :request
end