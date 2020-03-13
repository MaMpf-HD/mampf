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

	def find_tags
		@sort = params[:sort]
		@id = params[:id].to_i
		@tags = Tag.find_erdbeere_tags(@sort, @id)
	end

  def edit_tags
  end

  def cancel_edit_tags
  end

  def display_info
    @id = params[:id]
    @sort = params[:sort]
    response = Faraday.get "https://erdbeere-dev.mathi.uni-heidelberg.de/" \
                           "api/v1/#{@sort.downcase.pluralize}/#{@id}/view_info"
    @content = JSON.parse(response.body)
    if response.status != 200
      @info = 'Something went wrong'
      return
    end
    @info = if @sort == 'Structure'
              @content['data']['attributes']['name']
            else
              "#{@content['included'][0]['attributes']['name']}:"\
              "#{@content['data']['attributes']['name']}"
            end
  end

  def update_tags
    tags = Tag.where(id: erdbeere_params[:tag_ids])
    sort = erdbeere_params[:sort]
    id = erdbeere_params[:id].to_i
    previous_tags = Tag.find_erdbeere_tags(sort, id)
    added_tags = tags - previous_tags
    removed_tags = previous_tags - tags
    added_tags.each do |t|
      t.update(realizations: t.realizations.push([sort, id]))
    end
    removed_tags.each do |t|
      t.update(realizations: t.realizations - [[sort, id]])
    end
    if sort == 'Structure'
      redirect_to erdbeere_structure_path(id)
      return
    end
    redirect_to erdbeere_property_path(id)
  end

  def fill_realizations_select
    response = Faraday.get 'https://erdbeere-dev.mathi.uni-heidelberg.de/' \
                           'api/v1/structures/'
    @tag = Tag.find_by_id(params[:id])
    hash = JSON.parse(response.body)
    @structures = hash['data'].map do |d|
      { id: d['id'],
        name: d['attributes']['name'],
        properties: d['relationships']['original_properties']['data'].map { |x| x['id'] }}
    end
    @properties = hash['included'].map do |d|
      { id: d['id'],
        name: d['attributes']['name'] }
    end
  end

  private

  def erdbeere_params
    params.require(:erdbeere).permit(:sort, :id, tag_ids: [])
  end
end