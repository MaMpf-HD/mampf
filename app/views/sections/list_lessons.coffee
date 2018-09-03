$('#section-lesson-list-<%= @id %>').empty()
  .append('<%= j render partial: "lessons/list",
                          locals: { lessons: @lessons, inspection: false } %>')
