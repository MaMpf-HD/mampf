$('#reassignModal').modal 'hide'
$('#quizzable-data').empty()
  .append '<%= j render partial: "remarks/data",
                        locals: { remark: @remark } %>'
quizzableData = document.getElementById('quizzable_data')
renderMathInElement quizzableData,
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