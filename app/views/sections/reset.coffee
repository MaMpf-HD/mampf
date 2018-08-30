$('#section-body-<%= @section.id %>').empty()
  .append('<%= j render partial: "sections/body",
                        locals: { section: @section } %>')
$('#section-body-<%= @section.id %> .selectize').selectize({ plugins: ['remove_button'] })
$('[id^="section-form-"] :input').on 'change', ->
  sectionId = this.dataset.id
  $('#section-basics-warning-' + sectionId).show().data('shown', '1')
  return
$('[id^="section-basics-cancel-"]').on 'click', ->
  sectionId = this.dataset.id
  $.ajax Routes.reset_section_path(),
    type: 'GET'
    dataType: 'script'
    data: {
      id: sectionId
    }
  $('#section-basics-warning-' + sectionId).hide()
  return
$('#new-tag-button-<%= @section.id%>').on 'click', ->
  $.ajax Routes.tag_modal_path(),
    type: 'GET'
    dataType: 'script'
    data: {
      course: this.dataset.course
    }
  return
