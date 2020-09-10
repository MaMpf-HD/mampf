$('#assignmentListHeader').show()
  .after('<%= j render partial: "assignments/form",
                       locals: { assignment: @assignment } %>')