# render announcement form to announcement modal
$('#new-announcement-modal-content').empty()
  .append('<%= j render partial: "announcements/form",
                        locals: { announcement: @announcement,
                                  lecture: @lecture } %>')

# activate popovers and show modal
$('[data-toggle="popover"]').popover()
$('#newAnnouncementModal').modal('show')