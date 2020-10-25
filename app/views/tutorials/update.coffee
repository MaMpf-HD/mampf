<% if @errors.present? %>
# clean up from previous error messages
$('#tutorial_title').removeClass('is-invalid')
$('#tutorial-title-error').empty()

# display error message
<% if @errors[:title].present? %>
$('#tutorial-title-error')
  .append('<%= @errors[:title].join(" ") %>').show()
$('#tutorial_title').addClass('is-invalid')
<% end %>

<% else %>
$('.tutorialRow[data-id="<%= @tutorial.id %>')
  .replaceWith('<%= j render partial: "tutorials/row",
                      locals: { tutorial: @tutorial,
                      					inspection: false } %>')
<% end %>