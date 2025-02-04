$('#sidebar').empty()
.append('<%= j render partial: "shared/sidebar",
                        locals: { lecture: @lecture,
                                  course: @course } %>')