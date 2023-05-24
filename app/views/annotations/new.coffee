$('#annotation-modal-content').empty()
  .append('<%= j render partial: "annotations/form"%>')
$('#annotation-modal').modal('show')

categoryRadios = document.getElementById('category-radios')

categoryRadios.addEventListener 'click', (evt) ->
  if evt.target && event.target.matches("input[type='radio']")
    switch evt.target.value
      when "note" then note()
      when "content" then content()
      when "mistake" then mistake()
      when "presentation" then presentation()
  return

note = ->
  $('#specific').empty()
  visibleForTeacher(false)
  postComment(false)
  return

content = ->
  $('#specific').empty().append('<%= j render partial: "annotations/form_content"%>')
  visibleForTeacher(true)
  postComment(false)
  return

mistake = ->
  $('#specific').empty()
  visibleForTeacher(true)
  postComment(true)
  return

presentation = ->
  $('#specific').empty().append('<%= j render partial: "annotations/form_presentation"%>')
  visibleForTeacher(true)
  postComment(false)
  return



# Auxiliary methods

visibleForTeacher = (boolean) ->
  $('#annotation_visible_for_teacher').prop("checked", boolean)
  return

postComment = (boolean) ->
  $('#annotation_post_as_comment').prop("checked", boolean)
  return