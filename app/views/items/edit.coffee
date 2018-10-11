$('#action-placeholder').empty().append('Item bearbeiten')
$('#action-container').empty()
  .append('<%= j render partial: "items/form",
                        locals: { item: @item }%>')
<% if @item.sort == 'section' %>
$("label[for='item_description']").empty().append('Titel')
<% if @item.section.present? %>
$('#item_description_field').hide()
$('#item_number_field').hide()
<% end %>
<% end %>
$('.selectize').selectize({ plugins: ['remove_button'] })
$('input[id$="-selectized"]').css('width', '100%')
