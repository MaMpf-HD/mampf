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
      $(select).find("option[value=#{val}]").attr('selected', true) if val != ''
  else
    $(select).find("option[value=#{selectedValue}]").attr('selected', true) if selectedValue != ''
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
  $('.selectize').each ->
    if this.id == 'search_tag_ids' && this.dataset.filled == 'false'
      tag_select = this
      $.ajax Routes.fill_tag_select_path(),
        type: 'GET'
        dataType: 'json'
        success: (result) ->
          for option in result
            new_option = document.createElement('option')
            new_option.value = option.value
            new_option.text = option.text
            tag_select.add(new_option, null)
          tag_select.dataset.filled = 'true'
          $(tag_select).selectize({ plugins: ['remove_button'] })
          return
      return
    else
      $(this).selectize({ plugins: ['remove_button'] })
    $('input[id$="-selectized"]').css('width', '100%')
  return
