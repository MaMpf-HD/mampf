$('#lesson-section-list').empty()
  .append('<%= j render partial: "sections/list",
                          locals: { sections: @sections, inspection: true } %>')
