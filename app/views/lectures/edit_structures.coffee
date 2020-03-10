$('#erdbeereStructuresBody').empty()
.append('<%= j render partial: "lectures/show/structures",
                      locals: { structures: @structures,
                                properties: @properties } %>')