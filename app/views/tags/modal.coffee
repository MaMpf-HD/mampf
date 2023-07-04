# render new tag modal
$('#new-tag-modal-content').empty()
  .append('<%= j render partial: "tags/modal_form",
                        locals: { tag: @tag,
                                  new_tag: true,
                                  graph_elements: nil,
                                  from: @from }%>')

# activate popovers and selectize
$('[data-bs-toggle="popover"]').popover()
fillOptionsByAjax($('#new-tag-modal-content .selectize'))

# store from where the modal was called
$('#newTagModal').modal('show').data('from','<%= @from %>')

$('#newTagModal').on 'shown.bs.modal', ->
  $('#titlesInput input[data-locale="<%= @locale %>"]').first().focus()
  return