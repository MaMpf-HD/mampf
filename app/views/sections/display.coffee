$('#section-content-modal-content').empty()
  .append('<%= j render partial: "items/items",
                        locals: { items: @section.visible_items,
                                  small: false,
                                  embedded: false } %>')
$('#section-title-modal').empty().append('"<%= @section.title %>"')

sectionModal = document.getElementById('sectionContentModal')
renderMathInElement sectionModal,
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

$('#sectionContentModal').modal('show')