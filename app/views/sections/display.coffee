$('#section-content-modal-content').empty()
  .append('<%= j render partial: "items/items",
                        locals: { items: @section.visible_items,
                        small: false } %>')
$('#section-title-modal').empty().append('"<%= @section.title %>"')
$('#sectionContentModal').modal('show')