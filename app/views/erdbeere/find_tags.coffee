$('#erdbeereTags').empty()
	.append('<%= j render partial: "erdbeere/find_tags",
												locals: { tags: @tags } %>')