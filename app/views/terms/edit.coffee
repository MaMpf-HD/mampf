$('#row-term-<%= params[:id]%>').empty()
  .removeClass('row')
  .append('<%= j render partial: "terms/form", locals: { term: @term} %>')
