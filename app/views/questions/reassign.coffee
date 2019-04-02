$('#reassignModal').modal 'hide'
$('#quizzableModalLabel').empty()
  .append('Frage <%= @question.description %> bearbeiten')
$('#quizzable-data').empty()
  .append '<%= j render partial: "questions/data",
                        locals: { question: @question } %>'
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
