$('#row-term-<%= @id %>').addClass('row').empty()
  .append('<%= j render partial: "terms/row",
                        locals: { term: @term } %>')
