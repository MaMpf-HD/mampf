$('#annotation-modal-content').empty()
  .append('<%= j render partial: "annotations/form"%>')
$('#annotation-modal').modal('show')

submitButton = document.getElementById('submit-button')
postAsComment = document.getElementById('annotation_post_as_comment')

postAsComment.addEventListener 'change', (evt) ->
  if this.checked
    warningMessage()
  return

warningMessage = () ->
  message = document.getElementById('warning').dataset.publishing
  mistakeRadio = document.getElementById('annotation_category_mistake')
  if mistakeRadio.checked
    message += "\n" + document.getElementById('warning').dataset.mistake
    medId = thyme.dataset.medium
    rad = 60 # annotations that are inside this radius (in seconds) are considered as "near". 
    $.ajax Routes.near_mistake_annotations_path(),
      type: 'GET'
      dataType: 'json'
      data: {
        mediumId: medId
        timestamp: video.currentTime
        radius: rad
      }
      success: (c) ->
        if c != undefined && c != 0
          if c == 1
            message += document.getElementById('warning').dataset.oneCloseAnnotation
          else
            message += document.getElementById('warning').dataset.multipleCloseAnnotations1 +
                       "" + c +
                       document.getElementById('warning').dataset.multipleCloseAnnotations2
          alert message
  else
    alert message
  return



# CATEGORY

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
  submitButton.disabled = false
  visibleForTeacher(false)
  postComment(false)
  return

content = ->
  $('#specific').empty().append('<%= j render partial: "annotations/form_content"%>')
  submitButton.disabled = true # disable submit button until the content category is selected
  visibleForTeacher(true)
  postComment(false)
  contentCategoryRadios = document.getElementById('content-category-radios')
  contentCategoryRadios.addEventListener 'click', (evt) ->
    if evt.target && event.target.matches("input[type='radio']")
      submitButton.disabled = false
      switch evt.target.value
        when "definition" then definition()
        when "argument" then argument()
        when "strategy" then strategy()
    return
  definition = ->
    $('#content-specific').empty().append('<%= j render partial: "annotations/form_content_definition"%>')
    return
  argument = ->
    $('#content-specific').empty()
    return
  strategy = ->
    $('#content-specific').empty()
    return
  return

mistake = ->
  $('#specific').empty()
  submitButton.disabled = false
  visibleForTeacher(true)
  postComment(true)
  warningMessage()
  return

presentation = ->
  $('#specific').empty()
  submitButton.disabled = false
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



# If this script is rendered by the edit method of the annotation controller:
# Select correct subcategory (this is not automatically done by the rails form
# as the content is dynamically rendered).
contentRadio = document.getElementById('annotation_category_content')
if contentRadio.checked
  content()
  submitButton.disabled = false
  subtext = document.getElementById('annotation_subtext').textContent.replace(/[^a-z]/g, '')
  switch subtext
    when "definition" then document.getElementById('content-category-definition').checked = true
    when "argument" then document.getElementById('content-category-argument').checked = true
    when "strategy" then document.getElementById('content-category-strategy').checked = true
  return