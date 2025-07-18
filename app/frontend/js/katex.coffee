$(document).on 'turbolinks:load', ->
  renderMathInElement document.body,
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
    ignoredClasses: ['trix-content', 'form-control']
    throwOnError: false

  return