<% if !@too_late %>
$('.submissionArea[data-id="<%= @assignment.id %>"]').empty()
  .append('<%= j render partial: "submissions/card",
                        locals: { assignment: @assignment,
                                  submission: nil } %>')
initBootstrapPopovers()

<% if @progress_value.present? %>
progressBar = $('[data-testid="progress-bar"]')
progressBarInner = progressBar.find('.progress-bar')
progressBarInner.css('width', '<%= @progress_value %>%')
  .attr('aria-valuenow', '<%= @progress_value %>')
  .text('<%= @progress_value %>%')

progressText = progressBar.find('span')
<% if @progress_value == 0 %>
progressText.show()
<% else %>
progressText.hide()
<% end %>
<% end %>

<% else %>
alert('<%= t("submission.too_late_no_destroying") %>')
<% end %>