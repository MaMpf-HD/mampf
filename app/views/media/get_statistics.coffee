# render new lesson form
$('#statistics-modal-content').empty()
  .append('<%= j render partial: "media/statistics",
                        locals: { medium: @medium,
                                  video_downloads: @video_downloads,
                                  video_thyme: @video_thyme,
                                  manuscript_access: @manuscript_access,
                                  quiz_access: @quiz_access,
                                  success: @success,
                                  question_count: @question_count } %>').show()

# activate popovers
$('[data-toggle="popover"]').popover()

$('#statisticsModal').modal('show')