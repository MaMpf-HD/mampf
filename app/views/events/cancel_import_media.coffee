$('#importMediaForm').empty()
  .append '<%= j render partial: "lectures/import/no_selection" %>'
$('#selectionCounter').empty().append('(0)')