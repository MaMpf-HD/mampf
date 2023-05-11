# https://stackoverflow.com/a/36227664/9655481
getScrollTop = ->
  return Math.max(document.body.scrollTop, document.documentElement.scrollTop)
oldScrollPos = getScrollTop()

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

window.scrollTo(0, oldScrollPos)
