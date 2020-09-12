$('.submissionButtons[data-id="<%= @assignment.id %>"]').empty().addClass('pl-2')
	.append('<%= j render partial: "submissions/form",
												locals: { submission: @submission } %>')

$('#submission_tutorial_id').select2
  theme: 'bootstrap'