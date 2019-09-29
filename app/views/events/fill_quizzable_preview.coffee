$('#mediumPreview').empty()
  .append '<%= j render partial: "quizzes/edit/vertex_status",
                        locals: { quizzable: @quizzable } %>'
  .append '<%= j render partial: "quizzes/quizzable_preview",
                        locals: { quizzable: @quizzable } %>'
mediumPreview = document.getElementById('mediumPreview')
renderMathInElement mediumPreview,
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