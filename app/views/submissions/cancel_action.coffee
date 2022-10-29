$('.submission-actions[data-id="<%= @submission.id %>"]').empty()
  .append('<%= j render partial: "submissions/other_actions",
                        locals: { submission: @submission } %>')