resetSelectized = (index, select) ->
  selectedValue = select.selectize.getValue()
  select.selectize.destroy()
  # if selected values need to be kept
  # if selectedValue
  #   $select = $(select)
  #   $select.find('option').attr('selected', null)
  #   $select.find("option[value=#{selectedValue}]").attr('selected', true)
  return

$(document).on 'turbolinks:before-cache', ->
  $('.selectized').each resetSelectized
