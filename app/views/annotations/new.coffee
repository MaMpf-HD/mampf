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
  return

content = ->
  $('#specific').empty().append('<%= j render partial: "annotations/form_content"%>')
  $('#annotation_visible_for_teacher').prop("checked", true)
  return

mistake = ->
  $('#specific').empty().append('<%= j render partial: "annotations/form_mistake"%>')
  $('#annotation_visible_for_teacher').prop("checked", true)
  return

presentation = ->
  $('#specific').empty().append('<%= j render partial: "annotations/form_presentation"%>')
  $('#annotation_visible_for_teacher').prop("checked", true)
  return