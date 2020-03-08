# ExamplesController
class ErdbeereController < ApplicationController
  authorize_resource class: false
	layout 'application'

	def show_example
    response = Faraday.get "https://erdbeere-dev.mathi.uni-heidelberg.de/" \
    											 "api/v1/examples/#{params[:id]}"
    @content = if response.status == 200
								 JSON.parse(response.body)['embedded_html']
							 else
							 	 'Something went wrong.'
							 end
	end

	def show_property
    response = Faraday.get "https://erdbeere-dev.mathi.uni-heidelberg.de/" \
    											 "api/v1/properties/#{params[:id]}"

		@content = if response.status == 200
								 JSON.parse(response.body)['embedded_html']
							 else
							 	 'Something went wrong.'
							 end
	end

	def show_structure
		id = params[:id]
    response = Faraday.get "https://erdbeere-dev.mathi.uni-heidelberg.de/" \
    											 "api/v1/structures/#{params[:id]}"
    @content = if response.status == 200
								 JSON.parse(response.body)['embedded_html']
							 else
							 	 'Something went wrong.'
							 end
	end
end