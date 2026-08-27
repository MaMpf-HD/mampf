function disableExceptOrganizational() {
  $("#lecture-organizational-warning").show();
  $(".fa-edit").hide();
  $(".new-in-lecture").hide();
  $('[data-bs-toggle="collapse"]').prop("disabled", true).removeClass("clickable");
};

// Bound to the document rather than to the fields: this file is a module in the
// page body, so on the visit that first loads it Turbo has announced turbo:load
// long before it is evaluated, and anything bound in there would never see the
// form. See the cancel buttons below for the other half of the same feature.
$(document).on("change", "#lecture-form :input", function () {
  $("#lecture-basics-warning").show();
  $(".fa-edit:not(#update-teacher-button,#update-editors-button)").hide();
  $(".new-in-lecture").hide();
  $('[data-bs-toggle="collapse"]').prop("disabled", true).removeClass("clickable");
});

$(document).on("change", "#lecture-preferences-form :input", function () {
  $("#lecture-preferences-warning").show();
  $('[data-bs-toggle="collapse"]').prop("disabled", true).removeClass("clickable");
  $(".fa-edit").hide();
  $(".new-in-lecture").hide();
});

$(document).on("change", "#lecture-comments-form :input", function () {
  $("#lecture-comments-warning").show();
  $('[data-bs-toggle="collapse"]').prop("disabled", true).removeClass("clickable");
  $(".fa-edit").hide();
  $(".new-in-lecture").hide();
});

$(document).on("change", "#lecture-assignments-form :input", function () {
  $("#lecture-assignments-warning").show();
  $('[data-bs-toggle="collapse"]').prop("disabled", true).removeClass("clickable");
  $(".new-in-lecture").hide();
});

$(document).on("change", "#lecture-organizational-form :input", function () {
  disableExceptOrganizational();
});

$(document).on("trix-change", "#lecture-concept-trix", function () {
  disableExceptOrganizational();
});

const RELOADING_CANCEL_BUTTONS = [
  "#lecture-basics-cancel",
  "#cancel-lecture-preferences",
  "#cancel-lecture-comments",
  "#cancel-lecture-organizational",
].join(", ");

$(document).on("click", RELOADING_CANCEL_BUTTONS, function () {
  location.reload(true);
});

$(document).on("click", "#cancel-lecture-assignments", function () {
  $("#lecture-assignments-warning").hide();
  $('[data-bs-toggle="collapse"]').prop("disabled", false).addClass("clickable");
  $(".new-in-lecture").show();
  const maxSize = $("#lecture_submission_max_team_size").data("value");
  $("#lecture_submission_max_team_size").val(maxSize);
  const gracePeriod = $("#lecture_submission_grace_period").data("value");
  $("#lecture_submission_grace_period").val(gracePeriod);
});

$(document).on("click", "#delete-forum", function () {
  return confirm($(this).data("sureToDelete"));
});

// The absolute numbering box decides whether a start section may be picked.
$(document).on("change", "#lecture_absolute_numbering", function () {
  $("#lecture_start_section").prop("disabled", !$(this).prop("checked"));
});

$(document).on("click", "#hide-media-button", function () {
  $("#lecture-media-card").hide();
  $("#lecture-content-card").removeClass("col-xxl-9");
  $("#show-media-button").show();
});

$(document).on("click", "#show-media-button", function () {
  $("#lecture-content-card").addClass("col-xxl-9");
  $("#lecture-media-card").show();
  $("#show-media-button").hide();
});

// Tags can only be imported along with the sections they hang off.
$(document).on("change", "#import_sections", function () {
  if ($(this).prop("checked")) {
    $("#import_tags").prop("disabled", false);
    return;
  }
  $("#import_tags").prop("disabled", true).prop("checked", false);
});

$(document).on("change", "#lecture_course_id", function () {
  $("#lecture_term_id").removeClass("is-invalid");
  $("#new-lecture-term-error").empty();
  const courseId = parseInt($(this).val());
  const termInfo = $(this).data("terminfo").filter(x => x[0] === courseId);
  if (!termInfo[0]) return;

  const termIndependent = termInfo[0][1];
  $("#newLectureTerm").toggle(!termIndependent);
  $("#lecture_term_id").prop("disabled", termIndependent);
  $("#newLectureSort").toggle(!termIndependent);
});

$(document).on("change", "#medium_publish_media_0", function () {
  $('[id^="medium_released_"]').attr("disabled", true);
  $("#access-text").css("color", "grey");
});

$(document).on("change", "#medium_publish_media_1", function () {
  $('[id^="medium_released_"]').attr("disabled", false);
  $("#access-text").css("color", "");
});

$(document).on("turbo:load", function () {
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
          const row = document.createElement("div");
          row.className = "row mx-2 border-left border-right border-bottom";
          const colName = document.createElement("div");
          colName.className = "col-6";
          colName.innerHTML = res[0];
          row.appendChild(colName);
          const colMail = document.createElement("div");
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
});

$(document).on("turbo:before-cache", function () {
  $(".lecture-tag").removeClass("bg-warning");
  $(".lecture-lesson").removeClass("bg-info").addClass("bg-secondary");
});
