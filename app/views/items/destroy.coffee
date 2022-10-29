# rerender the toc box and the references box
$('#toc-area').empty()
  .append('<%= j render partial: 'media/toc',
                        locals: { medium: @medium } %>')
$('#meta-area').empty()
  .append('<%= j render partial: "media/reference",
                        locals: { medium: @medium } %>')

# hide export toc buttons if there are  no toc items
<% if @medium.items.blank? %>
$('#export-toc').hide()
<% end %>

# clean up action box
$('#action-placeholder').empty()
$('#action-container').empty()

# rerender math in toc box
tocArea = document.getElementById('toc-area')
renderMathInElement tocArea,
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


# rerender math in references box
metaArea = document.getElementById('meta-area')
renderMathInElement metaArea,
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
