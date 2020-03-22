$('#genericModalLabel').empty().append('<h5><%= t("admin.area.edit") %></h5>')
$('#generic-modal-content').empty()
	.append('<%= j render partial: "areas/edit/edit",
												locals: { area: @area } %>')
$('#genericModal').modal('show')