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

  private

  def erdbeere_params
    params.require(:erdbeere).permit(:sort, :id, tag_ids: [])
  end
end