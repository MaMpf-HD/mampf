$('#<%= dom_id(@section) %>').empty().removeClass('bg-mdb-color-lighten-6')
  .append('<%= j render partial: "sections/body",
                        locals: { section: @section } %>')
$('#section-form .selectize').selectize({ plugins: ['remove_button'] })
