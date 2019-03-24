$('#remark-basics-edit').empty()
  .append '<%= j render partial: "remarks/basics",
                        locals: { remark: @remark } %>'
remarksBasics = document.getElementById('remarks-basics-edit')
renderMathInElement remarksBasics,
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