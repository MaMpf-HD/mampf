# render new tag modal
$('#new-tag-modal-content').empty()
  .append('<%= j render partial: "tags/modal_form",
                        locals: { tag: @tag,
                                  new_tag: true,
                                  graph_elements: nil,
                                  from: @from }%>')

# activate popovers and selectize
$('[data-toggle="popover"]').popover()
$('#new-tag-modal-content .selectize').selectize({ plugins: ['remove_button'] })

# bugfix for selectize (which sometimes renders the prompt with a zero width)
$('input[id$="-selectized"]').css('width', '100%')

# store from where the modal was called
$('#newTagModal').modal('show').data('from','<%= @from %>')

$('#newTagModal').on 'shown.bs.modal', ->
  $('#tag_notions_attributes_0_title').focus()
  return