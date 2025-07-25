# ExamplesController
class ErdbeereController < ApplicationController
  authorize_resource class: false
  layout "application"

  def current_ability
    @current_ability ||= ErdbeereAbility.new(current_user)
  end

  def show_example
    response = Clients::ErdbeereClient.get("examples/#{params[:id]}")
    @content = if response.status == 200
      JSON.parse(response.body)["embedded_html"]
    else
      I18n.t("erdbeere.error")
    end
  end

  def show_property
    response = Clients::ErdbeereClient.get("properties/#{params[:id]}")

    @content = if response.status == 200
      JSON.parse(response.body)["embedded_html"]
    else
      I18n.t("erdbeere.error")
    end
  end

  def show_structure
    params[:id]
    response = Clients::ErdbeereClient.get("structures/#{params[:id]}")
    @content = if response.status == 200
      JSON.parse(response.body)["embedded_html"]
    else
      I18n.t("erdbeere.error")
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
    response = Clients::ErdbeereClient.get("#{@sort.downcase.pluralize}/#{@id}/view_info")
    @content = JSON.parse(response.body)
    if response.status != 200
      @info = I18n.t("erdbeere.error")
      return
    end
    @info = if @sort == "Structure"
      @content["data"]["attributes"]["name"]
    else
      "#{@content["included"][0]["attributes"]["name"]}:" \
        "#{@content["data"]["attributes"]["name"]}"
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
    if sort == "Structure"
      redirect_to erdbeere_structure_path(id)
      return
    end
    redirect_to erdbeere_property_path(id)
  end

  def fill_realizations_select
    response = Clients::ErdbeereClient.get("structures")
    @tag = Tag.find_by(id: params[:id])
    hash = JSON.parse(response.body)
    @structures = hash["data"].map do |d|
      { id: d["id"],
        name: d["attributes"]["name"],
        properties: d["relationships"]["original_properties"]["data"].pluck("id") }
    end
    @properties = hash["included"].map do |d|
      { id: d["id"],
        name: d["attributes"]["name"] }
    end
  end

  def find_example
    response = Clients::ErdbeereClient.get("find?#{find_params.to_query}")
    @content = if response.status == 200
      JSON.parse(response.body)["embedded_html"]
    else
      I18n.t("erdbeere.error")
    end
  end

  private

    def erdbeere_params
      params.expect(erdbeere: [:sort, :id, { tag_ids: [] }])
    end

    def find_params
      params.expect(find: [:structure_id,
                           { satisfies: [],
                             violates: [] }])
    end
end
