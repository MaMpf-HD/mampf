$('.submissionMain[data-id="<%= @assignment.id %>"]').empty()
  .append('<%= j render partial: "submissions/card_main",
                        locals: { assignment: @assignment,
                                  submission: nil } %>')
$('#submissionCard')
	.removeClass('bg-post-it-red bg-post-it-yellow bg-post-it-green')
	.addClass('bg-submission-red')