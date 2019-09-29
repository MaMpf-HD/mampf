id = <%= @id %>
importTab = document.getElementById('importMedia')
selected = importTab.dataset.selected
if selected
  selected = JSON.parse(selected)
else
  selected = []
if id in selected
  selected = selected.filter (x) -> x isnt id
  $('#row-medium-' + id).removeClass('bg-green-lighten-4')
else
  selected.push id
  $('#row-medium-' + id).addClass('bg-green-lighten-4')
importTab.dataset.selected = JSON.stringify(selected)
if selected.length == 0
  $('#importMediaForm').empty()
    .append '<%= j render partial: "shared/no_selection" %>'
else
  $('#importMediaForm').empty()
    .append '<%= j render partial: "shared/import_form",
                          locals: { purpose: @purpose } %>'
$('#selectionCounter').empty().append('(' + selected.length + ')')