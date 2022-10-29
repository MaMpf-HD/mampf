# replace term row by editable term row
$('#row-term-<%= params[:id]%>').empty()
  .removeClass('row')
  .append('<%= j render partial: "terms/form",
                        locals: { term: @term,
                                  new_action: false } %>')
