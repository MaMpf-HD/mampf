if $('#lecture-basics-warning').is(':visible') || $('#lecture-preferences-warning').is(':visible')
  $('#no-effect-warning').show()
else
  $('#new-lesson-area').empty()
  $('#lesson-action').empty().append('bearbeiten')
  $('#lesson-modal-content').empty()
    .append('<%= j render partial: "lessons/edit",
                          locals: { lesson: @lesson } %>').show()
  $('#lessonModal').modal('show')
  $('[data-toggle="popover"]').popover()
  $('#lesson-modal-content .selectize').selectize({ plugins: ['remove_button'] })
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
