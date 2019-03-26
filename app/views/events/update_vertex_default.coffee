$("#vertex_default_target_<%= @vertex_id %>").empty()
<% unless @quizzable.nil? %>
  .append '<%= j render partial: "vertices/quizzable",
                        locals: { quizzable: @quizzable } %>'
defaultTarget = document.getElementById('default_target')
renderMathInElement defaultTarget,
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
