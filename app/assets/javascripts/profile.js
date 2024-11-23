$(document).ready(function () {
  $("#profileForm").on("change input", function () {
    $("#profileChange").removeClass("d-none");
  });

  $('input:checkbox[name^="user[lecture"]').on("change", function () {
    const courseId = this.dataset.course;
    const lectureId = this.dataset.lecture;
    const checkedCount = $('input:checked[data-course="' + courseId + '"]').length;
    const authRequiredLectureIds = $("#lectures-for-course-" + courseId).data("authorize");

    if ($(this).prop("checked") && authRequiredLectureIds.includes(parseInt(lectureId))) {
      $("#pass-lecture-" + lectureId).show();
    }
    else {
      $("#pass-lecture-" + lectureId).hide();
      if (checkedCount === 0) {
        $('.courseSubInfo[data-course="' + courseId + '"]').removeClass("fas fa-check-circle")
          .addClass("far fa-circle");
      }
      else {
        $('.courseSubInfo[data-course="' + courseId + '"]').removeClass("far fa-circle")
          .addClass("fas fa-check-circle");
      }
    }
  });

  $(".programCollapse").on("show.bs.collapse", function () {
    const program = $(this).data("program");
    $("#program-" + program + "-collapse").find(".coursePlaceholder").each(function () {
      const course = $(this).data("course");
      $(this).append($("#course-card-" + course));
      $("#course-card-" + course).show();
    });
  });

  $("#request-data-btn").on("click", function () {
    console.log("pressed");
    const toast = $("#request-data-toast");
    bootstrap.Toast.getOrCreateInstance(toast).show();
  });
});
