# disable all other input fields when a section is edited
$('.fa-edit').hide()
$('.new-in-lecture').hide()
$('#lectureAccordion .collapse').collapse('hide')
$('[data-toggle="collapse"]').addClass('disabled')

# render edit section form
$('#<%= dom_id(@section) %>').empty().removeClass('bg-mdb-color-lighten-6')
  .addClass('bg-yellow-lighten-5')
  .append('<%= j render partial: "sections/form",
                        locals: { section: @section } %>')

 # activate popovers and selectize
$('#section-form .selectize').each ->
  if this.dataset.ajax == 'true' && this.dataset.filled == 'false'
    tag_select = this
    locale = tag_select.dataset.locale
    $.ajax Routes.fill_tag_select_path({locale: locale}),
      type: 'GET'
      dataType: 'json'
      success: (result) ->
        for option in result
          new_option = document.createElement('option')
          new_option.value = option.value
          new_option.text = option.text
          tag_select.add(new_option, null)
        tag_select.dataset.filled = 'true'
        $(tag_select).selectize({ plugins: ['remove_button', 'drag_drop'] })
        return
    return
  else
    $(this).selectize({ plugins: ['remove_button'] })
  $('#section-form input[id$="-selectized"]').css('width', '100%')


$('[data-toggle="popover"]').popover()
# bugfix for selectize (which sometimes renders the prompt with a zero width)
$('input[id$="-selectized"]').css('width', '100%')