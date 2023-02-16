$('#tag_realizations').empty()
  .append('<%= j render partial: "erdbeere/fill_realizations_select",
                        locals: { structures: @structures,
                                  properties: @properties,
                                  tag: @tag } %>')
  new TomSelect('#tag_realizations',{ plugins: ['remove_button'] })