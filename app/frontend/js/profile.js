$(document).ready(function () {
  $("#profileForm").on("change input", function () {
    $("#profileChange").removeClass("d-none");
    $("#profileChangeBottom").removeClass("d-none");
  });

  $('input:checkbox[id^="user_lecture"]').on("change", function () {
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

  $(".programCollapse").on("show.bs.collapse", function () {
    const program = $(this).data("program");
    $(`#program-${program}-collapse`).find(".coursePlaceholder").each(function () {
      const course = $(this).data("course");
      $(this).append($(`#course-card-${course}`));
      $(`#course-card-${course}`).show();
    });
  });

  $("#request-data-btn").on("click", function () {
    const toast = $("#request-data-toast");
    bootstrap.Toast.getOrCreateInstance(toast).show();
  });
});
