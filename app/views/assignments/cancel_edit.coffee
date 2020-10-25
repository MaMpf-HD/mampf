$('.assignmentRow[data-id="<%= @assignment.id %>')
  .replaceWith('<%= j render partial: "assignments/row",
                      locals: { assignment: @assignment,
                      					inspection: false } %>')