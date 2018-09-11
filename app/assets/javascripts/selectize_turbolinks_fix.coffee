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

$(document).on 'turbolinks:before-cache', ->
  $('.selectized').each resetSelectized
  return
