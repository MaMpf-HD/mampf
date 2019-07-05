id = <%= @id %>
importTab = document.getElementById('import-vertex-tab')
selected = importTab.dataset.selected
if selected
  selected = JSON.parse(selected)
else
  selected = []
if id in selected
  selected = selected.filter (x) -> x isnt id
  $('#result-quizzable-' + id).removeClass('bg-green-lighten-4')
else
  selected.push id
  $('#result-quizzable-' + id).addClass('bg-green-lighten-4')
importTab.dataset.selected = JSON.stringify(selected)
if selected.length == 0
  $('#importVertexForm').empty()
    .append '<%= j render partial: "quizzes/new_vertex/no_selection" %>'
else
  $('#importVertexForm').empty()
    .append '<%= j render partial: "quizzes/new_vertex/form" %>'
$('#selectionCounter').empty().append('(' + selected.length + ')')