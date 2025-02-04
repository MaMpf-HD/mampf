$('.correction-column[data-id="<%= @submission.id %>"]').empty()
  .append('<%= j render partial: "submissions/correction_column",
                        locals: { submission: @submission } %>')