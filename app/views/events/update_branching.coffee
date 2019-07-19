$("<%= '#'+@id%>").empty()
<% unless @quizzable.nil? %>
  .append '<%= j render partial: "vertices/quizzable",
                        locals: { quizzable: @quizzable } %>'
texRefresh = document.getElementById('<%= @id %>')
renderMathInElement texRefresh,
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
<% end %>
