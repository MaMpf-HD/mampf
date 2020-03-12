$('#erdbeereTags').empty()
	.append('<%= j render partial: "erdbeere/find_tags",
												locals: { tags: @tags,
                                  sort: @sort,
                                  id: @id } %>')
fillOptionsByAjax($('#erdbeereTags .selectize'))
$('#edit-erdbeere-tags-form').hide()
$('#editErdbeereTags').empty()
  .append('<%= j render partial: "erdbeere/edit_tags_button",
                        locals: { tags: @tags } %>')