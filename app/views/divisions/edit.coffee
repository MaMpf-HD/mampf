$('#genericModalLabel').empty().append('<h5><%= t("admin.division.edit") %></h5>')
$('#generic-modal-content').empty()
	.append('<%= j render partial: "divisions/edit/edit",
												locals: { division: @division } %>')
$('#genericModal').modal('show')