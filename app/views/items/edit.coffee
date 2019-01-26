# set up action box
$('#action-placeholder').empty().append('Eintrag bearbeiten')
$('#action-container').empty()
  .append('<%= j render partial: "items/form",
                        locals: { item: @item }%>')

# make some modification if the item's sort is 'section':
# change description label to 'Titel' and remove fields for number
# and description
<% if @item.sort == 'section' %>
$("label[for='item_description']").empty().append('Titel')
<% if @item.section.present? %>
$('#item_description_field').hide()
$('#item_number_field').hide()
<% end %>
<% end %>

# activate selectize and popovers
$('.selectize').selectize({ plugins: ['remove_button'] })
$('[data-toggle="popover"]').popover()

# workaround for a selectize bug whwere the width of
# the text area for the input prompt is miscalculated
$('input[id$="-selectized"]').css('width', '100%')