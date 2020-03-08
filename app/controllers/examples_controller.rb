# ExamplesController
class ExamplesController < ApplicationController
  authorize_resource class: false

	def show
		id = params[:id]
    response = Faraday.get "https://erdbeere-dev.mathi.uni-heidelberg.de/api/v1/examples/#{id}"
    json = JSON.parse(response.body)
    @content = json['embedded_html']
    render layout: 'application'
	end
end