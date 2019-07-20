$('#quizzablePreview').empty()
  .append '<%= j render partial: "quizzes/edit/vertex_status",
                        locals: { quizzable: @quizzable } %>'
  .append '<%= j render partial: "quizzes/quizzable_preview",
                        locals: { quizzable: @quizzable } %>'
quizzablePreview = document.getElementById('quizzablePreview')
renderMathInElement quizzablePreview,
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