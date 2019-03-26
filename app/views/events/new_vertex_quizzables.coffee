$('#new_vertex_quizzable_select').empty()
  .append '<%= j render partial: "quizzables" %>'
$('#new_vertex_quizzable_select').trigger 'change'
