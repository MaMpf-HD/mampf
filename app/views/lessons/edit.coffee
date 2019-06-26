# issue a warning if lecture preferences have been changed but not yet saved
# user can only edit lesson if he has saved or canceled lefture preferences
if $('#lecture-basics-warning').is(':visible') || $('#lecture-preferences-warning').is(':visible')
  $('#no-effect-warning').show()
else
  # render edit lesson form
  $('#new-lesson-area').empty().hide()
  $('#lesson-modal-content').empty()
    .append('<%= j render partial: "lessons/edit",
                          locals: { lesson: @lesson } %>').show()
  $('#lessonModal').modal('show')

  # activate popovers and selectize
  $('[data-toggle="popover"]').popover()

  $('#lesson-modal-content .selectize').each ->
    if this.dataset.ajax == 'true' && this.dataset.filled == 'false'
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
  $('#lesson-modal-content input[id$="-selectized"]').css('width', '100%')



  # add/remove associated tags in the tag selector
  # if sections are selected/deselected
  # this code has to be here, as the lessons.coffe code does not apply to
  # the newly rendered modal
  sectionSelector = document.getElementById('lesson_section_ids')
  tagSelector = document.getElementById('lesson_tag_ids')
  sectionSelectize = sectionSelector.selectize
  tagSelectize = tagSelector.selectize
  # tags and their associated sections are stored in the data-tags attribute
  tags = $(sectionSelector).data('tags')

  sectionSelectize.on 'item_remove', (value) ->
    removeTags = (tags.filter (x) -> x.section.toString() == value.toString())[0].tags
    ids = removeTags.map (x) -> x[0]
    for i in ids
      tagSelectize.removeItem(i)
      tagSelectize.removeOption(i)
    tagSelectize.refreshItems()
    tagSelectize.refreshOptions(false)
    return

  sectionSelectize.on 'item_add', (value) ->
    addTags = (tags.filter (x) -> x.section.toString() == value.toString())[0].tags
    for i in addTags
      tagSelectize.addOption({ value: i[0], text: i[1] })
      tagSelectize.addItem(i[0])
    tagSelectize.refreshItems()
    tagSelectize.refreshOptions(false)

  lessonItems = document.getElementById('lessonItems')
  if lessonItems
    renderMathInElement lessonItems,
      delimiters: [
        {
          left: '$$'
          right: '$$'
          display: true
        }
        {
          left: '$'
          right: '$'
          display: false
        }
        {
          left: '\\('
          right: '\\)'
          display: false
        }
        {
          left: '\\['
          right: '\\]'
          display: true
        }
      ]
      throwOnError: false