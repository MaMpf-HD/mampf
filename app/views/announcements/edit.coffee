$('#row-announcement-<%= @id %>').empty()
  .removeClass('row')
  .append('<%= j render partial: "announcements/form",
                        locals: { announcement: @announcement,
                                  new_action: false } %>')