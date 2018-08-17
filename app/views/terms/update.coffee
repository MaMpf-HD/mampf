<% if @errors.present? %>
$('#term-error').empty().append('<%= @errors %>').show()
$('#term_year').addClass('is-invalid')
$('#term_season').addClass('is-invalid')
<% else %>
$('#row-term-<%= @id %>').addClass('row').empty()
  .append('<%= j render partial: "terms/row",
                        locals: { term: @term } %>')
<% end %>
