$('.submission-row[data-id="<%= @submission.id %>"]')
  .removeClass('bg-submission-orange')
  .empty().append('<%= j render partial: "tutorials/submission_row",
                                locals: { submission: @submission } %>')