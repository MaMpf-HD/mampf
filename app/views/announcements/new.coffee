$('#new-announcement-modal-content').empty()
  .append('<%= j render partial: "announcements/form",
                        locals: { announcement: @announcement,
                                  lecture: @lecture } %>')
$('[data-toggle="popover"]').popover()
$('#newAnnouncementModal').modal('show')