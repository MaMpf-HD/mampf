$('.tutorialRow[data-id="<%= @tutorial.id %>"').remove()
<% if @lecture.tutorials.none? %>
$('#tutorialListHeader').hide()
<% end %>