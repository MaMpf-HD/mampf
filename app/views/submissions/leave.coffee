$('.submissionMain[data-id="<%= @assignment.id %>"]').empty()
  .append('<%= j render partial: "submissions/card_main",
                        locals: { assignment: @assignment,
                                  submission: nil } %>')
$('.submissionHeader[data-id="<%= @assignment.id %>"]')
	.removeClass('bg-submission-yellow bg-submission-green')
	.addClass('bg-submission-red')
$('#late-submission-warning').popover()