$('.assignmentRow[data-id="<%= @assignment.id %>"')
  .replaceWith('<%= j render partial: "assignments/form",
                      locals: { assignment: @assignment } %>')