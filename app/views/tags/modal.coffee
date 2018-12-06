$('#new-tag-modal-content').empty()
  .append('<%= j render partial: "tags/form",
                        locals: { tag: @tag,
                                  new_tag: true,
                                  modal: true,
                                  graph_elements: nil,
                                  from: @from }%>')
$('[data-toggle="popover"]').popover()
$('#new-tag-modal-content .selectize').selectize({ plugins: ['remove_button'] })
$('#newTagModal').modal('show').data('from','<%= @from %>')
