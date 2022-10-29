<% if @errors.present? %>
# display error messages
$('#term-error').empty().append('<%= @errors %>').show()
$('#term_year').addClass('is-invalid')
$('#term_season').addClass('is-invalid')
<% else %>
# replace editable term row by non-editable row
$('#row-term-<%= @id %>').addClass('row').empty()
  .append('<%= j render partial: "terms/row",
                        locals: { term: @term } %>')
<% end %>
