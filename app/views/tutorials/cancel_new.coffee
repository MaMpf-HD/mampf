$('.tutorialRow[data-id="0"]').remove()
<% if @none_left %>
$('#tutorialListHeader').hide()
<% end %>
$('#newTutorialButton').show()