id = <%= @id %>
importTab = document.getElementById('importMedia')
selected = importTab.dataset.selected
if selected
  selected = JSON.parse(selected)
else
  selected = []
if id in selected
  selected = selected.filter (x) -> x isnt id
  $('#result-import-' + id).removeClass('bg-green-lighten-4')
else
  selected.push id
  $('#result-import-' + id).addClass('bg-green-lighten-4')
importTab.dataset.selected = JSON.stringify(selected)
if selected.length == 0
  $('#importMediaForm').empty()
    .append '<%= j render partial: "lectures/import/no_selection" %>'
else
  $('#importMediaForm').empty()
    .append '<%= j render partial: "lectures/import/form" %>'
$('#selectionCounter').empty().append('(' + selected.length + ')')