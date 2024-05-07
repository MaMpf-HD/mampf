function disableExceptOrganizational() {
  $("#lecture-organizational-warning").show();
  $(".fa-edit").hide();
  $(".new-in-lecture").hide();
  $('[data-bs-toggle="collapse"]').prop("disabled", true).removeClass("clickable");
};

// Load example data (erdbeere) for structures
function loadExampleStructures() {
  const structuresBody = $("#erdbeereStructuresBody");
  const lectureId = structuresBody.data("lecture");
  const loading = structuresBody.data("loading");
  structuresBody.empty().append(loading);
  $.ajax(Routes.edit_structures_path(lectureId), {
    type: "GET",
    dataType: "script",
  });
};

$(document).on("turbolinks:load", function () {
  let s, structures;
  initBootstrapPopovers();
  // if any input is given to the lecture form (for people in lecture),
  // disable other input
  $("#lecture-form :input").on("change", function () {
    $("#lecture-basics-warning").show();
    $(".fa-edit:not(#update-teacher-button,#update-editors-button)").hide();
    $(".new-in-lecture").hide();
    $('[data-bs-toggle="collapse"]').prop("disabled", true).removeClass("clickable");
  });

  // if any input is given to the preferences form, disable other input
  $("#lecture-preferences-form :input").on("change", function () {
    $("#lecture-preferences-warning").show();
    $('[data-bs-toggle="collapse"]').prop("disabled", true).removeClass("clickable");
    $(".fa-edit").hide();
    $(".new-in-lecture").hide();
  });

  // if any input is given to the comments form, disable other input
  $("#lecture-comments-form :input").on("change", function () {
    $("#lecture-comments-warning").show();
    $('[data-bs-toggle="collapse"]').prop("disabled", true).removeClass("clickable");
    $(".fa-edit").hide();
    $(".new-in-lecture").hide();
  });

  // if any input is given to the assignments form, disable other input
  $("#lecture-assignments-form :input").on("change", function () {
    $("#lecture-assignments-warning").show();
    $('[data-bs-toggle="collapse"]').prop("disabled", true).removeClass("clickable");
    $(".new-in-lecture").hide();
  });

  // if any input is given to the organizational form, disable other input
  $("#lecture-organizational-form :input").on("change", function () {
    disableExceptOrganizational();
  });

  const trixElement = document.querySelector("#lecture-concept-trix");
  if (trixElement) {
    const {
      content,
    } = trixElement.dataset;
    const {
      editor,
    } = trixElement;
    editor.setSelectedRange([0, 65535]);
    editor.deleteInDirection("forward");
    editor.insertHTML(content);
    document.activeElement.blur();
    trixElement.addEventListener("trix-change", function () {
      disableExceptOrganizational();
    });
  }

  // if absolute numbering box is checked/unchecked, enable/disable selection of
  // start section
  $("#lecture_absolute_numbering").on("change", function () {
    if ($(this).prop("checked")) {
      $("#lecture_start_section").prop("disabled", false);
    }
    else {
      $("#lecture_start_section").prop("disabled", true);
    }
  });

  // reload current page if lecture basics editing is cancelled
  $("#lecture-basics-cancel").on("click", function () {
    location.reload(true);
  });

  // reload current page if lecture preferences editing is cancelled
  $("#cancel-lecture-preferences").on("click", function () {
    location.reload(true);
  });

  // reload current page if lecture comments editing is cancelled
  $("#cancel-lecture-comments").on("click", function () {
    location.reload(true);
  });

  // reload current page if lecture preferences editing is cancelled
  $("#cancel-lecture-organizational").on("click", function () {
    location.reload(true);
  });

  // restore assignments form if lecture assignments editing is cancelled
  $("#cancel-lecture-assignments").on("click", function () {
    $("#lecture-assignments-warning").hide();
    $('[data-bs-toggle="collapse"]').prop("disabled", false).addClass("clickable");
    $(".new-in-lecture").show();
    const maxSize = $("#lecture_submission_max_team_size").data("value");
    $("#lecture_submission_max_team_size").val(maxSize);
    const gracePeriod = $("#lecture_submission_grace_period").data("value");
    $("#lecture_submission_grace_period").val(gracePeriod);
  });

  // hide the media tab if hide media button is clicked
  $("#hide-media-button").on("click", function () {
    $("#lecture-media-card").hide();
    $("#lecture-content-card").removeClass("col-xxl-9");
    $("#show-media-button").show();
  });

  // display the media tab if show media button is clicked
  $("#show-media-button").on("click", function () {
    $("#lecture-content-card").addClass("col-xxl-9");
    $("#lecture-media-card").show();
    $("#show-media-button").hide();
  });

  // mousenter over a medium -> colorize lessons and tags
  $('[id^="lecture-medium_"]').on("mouseenter", function () {
    if (this.dataset.type === "Lesson") {
      const lessonId = this.dataset.id;
      $('.lecture-lesson[data-id="' + lessonId + '"]')
        .removeClass("bg-secondary")
        .addClass("bg-info");
    }
    const tags = $(this).data("tags");
    for (const t of tags) {
      $('.lecture-tag[data-id="' + t + '"]').removeClass("bg-light")
        .addClass("bg-warning");
    }
  });

  // mouseleave over lesson -> restore original color of lessons and tags
  $('[id^="lecture-medium_"]').on("mouseleave", function () {
    if (this.dataset.type === "Lesson") {
      const lessonId = this.dataset.id;
      $('.lecture-lesson[data-id="' + lessonId + '"]').removeClass("bg-info")
        .addClass("bg-secondary");
    }
    const tags = $(this).data("tags");
    for (const t of tags) {
      $('.lecture-tag[data-id="' + t + '"]').removeClass("bg-warning");
    }
  });

  // mouseenter over lesson -> colorize tags
  $('[id^="lecture-lesson_"]').on("mouseenter", function () {
    const tags = $(this).data("tags");
    for (const t of tags) {
      $('.lecture-tag[data-id="' + t + '"]').addClass("bg-warning");
    }
  });

  // mouseleave over lesson -> restore original color of tags
  $('[id^="lecture-lesson_"]').on("mouseleave", function () {
    const tags = $(this).data("tags");
    for (const t of tags) {
      $('.lecture-tag[data-id="' + t + '"]').removeClass("bg-warning");
    }
  });

  // mouseenter over tag -> colorize lessons
  $('[id^="lecture-tag_"]').on("mouseenter", function () {
    const lessons = $(this).data("lessons");
    for (const l of lessons) {
      $('.lecture-lesson[data-id="' + l + '"]').removeClass("bg-secondary")
        .addClass("bg-info");
    }
  });

  // mouseleave over tag -> restore original color of lessons
  $('[id^="lecture-tag_"]').on("mouseleave", function () {
    const lessons = $(this).data("lessons");
    for (const l of lessons) {
      $('.lecture-lesson[data-id="' + l + '"]').removeClass("bg-info")
        .addClass("bg-secondary");
    }
  });

  $('#edited-media-tab a[data-bs-toggle="tab"]').on("shown.bs.tab", function (e) {
    const {
      sort,
    } = e.target.dataset; // newly activated tab
    const path = $("#create-new-medium").prop("href");
    if (path) {
      const new_path = path.replace(/\?sort=.+?&/, "?sort=" + sort + "&");
      $("#create-new-medium").prop("href", new_path);
    }
  });

  const userModalContent = document.getElementById("lectureUserModalContent");
  if (userModalContent && (userModalContent.dataset.filled === "false")) {
    const lectureId = userModalContent.dataset.lecture;
    $.ajax(Routes.show_subscribers_path(lectureId), {
      type: "GET",
      dataType: "json",
      data: {
        lecture: lectureId,
      },
      success(result) {
        if (result.length === 0) {
          $("#lectureUserModalButton").hide();
        }
        for (const res of result) {
          var row = document.createElement("div");
          row.className = "row mx-2 border-left border-right border-bottom";
          var colName = document.createElement("div");
          colName.className = "col-6";
          colName.innerHTML = res[0];
          row.appendChild(colName);
          var colMail = document.createElement("div");
          colMail.className = "col-6";
          colMail.innerHTML = res[1];
          row.appendChild(colMail);
          userModalContent.appendChild(row);
          userModalContent.dataset.filled = "true";
        }
      },
    },
    );
  }

  // on small mobile display, use shortened tag badges and
  // shortened course titles
  const mobileDisplay = function () {
    $(".tagbadge").hide();
    $(".courseMenuItem").hide();
    $(".tagbadgeshort").show();
    $(".courseMenuItemShort").show();
    $("#secondnav").show();
    $("#lecturesDropdown").appendTo($("#secondnav"));
    $("#notificationDropdown").appendTo($("#secondnav"));
    $("#feedback-btn").appendTo($("#secondnav"));
    $("#searchField").appendTo($("#secondnav"));
    $("#second-admin-nav").show();
    $("#adminDetails").appendTo($("#second-admin-nav"));
    $("#adminUsers").appendTo($("#second-admin-nav"));
    $("#adminProfile").appendTo($("#second-admin-nav"));
    $("#teachableDrop").prependTo($("#second-admin-nav"));
    $("#adminMain").css("flex-direction", "row");
    $("#adminHome").css("padding-right", "0.5rem");
    $("#adminCurrentLecture").css("padding-right", "0.5rem");
    $("#adminSearch").css("padding-right", "0.5rem");
    $("#mampfbrand").hide();
  };

  // on large display, use normal tag badges and course titles
  const largeDisplay = function () {
    $(".tagbadge").show();
    $(".courseMenuItem").show();
    $(".tagbadgeshort").hide();
    $(".courseMenuItemShort").hide();
    $("#secondnav").hide();
    $("#lecturesDropdown").appendTo($("#firstnav"));
    $("#notificationDropdown").appendTo($("#firstnav"));
    $("#feedback-btn").appendTo($("#firstnav"));
    $("#searchField").appendTo($("#firstnav"));
    $("#second-admin-nav").hide();
    $("#teachableDrop").appendTo($("#first-admin-nav"));
    $("#adminDetails").appendTo($("#first-admin-nav"));
    $("#adminUsers").appendTo($("#first-admin-nav"));
    $("#adminProfile").appendTo($("#first-admin-nav"));
    $("#adminMain").removeAttr("style");
    $("#adminHome").removeAttr("style");
    $("#adminCurrentLecture").removeAttr("style");
    $("#adminSearch").removeAttr("style");
    $("#mampfbrand").show();
  };

  // highlight tagbadges if screen is very small
  if (window.matchMedia("screen and (max-width: 767px)").matches) {
    mobileDisplay();
  }

  if (window.matchMedia("screen and (max-device-width: 767px)").matches) {
    mobileDisplay();
  }

  // mediaQuery listener for very small screens
  const match_verysmall = window.matchMedia("screen and (max-width: 767px)");
  match_verysmall.addListener(function (result) {
    if (result.matches) {
      mobileDisplay();
    }
  });

  const match_verysmalldevice = window.matchMedia("screen and (max-device-width: 767px)");
  match_verysmalldevice.addListener(function (result) {
    if (result.matches) {
      mobileDisplay();
    }
  });

  // mediaQuery listener for normal screens
  let match_normal = window.matchMedia("screen and (min-width: 768px)");
  match_normal.addListener(function (result) {
    if (result.matches) {
      largeDisplay();
    }
  });

  match_normal = window.matchMedia("screen and (min-device-width: 768px)");
  match_normal.addListener(function (result) {
    if (result.matches) {
      largeDisplay();
    }
  });

  loadExampleStructures();

  const $lectureStructures = $("#lectureStructuresInfo");
  if ($lectureStructures.length > 0) {
    structures = $lectureStructures.data("structures");
    for (const s of structures) {
      $("#structure-item-" + s).show();
    }
  }

  $("#switchGlobalStructureSearch").on("click", function () {
    if ($(this).is(":checked")) {
      $('[id^="structure-item-"]').show();
    }
    else {
      $('[id^="structure-item-"]').hide();
      structures = $lectureStructures.data("structures");
      for (const s of structures) {
        $("#structure-item-" + s).show();
      }
    }
  });

  $(document).on("change", "#lecture_course_id", function () {
    $("#lecture_term_id").removeClass("is-invalid");
    $("#new-lecture-term-error").empty();
    const courseId = parseInt($(this).val());
    const termInfo = $(this).data("terminfo").filter(x => x[0] === courseId);
    console.log(termInfo[0]);
    if (termInfo[0]) {
      if (termInfo[0][1]) {
        $("#newLectureTerm").hide();
        $("#lecture_term_id").prop("disabled", true);
        $("#newLectureSort").hide();
      }
      else {
        $("#newLectureTerm").show();
        $("#lecture_term_id").prop("disabled", false);
        $("#newLectureSort").show();
      }
      return;
    }
  });

  $(document).on("change", "#medium_publish_media_0", function () {
    $('[id^="medium_released_"]').attr("disabled", true);
    $("#access-text").css("color", "grey");
  });

  $(document).on("change", "#medium_publish_media_1", function () {
    $('[id^="medium_released_"]').attr("disabled", false);
    $("#access-text").css("color", "");
  });

  $("#import_sections").on("change", function () {
    if ($(this).prop("checked")) {
      $("#import_tags").prop("disabled", false);
    }
    else {
      $("#import_tags").prop("disabled", true).prop("checked", false);
    }
  });
});

// clean up everything before turbolinks caches
$(document).on("turbolinks:before-cache", function () {
  $(".lecture-tag").removeClass("bg-warning");
  $(".lecture-lesson").removeClass("bg-info").addClass("bg-secondary");
  $(document).off("change", "#lecture_course_id");
});
