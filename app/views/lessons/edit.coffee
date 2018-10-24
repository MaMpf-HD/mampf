if $('#lecture-basics-warning').is(':visible')
  $('#no-effect-warning').show()
else
  $('#new-lesson-area').empty()
    .append('<%= j render partial: "lessons/edit",
                          locals: { lesson: @lesson } %>').show()
  $('#new-lesson-area .selectize').selectize({ plugins: ['remove_button'] })
  $('#new_lesson_button').hide()
  $('#new_chapter_button').hide()
  $('[id^="new_section_button"]').hide()
  sectionSelector = document.getElementById('lesson_section_ids')
  tagSelector = document.getElementById('lesson_tag_ids')
  sectionSelectize = sectionSelector.selectize
  tagSelectize = tagSelector.selectize
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

  $('#cancel-new-lesson').on 'click', ->
    $('#new-lesson-area').empty().hide()
    $('#new_lesson_button').show()
    $('#new_chapter_button').show()
    $('[id^="new_section_button"]').show()
    return
