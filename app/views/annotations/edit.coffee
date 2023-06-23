$('#annotation-modal-content').empty()
  .append('<%= j render partial: "annotations/form"%>')
$('#annotation-modal').modal('show')

submitButton = document.getElementById('submit-button')
postAsComment = document.getElementById('post-as-comment')

postAsComment.addEventListener 'change', (evt) ->
  message = "Everyone who subscribed this lecture will be able to read your comment once " +
            "you click \"Create Annotation\". " +
            "If this is not what you intended to do, please unselect this checkbox."
  if this.checked
    mistakeRadio = document.getElementById('annotation_category_mistake')
    if mistakeRadio.checked
      message += "\n\nBefore submitting, please also check, if someone already posted " +
                 " a comment concerning this mistake. "
      medId = thyme.dataset.medium
      rad = 60 # annotations that are inside this radius are considered as "near". 
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
              message += "There already is a (public) mistake annotation that is close to yours."
            else
              message += "There are already " + c + " (public) mistake annotations that are close to yours."
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
  return

presentation = ->
  $('#specific').empty().append('<%= j render partial: "annotations/form_presentation"%>')
  submitButton.disabled = false
  visibleForTeacher(true)
  postComment(false)
  return



# select correct subcategory
contentRadio = document.getElementById('annotation_category_content')
if contentRadio.checked
  content()
  return



# Auxiliary methods

visibleForTeacher = (boolean) ->
  $('#annotation_visible_for_teacher').prop("checked", boolean)
  return

postComment = (boolean) ->
  $('#annotation_post_as_comment').prop("checked", boolean)
  return