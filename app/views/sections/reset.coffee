$('#section-body-<%= @section.id %>').empty()
  .append('<%= j render partial: "sections/body",
                        locals: { section: @section } %>')
$('#section-body-<%= @section.id %> .selectize').selectize({ plugins: ['remove_button'] })
$('[id^="section-form-"] :input').on 'change', ->
  sectionId = this.dataset.id
  $('#section-basics-warning-' + sectionId).show().data('shown', '1')
  tags = document.getElementById('section_tag_ids_' + sectionId).selectize.getValue()
  $.ajax Routes.list_section_tags_path(),
    type: 'GET'
    dataType: 'script'
    data: {
      id: sectionId
      tags: JSON.stringify(tags)
    }
  return
$('[id^="section-basics-cancel-"]').on 'click', ->
  sectionId = this.dataset.id
  $.ajax Routes.reset_section_path(),
    type: 'GET'
    dataType: 'script'
    data: {
      id: sectionId
    }
#  $('#section-basics-warning-' + sectionId).hide()
  return
$('#new-tag-button-<%= @section.id%>').on 'click', ->
  $.ajax Routes.tag_modal_path(),
    type: 'GET'
    dataType: 'script'
    data: {
      related_tag: this.dataset.tag
      course: this.dataset.course
      section: this.dataset.section
      from: this.dataset.from
    }
  return
$('[id^="section-tag-links-"]').on 'click', ->
  sectionId = this.dataset.id
  if $('#section-tag-list-' + sectionId).data('show') == 0
    $('#section-tag-list-' + sectionId).data('show', 1).show()
    $(this).text('Tag-Links ausblenden')
  else
    $('#section-tag-list-' + sectionId).data('show', 0).hide()
    $(this).text('Tag-Links einblenden')
  return
