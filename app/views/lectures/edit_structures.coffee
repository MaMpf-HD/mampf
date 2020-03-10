$('#erdbeereStructuresBody').empty()
.append('<%= j render partial: "lectures/edit/structures",
                      locals: { lecture: @lecture,
                      					all_structures: @all_structures,
                      					structures: @structures,
                                properties: @properties } %>')
structuresBody = document.getElementById('erdbeereStructuresBody')
renderMathInElement structuresBody,
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

$('[data-toggle="popover"]').popover()