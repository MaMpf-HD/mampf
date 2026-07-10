$(document).on("change input", "#profileForm", function () {
  $("#profileChange").removeClass("d-none");
  $("#profileChangeBottom").removeClass("d-none");
});

$(document).on("change", 'input:checkbox[id^="user_lecture"]', function () {
  const courseId = this.dataset.course;
  const lectureId = parseInt(this.dataset.lecture);
  const checkedCount = $(`input:checked[data-course="${courseId}"]`).length;
  const authRequiredLectureIds = $(`#lectures-for-course-${courseId}`).data("authorize");

  $(`.courseSubInfo[data-course="${courseId}"]`)
    .toggleClass("fas fa-check-circle", checkedCount > 0)
    .toggleClass("far fa-circle", checkedCount === 0);

  const showPasswordField = $(this).prop("checked") && authRequiredLectureIds.includes(lectureId);
  $(`#pass-lecture-${lectureId}`).toggle(showPasswordField);
});

$(document).on("show.bs.collapse", ".programCollapse", function () {
  const program = $(this).data("program");
  $(`#program-${program}-collapse`).find(".coursePlaceholder").each(function () {
    const course = $(this).data("course");
    $(this).append($(`#course-card-${course}`));
    $(`#course-card-${course}`).show();
  });
});

$(document).on("click", "#request-data-btn", function () {
  const toast = $("#request-data-toast");
  bootstrap.Toast.getOrCreateInstance(toast).show();
});
