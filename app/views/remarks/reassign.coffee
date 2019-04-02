$('#reassignModal').modal 'hide'
$('#quizzableModalLabel').empty()
  .append('Bemerkung <%= @remark.description %> bearbeiten')
$('#quizzable-data').empty()
  .append '<%= j render partial: "remarks/data",
                        locals: { remark: @remark } %>'
quizzableData = document.getElementById('quizzable-data')
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