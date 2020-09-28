$('.submissionMain[data-id="<%= @assignment.id %>"]').empty()
  .append('<%= j render partial: "submissions/card_main",
                        locals: { assignment: @assignment,
                                  submission: nil } %>')
$('.submissionCard[data-id="<%= @assignment.id %>"]')
	.removeClass('bg-submision-red bg-submission-yellow bg-submission-green')
	.addClass('bg-submission-red')