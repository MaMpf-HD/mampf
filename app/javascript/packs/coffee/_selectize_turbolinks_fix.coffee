# important: filename starts with underscore to move it in the first
# position of the asset pipeline (it is important that this file's methods are
# executed before all others)

# transfer knowledge about selected items from selectize to html options
resetSelectized = (index, select) ->
  selectedValue = select.selectize.getValue()
  select.selectize.destroy()
  $(select).find('option').attr('selected', null)
  if $(select).prop('multiple')
    for val in selectedValue
      $(select).find("option[value='" + val + "']").attr('selected', true) if val != ''
  else
    $(select).find("option[value='" + selectedValue + "']").attr('selected', true) if selectedValue != ''
  return

fillOptionsByAjax = ($selectizedSelection)->
  $selectizedSelection.each ->
    if this.dataset.drag == 'true'
      plugins = ['remove_button', 'drag_drop']
    else
      plugins = ['remove_button']
    if this.dataset.ajax == 'true' && this.dataset.filled == 'false'
      model_select = this
      courseId = 0
      existing_values = Array.apply(null, model_select.options).map (o) -> o.value
      if this.dataset.model == 'tag'
        locale = this.dataset.locale
        fill_path = Routes.fill_tag_select_path({locale: locale})
      else if this.dataset.model == 'user'
        fill_path = Routes.fill_user_select_path()
      else if this.dataset.model == 'user_generic'
        fill_path = Routes.list_generic_users_path()
      else if this.dataset.model == 'teachable'
        fill_path = Routes.fill_teachable_select_path()
      else if this.dataset.model == 'medium'
        fill_path = Routes.fill_media_select_path()
      else if this.dataset.model == 'course_tag'
        courseId = this.dataset.course
        fill_path = Routes.fill_course_tags_path()
      $.ajax fill_path,
        type: 'GET'
        dataType: 'json'
        data: {
          course_id: courseId
        }
        success: (result) ->
          for option in result
            if option.value.toString() not in existing_values
              new_option = document.createElement('option')
              new_option.value = option.value
              new_option.text = option.text
              model_select.add(new_option, null)
          model_select.dataset.filled = 'true'
          $(model_select).selectize({ plugins: plugins })
          return
      return
    else
      $(this).selectize({ plugins: plugins })
    $('input[id$="-selectized"]').css('width', '100%')
  return


# before caching, destroy selectize forms and tranfer their content to
# vanilla html
$(document).on 'turbolinks:before-cache', ->
  $('.selectized').each resetSelectized
  return

# bugfix
# sometimes selectize miscalculates the width of the prompt,
# making it look empty
# brute force solution: set width to 100%
$(document).on 'turbolinks:load', ->
  fillOptionsByAjax($('.selectize'))
  return
