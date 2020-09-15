$('.submissionMain[data-id="<%= @assignment.id %>"]').empty()
  .append('<%= j render partial: "submissions/card_main",
                        locals: { assignment: @assignment,
                                  submission: @submission } %>')