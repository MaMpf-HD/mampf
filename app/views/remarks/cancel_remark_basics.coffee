$('#remark-basics-edit').empty()
  .append '<%= j render partial: "remarks/basics",
                        locals: { remark: @remark } %>'
remarkBasics = document.getElementById('remark-basics-edit')
renderMathInElement remarkBasics,
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
