$('#annotation-modal-content').empty()
	.append('<%= j render partial: "annotations/form"%>')
$('#annotation-modal').modal('show')
