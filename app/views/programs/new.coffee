$('#genericModalLabel').empty().append('<h5><%= t("admin.program.new") %></h5>')
$('#generic-modal-content').empty()
	.append('<%= j render partial: "programs/edit/edit",
												locals: { program: @program } %>')
$('#genericModal').modal('show')