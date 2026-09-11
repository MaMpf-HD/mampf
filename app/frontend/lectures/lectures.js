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
