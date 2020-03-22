$('#genericModalLabel').empty().append('<h5><%= t("admin.area.new") %></h5>')
$('#generic-modal-content').empty()
	.append('<%= j render partial: "areas/edit/edit",
												locals: { area: @area } %>')
$('#genericModal').modal('show')