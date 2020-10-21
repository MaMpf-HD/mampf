$('#upload-bulk-errors').empty().hide()
#directUpload('upload-bulk-correction',)
<% if @errors.present? %>
$('#upload-bulk-errors').append('<%= @errors.join(", ") %>').show()
<% else %>
clearBulkUploadArea()
$('#bulk-upload-report').empty()
	.append('<%= j render partial: "tutorials/bulk_upload_report",
												locals: { report: @report } %>').show()
$('#tutorial-table').empty()
	.append('<%= j render partial: "tutorials/table",
												locals: { assignment: @assignment,
																	tutorial: @tutorial,
																	stack: @stack } %>')
$('[data-toggle="popover"]').popover()
<% end %>