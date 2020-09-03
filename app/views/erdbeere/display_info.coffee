$('.erdbeere-realization[data-sort="<%= @sort %>"][data-id="<%= @id %>"]').empty()
 .append('<%= @info %>')