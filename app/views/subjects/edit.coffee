$('#genericModalLabel').empty().append('<h5><%= t("admin.subject.edit") %></h5>')
$('#generic-modal-content').empty()
	.append('<%= j render partial: "subjects/edit/edit",
												locals: { subject: @subject } %>')
$('#genericModal').modal('show')